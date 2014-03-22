/*
 * OrmerodSensor.cpp
 *
 * Created: 16/02/2014 21:15:50
 *  Author: David
 */ 

// Pin assignments:
// PA0			digital input from Duet, high for IR, low for ultrasonic
// PA1/ADC1		analog input from IR sensor
// PA2/ADC2		analog input from ultrasonic transducer
// PA3/ADC3		analog input from thermistor
// PA4/SCLK		unused except for programming and debug
// PA5			digital output to control fan, high = on
// PA6/OC1A		output to ultrasonic transducer
// PA7/OC0B		pseudo-DAC output, most significant byte

// PB0,1		not available when using a ceramic resonator
// PB2/OC0A		pseudo-DAC output, least significant byte
// PB3/RESET	not available, used for programming

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

#define ISR_DEBUG	(0)

#define BITVAL(_x) (1u << _x)

const uint32_t F_CPU = 12000000uL;
const uint16_t defaultBaseTopU = 144;
const int16_t defaultPhaseDelay = -20;

// Ultrasonic parameters
// baseTopU is the value we program into ICR1A to define the TOP value.
uint16_t baseTopU = defaultBaseTopU;

// phaseDelay is the number of clock cycles by which the ADC sampling leads the output transition.
// Needs to be <= 34 so that we read the output pin in the correct sense.
// We could use >= 40 if we inverted the sense in which re read the output pin.
// IUt can be positive or negative.
int16_t phaseDelay = defaultPhaseDelay;

const uint16_t cyclesAveragedU = 32;				// must be a power of 2, max 128

// Ultrasonic variables
volatile int16_t diffU;
uint8_t posReadings[cyclesAveragedU], negReadings[cyclesAveragedU];
typedef uint8_t invariant(value < cyclesAveragedU) uIndex_t;
uIndex_t posIndex, negIndex;

// IR parameters. These also allow us to receive a signal through the command input.
const uint16_t freqIR = 4000;						// interrupt frequency. We run the IR sensor at 2kHz.
const uint16_t divisorIR = (uint16_t)(F_CPU/freqIR);
const uint16_t baseTopIR = divisorIR - 1;
const uint16_t cyclesAveragedIR = 8;				// must be a power of 2, max 32 (unless we make onSumIR and offSumIR uint32_t)

// IR variables
volatile uint16_t onSumIR, offSumIR;
uint16_t onReadings[cyclesAveragedIR], offReadings[cyclesAveragedIR];
typedef uint8_t invariant(value < cyclesAveragedIR) irIndex_t;
irIndex_t onIndex, offIndex;

// Fan parameters
const uint16_t fanSampleFreq = 16;
const uint16_t fanSamplesAveraged = 16;
const uint16_t thermistorFailureThreshold = 1023;	// we consider the hot end thermistor to have become disconnected if we get this reading or above
const uint16_t thermistorOnThreshold = 1005;		// we consider then hot end to need cooling of we get this reading or lower (about 42C)
const uint16_t thermistorOffThreshold = 1008;		// we consider then hot end to need cooling of we get this reading or lower (about 38C)
const uint16_t fanOnSeconds = 3;					// once the fan is on, we keep it on for at least this time

// Fan variables
uint16_t fanReadings[fanSamplesAveraged];
uint16_t fanSum;
typedef uint8_t invariant(value < fanSamplesAveraged) fanIndex_t;
fanIndex_t fanIndex;
uint8_t fanChangeCount;

volatile uint16_t tickCounter;

// General parameters

enum Mode { ModeOff = 0, ModeIR = 1, ModeUltrasonic = 2 };
	
Mode currentMode = ModeOff;

