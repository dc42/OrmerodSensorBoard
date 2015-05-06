/*
 * MiniLedSensor.cpp
 *
 * Created: 03/05/2015 11:06:12
 *  Author: David
 */ 

#include "ecv.h"

#ifdef __ECV__
#define __attribute__(_x)
#define __volatile__
#define __DOXYGEN__				// this avoids getting the wrong definitions for uint32_t etc.
#endif

#ifdef __ECV__
#pragma ECV noverifyincludefiles
#endif

#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/eeprom.h>
#include <avr/wdt.h>

#ifdef __ECV__
#pragma ECV verifyincludefiles
#endif

#define ISR_DEBUG	(0)		// set nonzero to use PB2 as debug output pin

#define BITVAL(_x) static_cast<uint8_t>(1u << (_x))

// Pin assignments:
// PB0/MOSI			far LED drive, active high
// PB1/MISO			near LED drive, active high
// PB2/ADC1/SCK		output to Duet via 12K resistor
// PB3/ADC3			output to Duet via 10K resistor
// PB4/ADC2			input from phototransistor
// PB5/ADC0/RESET	not available, used for programming

__fuse_t __fuse __attribute__((section (".fuse"))) = {0xE2u, 0xDFu, 0xFFu};

const unsigned int AdcPhototransistorChan = 2;
const unsigned int PortBNearLedBit = 1;
const unsigned int PortBFarLedBit = 0;
const unsigned int PortBDuet10KOutputBit = 3;
const unsigned int PortBDuet12KOutputBit = 2;

const uint8_t PortBUnusedBitMask = BITVAL(4);

// Approximate MPU frequency (8MHz internal oscillator)
const uint32_t F_CPU = 8000000uL;

// IR parameters. These also allow us to receive a signal through the command input.
const uint16_t interruptFreq = 8000;						// interrupt frequency. We run the IR sensor at one quarter of this, i.e. 2kHz
															// highest usable value is about 9.25kHz because the ADC needs 13.5 clock cycles per conversion.
const uint16_t divisorIR = (uint16_t)(F_CPU/interruptFreq);
const uint16_t prescalerIR = 8;								// needs to be high enough to get baseTopIR below 256
const uint16_t baseTopIR = (divisorIR/prescalerIR) - 1;
const uint16_t cyclesAveragedIR = 8;						// must be a power of 2, max 32 (unless we make onSumIR and offSumIR uint32_t)

const uint16_t farThreshold = 10 * cyclesAveragedIR;		// minimum far reading for us to think the sensor is working properly
const uint16_t simpleNearThreshold = 30 * cyclesAveragedIR;	// minimum reading to set output high in simple mode
const uint16_t saturatedThreshold = 870 * cyclesAveragedIR;	// minimum reading for which we consider the sensor saturated

const uint16_t kickFreq = 16;
const uint16_t kickIntervalTicks = interruptFreq/kickFreq;

// IR variables
typedef uint8_t invariant(value < cyclesAveragedIR) irIndex_t;

struct IrData
{
	uint16_t readings[cyclesAveragedIR];
	volatile uint16_t sum;
	irIndex_t index;

	void addReading(uint16_t arg)
	writes(*this; volatile)
	pre(invar())
	pre(arg <= 1023)
	post(invar())
	{
		sum = sum - readings[index] + arg;
		readings[index] = arg;
		index = static_cast<irIndex_t>((index + 1) % cyclesAveragedIR);
	}
	
	void init()
	writes(*this; volatile)
	post(invar());

	ghost(
		bool invar() const
			returns((forall r in readings :- r <= 1023) && sum == + over readings);
	)
	
#ifdef __ECV__
	// Dummy constructor to keep eCv happy
	IrData() : index(0) {}
#endif
};

IrData nearData, farData, offData;
	
// General variables
volatile uint16_t tickCounter;						// counts system ticks, lower 2 bits also used for ADC/LED state
uint16_t lastKickTicks;								// when we last kicked the watchdog
bool running;


