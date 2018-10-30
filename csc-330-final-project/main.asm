
/* 
Author: Ricky Severino
CSC-330: Organization of Computer Systems
Final Project
*/ 

.macro      set_point
            ldi         @0, low(@2)
            ldi         @1, high(@2)
.endmacro

.def		workhorse	= r16
.def        adc_value   = r17
.def        count       = r23

.cseg 
.org		0x00
			rjmp		setup
.org		0x100

.include    "WS2812B_lib.asm"

setup:		

;--------------------Change microcontroller to 8 MHz------------------------------------------------------

			ldi			workhorse,	0b10000000			; Set workhorse to 0x80 for CLKPCE 
			sts			CLKPR,		workhorse			; Enable CLKPCE
			ldi			workhorse,	0b00000001			; Set workhorse to 0x01 for CLKPS
			sts			CLKPR,		workhorse			; Change mircocontroller to 8 MHz

;--------------------Code for ADMUX and DDRD (potentiometer strip)----------------------------------------

			ldi			workhorse,	0xFF
			out			DDRD,		workhorse			; Use workhorse to set all pins in D to output
			ldi			workhorse,	0b01100000			; Using ADC0 (MUX3 through MUX0) and left adjust result bit (ADLAR)
			sts			ADMUX,		workhorse			; Using the voltage ref of AVCC (REFS1 and REFS0)

;----------------------------------------------------------------------------------------------------------

start:
            ldi         r24,        low(48)             ; Length of color array
            ldi         r25,        high(48)
            set_point   XL,XH,      0x222               ; Point to first value in data memory
            ldi         count,      0

loop:
            ldi         workhorse,  0b11000111          ; Enable the ADC (ADEN)    
            sts         ADCSRA,     workhorse           ; Starting the conversion (ADCS)
                                                        ; Using a prescalar of 128 (ADPS1 and ASPS0)
wait_adc:
            lds         workhorse,  ADCSRA
            andi        workhorse,  0b00010000          ; Test against the ADCSRA interrupt flag (ADIF)
            breq        wait_adc                        ; If the flag is not set, keep waiting
            lds         adc_value,  ADCH                ; Load ADCed valie into general purpose register

;--------------------Determine what color to display--------------------------------------------------------

maths_loop:
			ldi			workhorse,	28
			sub 		adc_value,	workhorse			; This loop is to subtract 28 from the value of ADC.
			brmi		choose_red						; Until it is < 0, increase the count, to determine which color to display
			inc			count
			rjmp		maths_loop

choose_red:
			cpi			count,		0
			brne		choose_green
			set_point	ZL, ZH,		red<<1
            ldi         workhorse,  0                   ; ldi 0 into workhorse because it will be used as a loop counter for load_from_prog_to_data
			rjmp		load_from_prog_to_data

choose_green:
			cpi			count,		1
			brne		choose_blue
			set_point	ZL, ZH,		green<<1
            ldi         workhorse,  0
			rjmp		load_from_prog_to_data

choose_blue:
			cpi			count,		2
			brne		choose_yellow
			set_point	ZL, ZH,		blue<<1
            ldi         workhorse,  0
			rjmp		load_from_prog_to_data

choose_yellow:
			cpi			count,		3
			brne		choose_cyan
			set_point	ZL, ZH,		yellow<<1
            ldi         workhorse,  0
			rjmp		load_from_prog_to_data

choose_cyan:
			cpi			count,		4
			brne		choose_magenta
			set_point	ZL, ZH,		cyan<<1
            ldi         workhorse,  0
			rjmp		load_from_prog_to_data

choose_magenta:
			set_point	ZL, ZH,		magenta<<1
            ldi         workhorse,  0
			rjmp		load_from_prog_to_data

;--------------------Load the values in the array to data memory-------------------------------------------

load_from_prog_to_data:
		
			lpm			r17,		Z+				
			st			X+,			r17
			inc			workhorse
			cp			workhorse,	r24
			brne		load_from_prog_to_data

show_colors:		
            set_point   XL,XH,      0x222               ; Point to first value in array
			rcall       output_grb
  			nop
			rjmp		start


red:		.db			0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0
green:		.db			255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0
blue:		.db			0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255, 0, 0, 255
yellow:		.db			255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0,  255, 255, 0,  255, 255, 0
cyan:		.db			255, 0 ,255, 255, 0 ,255,255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255, 255, 0 ,255
magenta:	.db			0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255, 0, 255, 255




