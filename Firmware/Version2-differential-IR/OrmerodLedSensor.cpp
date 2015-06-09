/*
 * OrmerodLedSensor.cpp
 *
 * Created: 16/02/2014 21:15:50
 *  Author: David
 */ 

#include <ecv.h>

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

#define DUAL_NOZZLE (1)		// set nonzero for dual nozzle support
#define ISR_DEBUG	(0)		// set nonzero to use PB2 as debug output pin

#if DUAL_NOZZLE && ISR_DEBUG
#error "DUAL_NOZZLE and ISR_DEBUG may not both be set"
#endif

#define BITVAL(_x) static_cast<uint8_t>(1u << (_x))

// Pin assignments:
// PA0/ADC0		digital input from Duet
// PA1/ADC1		analog input from phototransistor
// PA2/ADC2		output to Duet via 12K resistor (single nozzle) OR analog input from thermistor2 (dual nozzle)
// PA3/ADC3		analog input from thermistor (single nozzle) or 1K/4K7 sense pin (dual nozzle)
// PA4/SCLK		1K/4K7 sense pin (single nozzle) or analog input from thermistor 1 (dual nozzle). Also SCLK when programming.
// PA5/OC1B		digital output to control fan, active high. Also MISO when programming.
// PA6/OC1A		near LED drive, active low in prototype, will be active high in release. Also MOSI when programming.
// PA7/OC0B		output to Duet via 10K resistor

// PB0			far LED drive, active high
// PB1			far LED drive, active high (paralleled with PB0)
// PB2/OC0A		unused (single nozzle) OR ISR-DEBUG pin OR output to Duet via 12K resistor (dual nozzle)
// PB3/RESET	not available, used for programming

__fuse_t __fuse __attribute__((section (".fuse"))) = {0xE2u, 0xDFu, 0xFFu};

const unsigned int PortADuetInputBit = 0;
const unsigned int AdcPhototransistorChan = 1;
#if DUAL_NOZZLE
const unsigned int AdcThermistor2Chan = 2;
const unsigned int PortASeriesResistorSenseBit = 3;
const unsigned int AdcThermistor1Chan = 4;
#else
const unsigned int PortADuet12KOutputBit = 2;
const unsigned int AdcThermistor1Chan = 3;
const unsigned int PortASeriesResistorSenseBit = 4;
#endif
const unsigned int PortAFanControlBit = 5;
const unsigned int PortANearLedBit = 6;
#if DUAL_NOZZLE
const unsigned int PortADuet12KOutputBit = 7;
#else
const unsigned int PortADuet10KOutputBit = 7;
#endif

const uint8_t PortAUnusedBitMask = 0;

const uint8_t PortBFarLedMask = BITVAL(0) | BITVAL(1);
#if DUAL_NOZZLE
const unsigned int PortBDuet10KOutputBit = 2;
const uint8_t PortBUnusedBitMask = 0;
#elif ISR_DEBUG
const unsigned int PortBDebugPin = 2;
const uint8_t PortBUnusedBitMask = 0;
#else
const uint8_t PortBUnusedBitMask = BITVAL(2);
#endif

// Approximate MPU frequency (8MHz internal oscillator)
const uint32_t F_CPU = 8000000uL;

// IR parameters. These also allow us to receive a signal through the command input.
const uint16_t interruptFreq = 8000;						// interrupt frequency. We run the IR sensor at one quarter of this, i.e. 2kHz
															// highest usable value is about 9.25kHz because the ADC needs 13.5 clock cycles per conversion.
const uint16_t divisorIR = (uint16_t)(F_CPU/interruptFreq);
const uint16_t baseTopIR = divisorIR - 1;
const uint16_t cyclesAveragedIR = 8;						// must be a power of 2, max 32 (unless we make onSumIR and offSumIR uint32_t)