// ISR for the timer 0 compare match B interrupt
ISR(TIM1_COMPB_vect)
writes(posReadings; posIndex; negReadings; negIndex; onReadings; onIndex; offReadings; offIndex; volatile)
{
#ifdef ISR_DEBUG
	PORTA |= BITVAL(4);			// set debug pin high
#endif

	switch(currentMode)
	{
	case ModeUltrasonic:
		// This needs to be kept fast because interrupts occur at about 83kHz
		{
			uint8_t adcVal = ADCH;
			if ((PINA & BITVAL(6)) != 0)
			{
				diffU = diffU - (int16_t)posReadings[posIndex] + (int16_t)adcVal;
				posReadings[posIndex] = adcVal;
				posIndex = (posIndex + 1) & (cyclesAveragedU - 1);
			}
			else
			{
				diffU = diffU + (int16_t)negReadings[negIndex] - (int16_t)adcVal;
				negReadings[negIndex] = adcVal;
				negIndex = (negIndex + 1) & (cyclesAveragedU - 1);
			}
		}
		break;
		
	case ModeIR:
		// These interrupts happen at 16kHz so we have much more time
		{
			uint16_t adcVal = ADC & 1023u;
			if ((PINA & BITVAL(6)) == 0)
			{
				onSumIR = onSumIR - onReadings[onIndex] + adcVal;
				onReadings[onIndex] = adcVal;
				onIndex = (onIndex + 1) & (cyclesAveragedIR - 1);
			}
			else
			{
				offSumIR = offSumIR - offReadings[offIndex] + adcVal;
				offReadings[offIndex] = adcVal;
				offIndex = (offIndex + 1) & (cyclesAveragedIR - 1);
			}
		}
		break;
		
	default:
		break;
	}
	++tickCounter;

#ifdef ISR_DEBUG
	PORTA &= (uint8_t)~BITVAL(4);			// set debug pin high
#endif
}

void shortDelay(uint8_t n)
{
	for (uint8_t i = 0; i < n; ++i)
	keep(i <= n)
	decrease(n - i)
	{
#ifndef __ECV__
		asm volatile ("nop");
#endif
	}
}

// Process an ADC reading from the hot end thermistor
void processThermistorReading(uint16_t adcVal)	
writes(currentMode; fanSum; fanReadings; fanIndex; fanChangeCount; volatile)
pre(fanSum == + over fanReadings)
post(fanSum == + over fanReadings)
{
	fanSum = fanSum - fanReadings[fanIndex] + adcVal;
	fanReadings[fanIndex] = adcVal;
	fanIndex = (fanIndex + 1) & (fanSamplesAveraged - 1);
	
	if ((PORTA & BITVAL(5)) != 0)
	{
		// Fan is on. Turn it off if we have no thermistor failure or temp <= off-threshold
		if (fanSum < thermistorFailureThreshold * fanSamplesAveraged && fanSum >= thermistorOffThreshold * fanSamplesAveraged)
		{
			if (fanChangeCount == 0)
			{
				PORTA &= (uint8_t)~BITVAL(5);				// turn fan off						
			}
			else
			{
				--fanChangeCount;
			}
		}
	}
	else
	{
		// Fan is off. Turn it on if we have thermistor failure or temp >= on-threshold
		if (fanSum >= thermistorFailureThreshold * fanSamplesAveraged || fanSum <= thermistorOnThreshold * fanSamplesAveraged)
		{
			PORTA |= BITVAL(5);								// turn fan on
			fanChangeCount = (fanOnSeconds * fanSampleFreq) - 1;
		}		
	}
	
#ifndef __ECV__
	wdt_reset();											// kick the watchdog
#endif
}

