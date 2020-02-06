#include <pi16f887.inc>
list p=16f887

	cblock	0x20		;nomendo endereco da mamória
		led_cnt
	endc

	org 	0x00		;vetor de reset
	goto 	Start
	
	org 	0x04		;vetor interrupção
	retfie
	
Start:
	;---- I/O config ----
	;tris 0 input
	;tris 1 output
	
	bsf STATUS, RP0 	;seleciona do bank0 00 to bank1 01
	movlw B'11110000'	;bit menos significativo à direita
	movwf TRISA			;configura RA0-RA3 como output
						;configura RA4-RA7 como input
	bsf STATUS, RP1		;seleciona do bank1 01 to bank3 11
	clrf ANSEL 			;configura PORTA como entrada digital
	
Main:

	call RotinaInicializacao
	;bcf STATUS, RPO		;seleciona do bank3 11 to bank2 10
	;bcf STATUS, RP1		;seleciona do bank2 10 to bank0 00

RotinaInicializacao:
	
	bcf	 	STATUS, RPO		;seleciona do bank3 11 to bank2 10
	bcf 	STATUS, RP1		;seleciona do bank2 10 to bank0 00
	movlw 	0x0F			;movendo b"00001111"
	movwf	PORTA			;ligando os LEDs
							;set pinos RA0-RA3
	call 	Delay_1s		;chama função Delay
	clrf	led_cnt			;led_cnt = 0
	
LedContLoop:

	clrf 	PORTA			;clear PORTA zerando pinos RA0-RA3
	
	movlw	.0
	subwf	led_cnt, W		;subtrai w de led_cont
	btfsc	STATUS, Z		;comparação led_cnt = 0?
	bsf		PORTA,RA0		;sim
							;não
	movlw	.1
	subwf	led_cnt, W		;subtrai w de led_cont
	btfsc	STATUS, Z		;comparação led_cnt = 1?
	bsf		PORTA,RA1		;sim
							;não
	movlw	.2
	subwf	led_cnt, W		;subtrai w de led_cont
	btfsc	STATUS, Z		;comparação led_cnt = 2?
	bsf		PORTA,RA2		;sim
							;não
	movlw	.3
	subwf	led_cnt, W		;subtrai w de led_cont
	btfsc	STATUS, Z		;comparação led_cnt = 3?
	bsf		PORTA,RA3		;sim
							;não
							
	call	Delay_200ms		;chama função delay_200ms
	
	incf	led_cnt, F		;inclemente led_cont
	
	movlw	.4
	subwf	led_cnt, W		;subtrai w de led_cont
	btfss	STATUS, Z		;comparação led_cnt = 4?
	goto	LedContLoop		;não
	clrf	PORTA			;sim
	return
	
