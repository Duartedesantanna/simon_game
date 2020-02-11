#include <p16f887.inc>
#define	button	PORTB, RB0
list p=16f887
__CONFIG _CONFIG1, 0x2FF4
__CONFIG _CONFIG2, 0x3FFF

	cblock	0x20			;nomendo endereco da mamória
		led_cnt
		cnt_1
		cnt_2
		_wreg
		_status
		timer_counter_5s
		timer_counter_500ms
		level 	; level::
				; 1 = hard
				; 0 = easy
		sequency
		move
	endc
	
	;cblock	0x5F
	;	move_pointer		;ponteiro para memória de movimentos
	;endc
	
	MOVE_BASE_ADDR	EQU	0x5F
	TMR0_50MS	EQU	.61
	LED_RED		EQU	B'00000001'
	LED_YELLOW	EQU	B'00000010'
	LED_GREEN	EQU	B'00000100'
	LED_BLUE	EQU	B'00001000'

	org 	0x00			;vetor de reset
	goto 	Start
	
	org 	0x04			;vetor interrupção
	movwf	_wreg
	swapf	STATUS, W
	movwf	_status
	clrf	STATUS			;limpar STATUS para garantir que estamos no bank0
	btfsc	INTCON, T0IF	;T0IF == 1?
	goto	Timer0Interrupt	;sim	
	goto	ExitInterrupt	;nao

Timer0Interrupt:

	bcf		INTCON, T0IF
	incf	timer_counter_5s, F
	incf	timer_counter_500ms, F
	movlw	TMR0_50MS
	movwf	TMR0			;reseta TMR0 contador
	goto 	ExitInterrupt
	
ExitInterrupt:

	swapf	_status, W
	movwf	STATUS
	swapf	_wreg, F
	swapf	_wreg, W
	retfie
	
Start:
	;---- I/O config ----
	;tris 0 input
	;tris 1 output
	
	clrf	timer_counter_5s	;limpa timer_counter_5s
	clrf	timer_counter_500ms	;limpa timer_counter_500ms
	bsf 	STATUS, RP0 	;seleciona do bank0 00 to bank1 01
	movlw 	B'11110000'		;bit menos significativo à direita
	movwf 	TRISA			;configura RA0-RA3 como output
							;configura RA4-RA7 como input
	bcf		TRISB, TRISB0	;configura RB0 como input
	bcf		TRISB, TRISB1	;configura RB1 como input
	bsf 	STATUS, RP1		;seleciona do bank1 01 to bank3 11
	clrf 	ANSEL 			;configura PORTA como entrada digital
	clrf	ANSELH			;configura PORTB como entrada digital
	
	;----- TMR0 CONFIGURAÇAO ------
	; INTCON, TMR0, OPTION_REG
	; OPTION_REG : 
	;	T0CS = 0 (INTOSC=4)
	;	PSA = 0 (prescaler TMR0)
	;	PS = 111
	
	bcf		STATUS, RP1		;seleciona do bank3 11 to bank1 01
	movlw	b'00000111'		;seta PS - PS2, PS1 e PS0
	iorwf	OPTION_REG, F	;seta somente os bits de interesse utilizando a funçao logica OU
	movlw	b'11010111'		;limpa TOCS e PSA
	andwf	OPTION_REG, F	;sete somente os bits de interesse utilizando a funçao logica E
	bcf		STATUS, RP0		;seleciona do bank1 01 to bank0 00
	;clrf	TMR0
	movlw	.61
	movwf	TMR0
	bcf		INTCON, T0IF	;limpa a flag de interrupção
	bsf		INTCON, T0IE	;habilita interrupção TMR0
	bsf		INTCON, GIE		;habilita chave geral de interrupção
	call 	RotinaInicializacao
	
	movlw	MOVE_BASE_ADDR
	movwf	FSR
	bcf		STATUS, IRP
	
Main:
	
	btfsc	button			;botao foi precionado
	goto	Main			;não

	movf	TMR0, W
	movwf	move			;copia TMR0 em na variavel move
	clrf	sequency		;sim (zera a variavel sequencia)
	btfsc	PORTB, RB1		;seleciona nivel
	goto	LevelEasy		
	goto	LevelHard

LevelEasy:
	bcf		level, 0
	goto	Main_Loop
LevelHard:
	bsf		level, 0
	goto 	Main_Loop

Main_Loop:
	
	call 	SorteiaNumero
	call	StoreNumber
	goto	Main
	
;------------ Recebe move ------------
SorteiaNumero:
	
	movlw	0x03
	andwf	move	;limpa bit <7:2> (2 ao 7)
	movlw	.0
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_RED
	
	movlw	.1
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_YELLOW
	
	movlw	.2
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_GREEN
	
	movlw	.3
	subwf	move, W
	btfsc	STATUS, Z
	retlw	LED_BLUE
	
StoreNumber:

	movwf	INDF
	incf	FSR
	return

RotinaInicializacao:
	
	bcf	 	STATUS, RP0		;seleciona do bank3 11 to bank1 01
	bcf 	STATUS, RP1		;seleciona do bank1 01 to bank0 00
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
	
	incf	led_cnt, F		;incremente led_cont
	
	movlw	.4
	subwf	led_cnt, W		;subtrai w de led_cont
	btfss	STATUS, Z		;comparação led_cnt = 4?
	goto	LedContLoop		;não
	clrf	PORTA			;sim
	return

Delay_1s:
	
	call Delay_200ms
	call Delay_200ms
	call Delay_200ms
	call Delay_200ms
	call Delay_200ms
	return

Delay_1ms:
	movlw	.249
	movwf	cnt_1
Delay1:
	nop
	decfsz	cnt_1, F	;decrementa cnt_1
	goto	Delay1
	return

Delay_200ms:
	movlw	.200
	movwf	cnt_2
Delay2:
	call	Delay_ms
	decfsz	cnt_2, F
	goto	Delay2
	return
Delay_ms:
	movlw	.248
	movwf	cnt_1
Delay3:
	nop
	decfsz	cnt_1, F	;decrementa cnt_1
	goto	Delay3
	return

Delay_10us:

	nop
	nop
	nop
	nop
	nop
	nop
	return
	
	end