// Read the hot end temperature and set fan on/off as necessary
void checkFan()
writes(currentMode; fanSum; fanReadings; fanIndex; fanChangeCount; volatile)
pre(fanSum == + over fanReadings)
post(fanSum == + over fanReadings)
{
	currentMode = ModeOff;									// stop the tick ISR messing with the ADC
	
	ADCSRA = BITVAL(ADPS2) | BITVAL(ADPS1);					// disable ADC, no auto trigger, prescaler = 64 (ADC clock = 187.5kHz)
	ADCSRB = 0;
	ADMUX = BITVAL(MUX1) | BITVAL(MUX0);					// select input 3
	ADCSRA |= BITVAL(ADEN);									// enable ADC
	shortDelay(10);											// let it settle
	ADCSRA |= BITVAL(ADSC);									// start conversion
	while ((ADCSRA & BITVAL(ADSC)) != 0) {}					// wait for conversion to complete
	shortDelay(10);											// let it settle
	ADCSRA |= BITVAL(ADSC);									// do another conversion, otherwise the result can depend on whether we are running IR or ultrasonic
	while ((ADCSRA & BITVAL(ADSC)) != 0) {}					// wait for conversion to complete
	processThermistorReading(ADC & 1023u);
}	

// Set up the ADC to trigger off compare match B and take readings from the IR sensor
// The timer has already been set up. This returns with interrupts enabled.
void setAdcIR()
writes(currentMode; volatile)
pre(currentMode == ModeOff)
post(currentMode == ModeIR)
{
	cli();
	ADMUX = BITVAL(MUX0);									// select input 1
	ADCSRA = BITVAL(ADEN) | BITVAL(ADATE) | BITVAL(ADPS2) | BITVAL(ADPS1);		// enable ADC, auto trigger enable, prescaler = 64 (ADC clock = 187.5kHz)
	ADCSRB = BITVAL(ADTS2) | BITVAL(ADTS0);					// start conversion on timer 1 compare match B
	tickCounter = 0;
	sei();
	while (tickCounter < 2) {}								// ignore the readings from the first 2 interrupts after changing mode
	currentMode = ModeIR;									// tell interrupt handler to collect readings	
}

// Run the IR sensor and the fan
void runIRsensorAndFan()
writes(currentMode; onReadings; offReadings; onIndex; offIndex; volatile)
writes(fanSum; fanReadings; fanIndex; fanChangeCount)
pre(currentMode == ModeOff)
pre(fanSum == + over fanReadings)
post(fanSum == + over fanReadings)
{
	for (uint8_t i = 0; i < cyclesAveragedIR; ++i)
	keep(i <= cyclesAveragedIR)
	keep(forall j in 0..(i-1) :- onReadings[j] == 0 && offReadings[j] == 0)
	decrease(cyclesAveragedIR - i)
	{
		onReadings[i] = offReadings[i] = 0;		
	}
	onIndex = offIndex = 0;
	onSumIR = offSumIR = 0;

	cli();
	// Set up timer 1 in mode 12, toggle OC1A on compare match (mode 14 doesn't seem to work)
	TCCR1A = BITVAL(COM1A0);
	TCCR1B = BITVAL(WGM13) | BITVAL(WGM12);					// set the mode, clock stopped for now
	TCCR1C = 0;
	TCNT1 = 0;
	ICR1 = baseTopIR;
	OCR1A = (uint16_t)(F_CPU/50000u);						// invert the output 20us after the ADC starts a conversion
	OCR1B = 0;
	DDRA |= BITVAL(6);										// enable OCR1A output
	TIFR1 = BITVAL(OCF1B);									// clear any pending interrupt
	TIMSK1 = BITVAL(OCIE1B);								// enable the timer 0 compare match B interrupt
	TCCR1B |= BITVAL(CS10);									// start the clock
	
	setAdcIR();												// this also enables interrupts

	// Monitor PA0 for a transition to low, which indicates a change to ultrasonic sensing
	while ((PINA & BITVAL(0)) != 0)
	keep(fanSum == + over fanReadings)
	{
		// Calculate the average
		cli();
		uint16_t locOnSum = onSumIR;
		uint16_t locOffSum = offSumIR;
		sei();
		
		uint16_t rslt;
		if (locOnSum < locOffSum)
		{
			rslt = 0;
		}
		else if (locOnSum > 750 * cyclesAveragedIR)
		{
			// IR sensor is saturating so return 1023
			rslt = 1023 * cyclesAveragedIR;
		}
		else
		{
			rslt = locOnSum - locOffSum;
		}
		
		// Output the average to the pseudo-DAC
		rslt *= (64/cyclesAveragedIR);						// convert 10-bit ADC value to 16-bit
		OCR0A = (uint8_t)rslt;
		OCR0B = (uint8_t)(rslt >> 8);
		
		// Check whether we need to poll the fan
		cli();
		uint16_t locTickCounter = tickCounter;
		sei();
		if (locTickCounter >= F_CPU/(fanSampleFreq * baseTopIR))	// if 1/16 sec has passed
		{
			checkFan();
			setAdcIR();										// restart normal reading		
		}
	}
		
	TIMSK1 = 0;												// disable timer interrupts
	currentMode = ModeOff;									// disable the ISR
	TCCR1B = BITVAL(WGM13) | BITVAL(WGM12);					// stop the timer clock
}