// ISR for the timer 0 compare match A interrupt
// This works on a cycle of 4 readings as follows:
// far led on, near led on, leds off, null
ISR(TIM0_COMPB_vect)
writes(nearData; farData; offData)
writes(volatile)
pre(nearData.invar(); farData.invar(); offData.invar())
post(nearData.invar(); farData.invar(); offData.invar())
{
	uint16_t adcVal = ADC & 1023u;					// get the ADC reading from the previous conversion
	uint8_t locTickCounter = (uint8_t)tickCounter;
	while (TCNT0 < 3 * 8) {}						// delay a little until the ADC s/h has taken effect. 3 ADC clocks should be enough, and 1 ADC clock is 8 timer 0 clocks.
	switch(locTickCounter & 0x03u)
	{
		case 0:
			// Far LED is on, we just did no reading, we are doing a far reading now and a near reading next
			PORTB &= ~BITVAL(PortBFarLedBit);		// turn far LED off
			PORTB |= BITVAL(PortBNearLedBit);		// turn near LED on
			break;
		
		case 1:
			// Near LED is on, we just did a far reading, we are doing a near reading now and an off reading next			
			if (running)
			{
				farData.addReading(adcVal);
			}
			PORTB &= ~BITVAL(PortBNearLedBit);		// turn near LED off
			break;
					
		case 2:
			// LEDs are off, we just did a near reading, we are doing an off reading now and a dummy off reading next
			if (running)
			{
				nearData.addReading(adcVal);
			}
			break;

		case 3:
			// Far LED is on, we just did an off reading, we are doing another off reading now which will be discarded
			if (running)
			{
				offData.addReading(adcVal);
			}
			PORTB |= BITVAL(PortBFarLedBit);		// turn far LED on
			break;
	}
	++tickCounter;
}

#if 0	// unused at present

// Delay for a little while
// Each iteration of the loop takes 4 clocks plus one clock per NOP instruction in the body.
// The additional overhead for the function, including calling it, is 12 clocks.
// Therefore, with F_CPU = 8MHz and using 4 NOP instructions, it delays n + 1.5 microseconds.
void shortDelay(uint8_t n)
{
	for (uint8_t i = 0; i < n; ++i)
	keep(i <= n)
	decrease(n - i)
	{
#ifndef __ECV__			// eCv doesn't understand asm
		asm volatile ("nop");
		asm volatile ("nop");
		asm volatile ("nop");
		asm volatile ("nop");
#endif
	}
}

#endif

// Give a G31 reading of about 0
inline void SetOutputOff()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
	PORTB &= ~BITVAL(PortBDuet10KOutputBit);
	PORTB &= ~BITVAL(PortBDuet12KOutputBit);
}

// Give a G31 reading of about 445 indicating we are approaching the trigger point
inline void SetOutputApproaching()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
	PORTB &= ~BITVAL(PortBDuet10KOutputBit);
	PORTB |= BITVAL(PortBDuet12KOutputBit);
}	

// Give a G31 reading of about 578 indicating we are at/past the trigger point
inline void SetOutputOn()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
	PORTB |= BITVAL(PortBDuet10KOutputBit);
	PORTB &= ~BITVAL(PortBDuet12KOutputBit);
}

// Give a G31 reading of about 1023 indicating that the sensor is saturating
inline void SetOutputSaturated()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
	PORTB |= BITVAL(PortBDuet10KOutputBit);
	PORTB |= BITVAL(PortBDuet12KOutputBit);
}