const uint16_t farThreshold = 10 * cyclesAveragedIR;		// minimum far reading for us to think the sensor is working properly
const uint16_t simpleNearThreshold = 30 * cyclesAveragedIR;	// minimum reading to set output high in simple mode
const uint16_t saturatedThreshold = 870 * cyclesAveragedIR;	// minimum reading for which we consider the sensor saturated

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
	
// Fan parameters
const uint16_t thermistorSampleFreq = 16;
const uint16_t thermistorSampleIntervalTicks = interruptFreq/thermistorSampleFreq;

#if DUAL_NOZZLE
const uint16_t thermistorSamplesAveraged = 8;			// reduced from 16 because it looks like we ran out of memory in the dual nozzle case
#else
const uint16_t thermistorSamplesAveraged = 16;
#endif

// Fan thresholds

// Using a 1K series resistor, we use the ADC in differential mode with a gain of 1 and full scale resolution of 512, but we reverse the inputs so we effectively get 2x extra gain.
const uint16_t thermistorConnectedThreshold1K = 30;		// we consider the hot end thermistor to be disconnected if we get this reading less than the reference, or a higher reading
const uint16_t thermistorOffThreshold1K = 340;			// we turn the fan off if we get this reading less than the reference (about 38C), or a higher reading
const uint16_t thermistorOnThreshold1K = 400;			// we turn the fan on if we get this reading less than the reference (about 42C), or lower reading

// Using a 4K7 series resistor, we use the ADC in single-ended mode with a gain of 1.
const uint16_t thermistorConnectedThreshold4K7 = 7;		// we consider the hot end thermistor to be disconnected if we get this reading less than the reference, or a higher reading
const uint16_t thermistorOffThreshold4K7 = 78;			// we turn the fan off if we get this reading less than the reference (about 38C), or a higher reading
const uint16_t thermistorOnThreshold4K7 = 92;			// we turn the fan on if we get this reading less than the reference (about 42C), or lower reading

const uint16_t fanOnSeconds = 2;						// once the fan is on, we keep it on for at least this time

// Thermistor and fan variables
typedef uint8_t invariant(value < thermistorSamplesAveraged) thermistorIndex_t;

struct ThermistorData
{	
	uint16_t readings[thermistorSamplesAveraged], offsets[thermistorSamplesAveraged];
	volatile uint16_t readingSum, offsetSum;
	thermistorIndex_t index;

	void init(uint16_t readingInit, uint16_t offsetInit)
	writes(*this; volatile)
	pre(readingInit <= 1023; offsetInit <= 1023)
	post(this->invar());

	ghost(
		bool invar() const
		returns(   (forall r in readings :- r <= 1023)
				&& (forall r in offsets :- r <= 1023)
				&& readingSum == + over readings
				&& offsetSum == + over offsets
			   );
	)

#ifdef __ECV__
	// Dummy constructor to keep eCv happy
	IrData() : index(0) {}
#endif
};

ThermistorData thermistor1Data;
#if DUAL_NOZZLE
ThermistorData thermistor2Data;
#endif

uint16_t thermistorConnectedThreshold, thermistorOnThreshold, thermistorOffThreshold;
bool thermistor1Kmode;
uint16_t lastFanSampleTicks;
uint8_t fanChangeCount;

// General variables
volatile uint16_t tickCounter;						// counts system ticks, lower 2 bits also used for ADC/LED state
bool running;