// Set up the ADC to trigger off compare match B and take readings from the ultrasonic sensor
// The timer has already been set up. This returns with interrupts enabled.
void setAdcUltrasonic()
writes(currentMode; volatile)
post(currentMode == ModeUltrasonic)
{
	cli();
	// Since we run timer 1 at about 80kHz and an ADC conversion takes around 13 ADC clocks, we have to increase the ADC clock rate to at least about 1.1MHz.
	// We achieve this by using a 12MHz crystal and a prescaler of 8, giving an ADC clock of 1.5MHz. This is outside the characterized specification of the ADC, but seems to work OK.
	ADMUX = BITVAL(MUX1);									// select input 2
	ADCSRA = BITVAL(ADEN) | BITVAL(ADATE) | BITVAL(ADPS1) | BITVAL(ADPS0);		// enable ADC, auto trigger enable, prescaler = 8
	ADCSRB = BITVAL(ADLAR) | BITVAL(ADTS2) | BITVAL(ADTS0);	// start conversion on timer 1 compare match B, left adjust result because we only want 8 bits
	tickCounter = 0;
	sei();
	while (tickCounter < 2) {}								// ignore the readings from the first 2 interrupts after changing mode
	currentMode = ModeUltrasonic;							// enable the ISR
}

// Run the ultrasonic transducer and the fan
void runUltrasonicSensorAndFan()
writes(currentMode; posReadings; negReadings; posIndex; negIndex; volatile)
writes(fanSum; fanReadings; fanIndex; fanChangeCount)
pre(currentMode == ModeOff)
pre(fanSum == + over fanReadings)
post(fanSum == + over fanReadings)
{
	currentMode = ModeOff;
	for (uint8_t i = 0; i < cyclesAveragedU; ++i)
	keep(i <= cyclesAveragedU)
	keep(forall j in 0..(i-1) :- posReadings[j] == 0 && negReadings[j] == 0)
	decrease(cyclesAveragedU - i)
	{
		posReadings[i] = negReadings[i] = 0;
	}
	posIndex = negIndex = 0;
	diffU = 0;

	// Turn the fan on because we can't monitor it and the ultrasonic transducer at the same time
	
	// Set up timer 1 to generate a signal at approx. 40kHz in fast PWM mode
	// We use mode 12 with toggle OC1A on compare match (mode 14 doesn't seem to work)
	cli();
	TCCR1A = BITVAL(COM1A0);
	TCCR1B = BITVAL(WGM13) | BITVAL(WGM12);					// set mode, clock stopped for now
	TCCR1C = 0;
	TCNT1 = 0;
	ICR1 = baseTopU;
	if (phaseDelay >= 0)
	{
		OCR1A = (uint16_t)phaseDelay;
		OCR1B = 0;		
	}
	else
	{
		OCR1A = 0;
		OCR1B = (uint16_t)(-phaseDelay);		
	}
	DDRA |= BITVAL(6);										// enable OCR1A output
	TIFR1 = BITVAL(OCF1B);									// clear any existing interrupt
	TIMSK1 = BITVAL(OCIE1B);								// enable the timer 0 compare match B interrupt
	TCCR1B |= BITVAL(CS10);									// start the clock
	
	setAdcUltrasonic();										// this enables interrupts before returning

	while ((PINA & BITVAL(0)) == 0)
	keep(fanSum == + over fanReadings)
	{
		// Calculate the average
		cli();
		int16_t locDiff = diffU;
		sei();
		
		uint16_t rslt;
		if (locDiff < 0)
		{
			rslt = 0;
		}
		else
		{
			rslt = (uint16_t)locDiff;
		}		
		// Output the average to the pseudo-DAC
		rslt *= (256/cyclesAveragedU);
		OCR0A = (uint8_t)rslt;
		OCR0B = (uint8_t)(rslt >> 8);

		// Check whether we need to poll the fan
		cli();
		uint16_t locTickCounter = tickCounter;
		sei();
		if (locTickCounter >= F_CPU/(fanSampleFreq * defaultBaseTopU))	// if 1/16 sec has passed
		{
			checkFan();
			setAdcUltrasonic();								// restart normal reading
		}
	}
	
	TIMSK1 = 0;												// disable timer interrupts
	currentMode = ModeOff;									// disable the ISR		
	TCCR1B = BITVAL(WGM13) | BITVAL(WGM12);					// stop the timer clock
}