// Run the IR sensor and the fan
void runIRsensor()
writes(running; nearData; farData; offData; lastKickTicks; volatile)
{
	running = false;
	
	nearData.init();
	farData.init();
	offData.init();

	cli();
	// Set up timer 1 in mode 2 (CTC mode)
	GTCCR = 0;
	TCCR0A = BITVAL(WGM01);									// no direct outputs, mode 2
	TCCR0B = 0;												// set the mode, clock stopped for now
	TCNT0 = 0;
	OCR0A = baseTopIR;
	OCR0B = 0;
	TIFR = BITVAL(OCF0B);									// clear any pending interrupt
	TIMSK = BITVAL(OCIE0B);									// enable the timer 0 compare match B interrupt
	TCCR0B |= BITVAL(CS01);									// start the clock, prescaler = 8
	
	ADMUX = (uint8_t)AdcPhototransistorChan;				// select input 1 = phototransistor, single ended mode
	ADCSRA = BITVAL(ADEN) | BITVAL(ADATE) | BITVAL(ADPS2) | BITVAL(ADPS1);	// enable ADC, auto trigger enable, prescaler = 64 (ADC clock ~= 125kHz)
	ADCSRB = BITVAL(ADTS2) | BITVAL(ADTS0);					// start conversion on timer 0 compare match B, unipolar input mode
	tickCounter = 0;
	lastKickTicks = 0;
	sei();
	
	while (tickCounter < 4) {}								// ignore the readings from the first few interrupts after changing mode
	running = true;											// tell interrupt handler to collect readings

	for (;;)
	keep(nearData.invar(); farData.invar(); offData.invar())
	{
		cli();
		uint16_t locNearSum = nearData.sum;
		uint16_t locFarSum = farData.sum;
		uint16_t locOffSum = offData.sum;
		sei();
			
		if (locNearSum >= saturatedThreshold || locFarSum >= saturatedThreshold)
		{
			SetOutputSaturated();							// sensor is saturating, so set the output full on to indicate this
		}
		else
		{
			locNearSum = (locNearSum > locOffSum) ? locNearSum - locOffSum : 0;
			locFarSum = (locFarSum > locOffSum) ? locFarSum - locOffSum : 0;
			
			// Differential modulated IR sensor mode								
			if (locNearSum > locFarSum && locFarSum >= farThreshold)
			{
				SetOutputOn();
			}
			else if (locFarSum >= farThreshold && locNearSum * 6UL >= locFarSum * 5UL)
			{
				SetOutputApproaching();
			}
			else
			{
				SetOutputOff();
			}
		}
	
		// Check whether we need to kick the watchdog
		cli();
		uint16_t locTickCounter = tickCounter;
		sei();
		if (locTickCounter - lastKickTicks >= kickIntervalTicks)
		{
#ifndef __ECV__
			wdt_reset();											// kick the watchdog
#endif
			lastKickTicks += kickIntervalTicks;
		}
	
	}
}


// Main program
int main(void)
writes(volatile)
writes(running)
writes(nearData; farData; offData)	// IR variables
{
	cli();
	DIDR0 = BITVAL(AdcPhototransistorChan);					// disable digital input buffers on ADC pins

	// Set ports and pullup resistors
	PORTB = PortBUnusedBitMask;								// enable pullup on unused I/O pins
	
	// Enable outputs
	DDRB = BITVAL(PortBNearLedBit) | BITVAL(PortBFarLedBit) | BITVAL(PortBDuet10KOutputBit) | BITVAL(PortBDuet12KOutputBit);
	
	sei();

#ifndef __ECV__												// eCv++ doesn't understand gcc assembler syntax
	wdt_enable(WDTO_500MS);									// enable the watchdog (we kick it when checking the fan)	
#endif
		
	runIRsensor();											// doesn't return
	return 0;												// to keep gcc happy
}

// Initialize the IR data structure
void IrData::init()
{
	for (uint8_t i = 0; i < cyclesAveragedIR; ++i)
	writes(i; *this; volatile)
	keep(i <= cyclesAveragedIR)
	keep(forall j in 0..(i-1) :- readings[j] == 0)
	decrease(cyclesAveragedIR - i)
	{
		readings[i] = 0;
	}
	index = 0;
	sum = 0;
}

// End