/* ISR for the timer 0 compare match A interrupt
This works on a cycle of 16 readings as follows:

State	Just did	Doing now	New LED state	New ADC state
0		Dummy off	Far			Off				(Phototransistor)
1		Far			Off			Near			(Phototransistor)
2		Off			Near		Off				(Phototransistor)
3		Near		Dummy off	Far				(Phototransistor)
4		Dummy off	Far			Off				(Phototransistor)
5		Far			Off			Near			(Phototransistor)
6		Off			Near		Off				(Phototransistor)
7		Near		Dummy off	Far				(Phototransistor)
8		Dummy off	Far			Off				(Phototransistor)
9		Far			Off			Near			(Phototransistor)
10		Off			Near		Off				Thermistor
11		Near		Dummy fan	(Off)			(Thermistor)
12		Dummy fan	Dummy fan	(Off)			(Thermistor)
13		Dummy fan	Dummy fan	(Off)			(Thermistor)
14		Dummy fan	Fan			(Off)			Phototransistor
15		Fan			Dummy off	Far				(Phototransistor)

This pattern takes account of the following:
1. When we switch the ADC into differential mode to get reliable readings with a 1K series resistor, the ADC subsystem needs extra time to settle down.
2. We want to measure the readings with near and far LEDs illuminated from the off-state in both cases, so that the slow phototransistor response affects
   both readings equally.
*/

