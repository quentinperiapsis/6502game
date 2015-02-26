; Name:					Quentin Panger/Ryan Caldwell
; Course:               CpSc 370
; Instructor:           Dr. Conlon
; Date started:         February 8, 2015
; Last modification:    February 24, 2015
; Purpose of program:	Basic subroutines for the purpose of designing 
;							a 6502 Program 2-D game
     
		.CR     6502    ; Assemble 6502 language.
        .LI on,toff     ; Listing on, no timings included.
        .TF game.prg,BIN ; Object file and format

space   	= $20 
box     	= 230
home    	= $7000         ;Address of home on video screen
homel   	= $00
homeh   	= $70
scrend  	= $73e8         ;Address of bottom right of video screen
screndl 	= $e8
screndh 	= $73
rowsize 	= 40            ;Screen is 25 rows by 40 columns.
rowcnt  	= 25
secondQtr 	= home+256
thirdQtr	= home+512
fourthQtr	= home+768

		.OR $0300
start	cld             ;Set binary mode.
	jsr initScreen
	brk
initScreen
	ldy #$ff
	lda #space
clear1
	sta home,Y
	dey
	bne clear1
	sta home,Y
	ldy #$ff
	jmp clear2
clear2
	sta secondQtr,Y
	dey
	bne clear2
	sta secondQtr,Y
	ldy #$ff
	jmp clear3
clear3
	sta thirdQtr,Y
	dey
	bne clear3
	sta thirdQtr,Y
	ldy #$ff
	jmp clear4
clear4
	sta fourthQtr,Y
	dey
	bne clear4
	sta fourthQtr,Y
	rts
	