// Main program
int main(void)
writes(currentMode; volatile)
writes(onReadings; offReadings; onIndex; offIndex)			// IR variables
writes(posReadings; negReadings; posIndex; negIndex)		// ultrasonic variables
writes(fanSum; fanReadings; fanIndex; fanChangeCount)		// fan variables
{
	cli();
	DIDR0 = BITVAL(1) | BITVAL(2) | BITVAL(3);				// disable digital input buffers on ADC pins

	// Set ports and pullup resistors
	PORTA = BITVAL(0);										// enable pullup on PA0
	PORTB = 0;
	
	// Enable outputs
	DDRA = BITVAL(7) | BITVAL(5) | BITVAL(4);				// enable OC0B, fan and debug outputs
	DDRB = BITVAL(2);										// enable OC0A
	
	// Set up timer 0 to generate fast PWM (mode 3) on OC0A and OC0B. This is used for D to A conversion.
	TCCR0A = BITVAL(COM0A1) | BITVAL(COM0B1) | BITVAL(WGM01) | BITVAL(WGM00);
	TCCR0B = BITVAL(CS00);									// prescaler = 1 to get max PWM frequency
	OCR0A = 0;
	OCR0B = 0;
	
	sei();
	
	// Initialize the fan so that it won't come on at power up
	fanSum = 0;
	for (uint8_t i = 0; i < fanSamplesAveraged; ++i)
	keep(i <= fanSamplesAveraged)
	keep(forall j in 0..(i - 1) :- fanReadings[j] == thermistorFailureThreshold - 1)
	keep(fanSum == + over fanReadings.take(i))
	decrease(fanSamplesAveraged - i)
	{
		fanReadings[i] = thermistorFailureThreshold - 1;
		fanSum += thermistorFailureThreshold - 1;
	}
	fanIndex = 0;
	
#ifndef __ECV__												// eCv++ doesn't understand gcc assembler syntax
	wdt_enable(WDTO_500MS);									// enable the watchdog (we kick it when checking the fan)	
#endif
		
    for(;;)
	keep(fanSum == + over fanReadings)
    {
		currentMode = ModeOff;
	
		// If PA0 if high, run the IR code, else run the ultrasonic code
		if ((PINA & BITVAL(0)) != 0)
		{
			runIRsensorAndFan();
		}
		else
		{
			runUltrasonicSensorAndFan();
		}						
    }
	return 0;
}