ISR(TIM1_COMPB_vect)
writes(nearData; farData; offData)
writes(thermistor1Data)
#if DUAL_NOZZLE
writes(thermistor2Data)
#endif
writes(volatile)
pre(nearData.invar(); farData.invar(); offData.invar())
pre(thermistor1Data.invar())
#if DUAL_NOZZLE
pre(thermistor2Data.invar())
#endif
post(nearData.invar(); farData.invar(); offData.invar())
post(thermistor1Data.invar())
#if DUAL_NOZZLE
post(thermistor2Data.invar())
#endif
{
#if ISR_DEBUG
	PORTB |= BITVAL(PortBDebugPin);					// set debug pin high
#endif

	uint16_t adcVal = ADC & 1023u;					// get the ADC reading from the previous conversion
	uint8_t locTickCounter = (uint8_t)tickCounter;
	while (TCNT1 < 3 * 64) {}						// delay a little until the ADC s/h has taken effect. 3 ADC clocks should be enough, and 1 ADC clock is 64 of our clocks.
	switch(locTickCounter & 0x0fu)
	{
		case 0:
		case 4:
		case 8:
			// Far LED is on, we just did a dummy off reading, we are doing a far reading now and an off reading next
			PORTB &= ~PortBFarLedMask;				// turn far LED off
			break;

		case 1:
		case 5:
		case 9:
			// LEDs are off, we just did a far reading, we are doing an off reading now and a near reading next			
			if (running)
			{
				farData.addReading(adcVal);
			}
			PORTA |= BITVAL(PortANearLedBit);		// turn near LED on
			break;

		case 2:
		case 6:
			// Near LED is on, we just did a, off reading, we are doing a near reading now and a dummy off reading next
			if (running)
			{
				offData.addReading(adcVal);
			}
			PORTA &= ~BITVAL(PortANearLedBit);		// turn near LED off
			break;

		case 3:
		case 7:
			// LEDs are off, we just did a near reading, we are doing a dummy off reading now and a far reading next
			if (running)
			{
				nearData.addReading(adcVal);
			}
			PORTB |= PortBFarLedMask;				// turn far LED on
			break;
			
		case 10:
			// Near LED is on, we just did an off reading, we are doing a near reading now and a fan reading next
			if (running)
			{
				offData.addReading(adcVal);
			}
			PORTA &= ~BITVAL(PortANearLedBit);		// turn near LED off

#if DUAL_NOZZLE
			if ((locTickCounter & 0x20u) == 0)
			{
				// Select thermistor 1
				if (thermistor1Kmode)
				{
					ADMUX = ((locTickCounter & 0x10u) != 0)
						? 0b00110011u				// +ve input = ADC4, -ve input = ADC3, gain x20
						: 0b00010011u;				// +ve input = ADC3, -ve input = ADC4, gain x20
				}
				else
				{
					ADMUX = (uint8_t)AdcThermistor1Chan;	// select thermistor 1 (ADC4) as a single-ended input
				}
			}
			else
			{
				// Select thermistor 2
				if (thermistor1Kmode)
				{
					ADMUX = ((locTickCounter & 0x10u) != 0)
						? 0b00010001u				// +ve input = ADC2, -ve input = ADC3, gain x20
						: 0b00110001u;				// +ve input = ADC3, -ve input = ADC2, gain x20
				}
				else
				{
					ADMUX = (uint8_t)AdcThermistor2Chan;	// select thermistor 2 (ADC2) as a single-ended input
				}
			}
#else
			if (thermistor1Kmode)
			{
				ADMUX = ((locTickCounter & 0x10u) != 0)
						? 0b00010011u				// +ve input = ADC3, -ve input = ADC4, gain x20
						: 0b00110011u;				// +ve input = ADC4, -ve input = ADC3, gain x20
			}
			else
			{
				ADMUX = (uint8_t)AdcThermistor1Chan;	// select thermistor 1 (ADC3) as a single-ended input
			}
#endif			
			break;
		
		case 11:
			// LEDs are off, we just did a near reading, we are doing a fan reading which we will discard, we will do another fan reading next
			if (running)
			{
				nearData.addReading(adcVal);
			}
			break;
			
		case 12:
		case 13:
			// LEDs are off and we are doing dummy fan readings
			break;

		case 14:
			// LEDs are off, we just did a dummy fan reading, we are doing another fan reading now and a dummy off reading next
			ADMUX = (uint8_t)AdcPhototransistorChan;	// select input 1 = phototransistor
			break;

		case 15:
			// LEDs are off, we just did a fan reading, we are doing an off reading now and a far reading next
			if (running)
			{
				ThermistorData* currentThermistor =
#if DUAL_NOZZLE
					((locTickCounter & 0x20u) == 0) ? &thermistor1Data : &thermistor2Data;
#else
					&thermistor1Data;
#endif
				if (thermistor1Kmode)
				{
					adcVal ^= 0x0200u;				// convert signed reading to unsigned biased by 512
					if ((locTickCounter & 0x10u) != 0)
					{
						currentThermistor->readingSum = currentThermistor->readingSum - currentThermistor->readings[currentThermistor->index] + adcVal;
						currentThermistor->readings[currentThermistor->index] = adcVal;
						currentThermistor->index = (currentThermistor->index + 1) & (thermistorSamplesAveraged - 1);
					}
					else
					{
						currentThermistor->offsetSum = currentThermistor->offsetSum - currentThermistor->offsets[currentThermistor->index] + adcVal;
						currentThermistor->offsets[currentThermistor->index] = adcVal;
					}
				}
				else
				{
					currentThermistor->readingSum = currentThermistor->readingSum - currentThermistor->readings[currentThermistor->index] + adcVal;
					currentThermistor->readings[currentThermistor->index] = adcVal;
					currentThermistor->index = (currentThermistor->index + 1) & (thermistorSamplesAveraged - 1);
				}
			}
			PORTB |= PortBFarLedMask;				// turn far LED on
			break;
	}
	
	++tickCounter;

#if ISR_DEBUG
	PORTB &= (uint8_t)(~BITVAL(PortBDebugPin) & 0xFFu);	// set debug pin high
#endif
}

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

// Check the fan
void checkFan()	
writes(fanChangeCount; volatile)
{
	if ((PORTA & BITVAL(PortAFanControlBit)) != 0)
	{
		// Fan is on. Turn it off if thermistor is connected and temp <= off-threshold
		if (   (thermistor1Data.readingSum < thermistor1Data.offsetSum)
#if DUAL_NOZZLE
			&& (thermistor2Data.readingSum < thermistor2Data.offsetSum)
#endif
		   )
		{
			uint16_t fanDiff1 = thermistor1Data.offsetSum - thermistor1Data.readingSum;
#if DUAL_NOZZLE
			uint16_t fanDiff2 = thermistor2Data.offsetSum - thermistor2Data.readingSum;
#endif
			if (   (fanDiff1 >= thermistorConnectedThreshold) && (fanDiff1 <= thermistorOffThreshold)
#if DUAL_NOZZLE
				&& (fanDiff2 >= thermistorConnectedThreshold) && (fanDiff2 <= thermistorOffThreshold)
#endif
			   )
			{
				if (fanChangeCount == 0)
				{
					PORTA &= (uint8_t)~BITVAL(PortAFanControlBit);	// turn fan off						
				}
				else
				{
					--fanChangeCount;
				}
			}
		}			
	}
	else
	{
		uint16_t fanDiff1;
#if DUAL_NOZZLE
		uint16_t fanDiff2;
#endif
		// Fan is off. Turn it on if thermistor is disconnected or temp >= on-threshold
		if (   (thermistor1Data.readingSum >= thermistor1Data.offsetSum)
			|| ((fanDiff1 = thermistor1Data.offsetSum - thermistor1Data.readingSum) < thermistorConnectedThreshold)
			|| (fanDiff1 >= thermistorOnThreshold)
#if DUAL_NOZZLE
			|| (thermistor2Data.readingSum >= thermistor2Data.offsetSum)
			|| ((fanDiff2 = thermistor2Data.offsetSum - thermistor2Data.readingSum) < thermistorConnectedThreshold)
			|| (fanDiff2 >= thermistorOnThreshold)
#endif
		   )
		{
			// We used to turn the fan on immediately, but now we delay it a little to try to improve noise immunity
			if (fanChangeCount >= fanOnSeconds * thermistorSampleFreq)
			{
				PORTA |= BITVAL(PortAFanControlBit);		// turn fan on			
			}
			else
			{
				fanChangeCount += 4;						// the time we wait before turning the fan on is 1/4 of the time we wait before turning it off
			}
		}		
	}
	
#ifndef __ECV__
	wdt_reset();											// kick the watchdog
#endif
}

// Give a G31 reading of about 0
inline void SetOutputOff()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
#if DUAL_NOZZLE
	PORTB &= ~BITVAL(PortBDuet10KOutputBit);
	PORTA &= ~BITVAL(PortADuet12KOutputBit);
#else
	PORTA &= ~BITVAL(PortADuet10KOutputBit);
	PORTA &= ~BITVAL(PortADuet12KOutputBit);
#endif
}

// Give a G31 reading of about 465 indicating we are approaching the trigger point
inline void SetOutputApproaching()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
#if DUAL_NOZZLE
	PORTB &= ~BITVAL(PortBDuet10KOutputBit);
	PORTA |= BITVAL(PortADuet12KOutputBit);
#else
	PORTA &= ~BITVAL(PortADuet10KOutputBit);
	PORTA |= BITVAL(PortADuet12KOutputBit);
#endif
}	

// Give a G31 reading of about 535 indicating we are at/past the trigger point
inline void SetOutputOn()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
#if DUAL_NOZZLE
	PORTB |= BITVAL(PortBDuet10KOutputBit);
	PORTA &= ~BITVAL(PortADuet12KOutputBit);
#else
	PORTA |= BITVAL(PortADuet10KOutputBit);
	PORTA &= ~BITVAL(PortADuet12KOutputBit);
#endif
}

// Give a G31 reading of about 1023 indicating that the sensor is saturating
inline void SetOutputSaturated()
writes(volatile)
{
	// We do this in 2 operations, each of which is atomic, so that we don't mess up what the ISR is doing with the LEDs.
#if DUAL_NOZZLE
	PORTB |= BITVAL(PortBDuet10KOutputBit);
	PORTA |= BITVAL(PortADuet12KOutputBit);
#else
	PORTA |= BITVAL(PortADuet10KOutputBit);
	PORTA |= BITVAL(PortADuet12KOutputBit);
#endif
}

// Run the IR sensor and the fan
void runIRsensorAndFan()
writes(running; nearData; farData; offData; volatile)
writes(fanChangeCount; lastFanSampleTicks)
pre(thermistor1Data.invar())
#if DUAL_NOZZLE
pre(thermistor2Data.invar())
#endif
{
	running = false;
	
	nearData.init();
	farData.init();
	offData.init();

	cli();
	// Set up timer 1 in mode 12
	TCCR1A = 0;												// no direct outputs
	TCCR1B = BITVAL(WGM13) | BITVAL(WGM12);					// set the mode, clock stopped for now
	TCCR1C = 0;
	TCNT1 = 0;
	ICR1 = baseTopIR;
	OCR1B = 0;
	TIFR1 = BITVAL(OCF1B);									// clear any pending interrupt
	TIMSK1 = BITVAL(OCIE1B);								// enable the timer 0 compare match B interrupt
	TCCR1B |= BITVAL(CS10);									// start the clock
	
	ADMUX = (uint8_t)AdcPhototransistorChan;				// select phototransistor input, single-ended mode
	ADCSRA = BITVAL(ADEN) | BITVAL(ADATE) | BITVAL(ADPS2) | BITVAL(ADPS1);	// enable ADC, auto trigger enable, prescaler = 64 (ADC clock ~= 125kHz)
	ADCSRB = BITVAL(ADTS2) | BITVAL(ADTS0) | BITVAL(BIN);	// start conversion on timer 1 compare match B, bipolar input mode when using differential inputs
	tickCounter = 0;
	sei();
	
	while (tickCounter < 4) {}								// ignore the readings from the first few interrupts after changing mode
	running = true;											// tell interrupt handler to collect readings
	lastFanSampleTicks = 0;

	for (;;)
	keep(nearData.invar(); farData.invar(); offData.invar())
	keep(thermistor1Data.invar())
#if DUAL_NOZZLE
	keep(thermistor2Data.invar())
#endif
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
			
			if ((PINA & BITVAL(PortADuetInputBit)) == 0)
			{
				// Backup mode (simple modulated IR sensor mode), suitable for x-endstop detection.
				// We use only the near reading, because the far one can be high at too long a range.
				if (locNearSum >= simpleNearThreshold)
				{
					SetOutputOn();
				}
				else
				{
					// Don't give an 'approaching' reading when using the simple sensor, to help confirm which sensor we are using
					SetOutputOff();
				}
			}
			else
			{
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
		}
		
		// Check whether we need to poll the fan
		cli();
		uint16_t locTickCounter = tickCounter;
		sei();
		if (locTickCounter - lastFanSampleTicks >= thermistorSampleIntervalTicks)
		{
			checkFan();
			lastFanSampleTicks += thermistorSampleIntervalTicks;
		}
	}
}


// Main program
int main(void)
writes(volatile)
writes(running)
writes(nearData; farData; offData)	// IR variables
writes(thermistor1Data)
#if DUAL_NOZZLE
writes(thermistor2Data)
#endif
writes(fanChangeCount; lastFanSampleTicks)				// fan variables
writes(thermistor1Kmode; thermistorConnectedThreshold; thermistorOffThreshold; thermistorOnThreshold)
{
	cli();
#if DUAL_NOZZLE
	DIDR0 = BITVAL(AdcPhototransistorChan) | BITVAL(AdcThermistor1Chan) | BITVAL(AdcThermistor2Chan);
	// disable digital input buffers on ADC pins
#else
	DIDR0 = BITVAL(AdcPhototransistorChan) | BITVAL(AdcThermistor1Chan);
															// disable digital input buffers on ADC pins
#endif
	// Set ports and pullup resistors
	PORTA = BITVAL(PortADuetInputBit) | BITVAL(PortASeriesResistorSenseBit) | PortAUnusedBitMask;
															// enable pullup on Duet input, series resistor sense input, and unused I/O pins
	PORTB = PortBUnusedBitMask;								// enable pullup on unused I/O pins
	
	// Enable outputs
#if DUAL_NOZZLE
	DDRA = BITVAL(PortAFanControlBit) | BITVAL(PortANearLedBit) | BITVAL(PortADuet12KOutputBit);
#else
	DDRA = BITVAL(PortAFanControlBit) | BITVAL(PortANearLedBit) | BITVAL(PortADuet10KOutputBit) | BITVAL(PortADuet12KOutputBit);
#endif

#if DUAL_NOZZLE
	DDRB = PortBFarLedMask | BITVAL(PortBDuet10KOutputBit);	// enable LED and 12K outputs on port B
#elif ISR_DEBUG
	DDRB = PortBFarLedMask | BITVAL(PortBDebugPin);			// enable LED and debug outputs on port B
#else
	DDRB = PortBFarLedMask;									// enable LED outputs on port B
#endif
	
	// Wait 10ms to ensure that the power has stabilized before we read the series resistor sense pin
	for (uint8_t i = 0; i < 40; ++i)
	{
		shortDelay(255u);
	}
	thermistor1Kmode = ((PINA & BITVAL(PortASeriesResistorSenseBit)) != 0);
	
	// Initialize the fan so that it won't come on at power up
	uint16_t readingInit, offsetInit;
	if (thermistor1Kmode)
	{
		// When reading the thermistor in 1K series resistor mode, we run ADC in differential bipolar mode, gain = 20 (effective gain is 10 because full-scale is 512 not 1024)
		// We use the 1K mode sense pin as a +3.3V reference. Set it HIGH to reduce noise on it. We have already set the bit in the output register.
		DDRA |= BITVAL(PortASeriesResistorSenseBit);
		
		thermistorConnectedThreshold = thermistorConnectedThreshold1K * thermistorSamplesAveraged;
		thermistorOffThreshold = thermistorOffThreshold1K * thermistorSamplesAveraged;
		thermistorOnThreshold = thermistorOnThreshold1K * thermistorSamplesAveraged;
		offsetInit = 512;
		readingInit = offsetInit - thermistorConnectedThreshold1K;
	}
	else
	{
		// When reading the thermistor in 4.7K series resistor mode, we run ADC in single-ended mode, gain = 1
		thermistorConnectedThreshold = thermistorConnectedThreshold4K7 * thermistorSamplesAveraged;
		thermistorOffThreshold = thermistorOffThreshold4K7 * thermistorSamplesAveraged;
		thermistorOnThreshold = thermistorOnThreshold4K7 * thermistorSamplesAveraged;
		offsetInit = 1023;
		readingInit = offsetInit - thermistorConnectedThreshold4K7;
	}

	thermistor1Data.init(readingInit, offsetInit);
#if DUAL_NOZZLE
	thermistor2Data.init(readingInit, offsetInit);
#endif

	sei();

#ifndef __ECV__												// eCv++ doesn't understand gcc assembler syntax
	wdt_enable(WDTO_500MS);									// enable the watchdog (we kick it when checking the fan)	
#endif
		
	runIRsensorAndFan();									// doesn't return
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

// Initialize the thermistor data structure
void ThermistorData::init(uint16_t readingInit, uint16_t offsetInit)
{
	readingSum = 0;
	offsetSum = 0;

	for (uint8_t i = 0; i < thermistorSamplesAveraged; ++i)
	writes(i; *this; volatile)
	keep(i <= thermistorSamplesAveraged)
	keep(forall j in 0..(i - 1) :- readings[j] == readingInit)
	keep(forall j in 0..(i - 1) :- offsets[j] == offsetInit)
	keep(readingSum == + over readings.take(i))
	keep(offsetSum == + over offsets.take(i))
	decrease(thermistorSamplesAveraged - i)
	{
		readings[i] = readingInit;
		readingSum += readingInit;
		offsets[i] = offsetInit;
		offsetSum += offsetInit;
	}
	index = 0;
}

// End
