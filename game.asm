; Name:					Quentin Panger/Ryan Caldwell
; Course:               CpSc 370
; Instructor:           Dr. Conlon
; Date started:         February 8, 2015
; Last modification:    April 5, 2015
; Purpose of program:	Basic subroutines for the purpose of designing 
;							a 6502 Program 2-D game. Video output with some
;							utilizing pointers in zero-page for memory mapping
;							as well as a clear screen subroutine with character
;							polling to be edited next.
     
		.CR     6502    ; Assemble 6502 language.
        .LI on,toff     ; Listing on, no timings included.
        .TF game.prg,BIN ; Object file and format

space   	= $20 
home    	= $7000         ;Address of home on video screen
line2		= $7028
line3		= $7050
lastLine	= $73c0
homel   	= $00
homeh   	= $70
scrend  	= $73e7         ;Address of bottom right of video screen
screndl 	= $e7
screndh 	= $73
ballPos		= $71a4
ballPosL	= $a4
ballPosH	= $71
ballDir		= $01
pointer		= $02			;pointer in zero-page
paddle1		= $04
paddle2		= $06
ballPosPtr	= $08
iobase 		= $8800 		;6551 ACIA base address, data register
iostat 		= iobase+1 		;Keyboard status register
iocmd 		= iobase+2 		;Keyboard command register
ioctrl 		= iobase+3 		;Keyboard control register.
keyS		= $73			;Keyboard memory address of A
keyW		= $77
keyI		= $69
keyK		= $6b
enterKey	= $0d


		.OR $0300
start	cld             ;Set binary mode.
	jsr initGame
	jsr getKey
	jsr initScreen		
	jsr showBeginning
	jsr initPointers
gameLoop
	jsr getKey
	jsr moveBall
	jmp gameLoop
	brk
	
initGame
	jsr initScreen
	ldy #17			
	ldx #0
titlePrint
	lda gameTitle,X	
	iny
	cpy #22	
	beq devInfo
	sta home,Y
	inx
	jmp titlePrint
devInfo
	ldy #3
	ldx #0
infoLoop
	lda developers,X
	iny
	cpy #37
	beq gameStart
	sta line2,Y
	inx
	jmp infoLoop
gameStart
	ldy #10
	ldx #0
enterLoop
	lda enterGame,X
	iny
	cpy #30
	beq initPointers
	sta line3,Y
	inx
	jmp enterLoop

initScreen			
	lda #homel
	sta pointer		
	lda #homeh
	sta pointer+1	
	ldy #$ff
	lda #space	
lowClr				
	ldx pointer+1
	cpx #$74
	beq done
	sta (pointer),Y		
	dey
	beq highInc
	jmp lowClr
highInc
	sta (pointer),Y
	inc pointer+1
	ldy #$ff
	ldx pointer+1
	cpx #$73
	beq endScreen
	jmp lowClr
done
	rts
endScreen
	ldy #$e8
	jmp lowClr
	
showBeginning
	ldx #0
	lda begin,X	
	sta line2
	sta scrend-40
	lda pongBall,X
	sta ballPos
	ldy #1
screenBounds
	ldx #0
	lda scrnBound,X
	sta home,Y
	sta lastLine,Y
	iny
	cpy #39
	beq initialized
	jmp screenBounds
initialized
	rts
	
initPointers	
	cli
	lda #$0b
	sta iocmd	
	lda #$1a
	sta ioctrl
	lda #homel
	sta paddle1	
	lda #homeh
	sta paddle1+1
	lda #screndl
	sta paddle2
	lda #screndh
	sta paddle2+1
	lda #ballPosL
	sta ballPosPtr
	lda #ballPosH
	sta ballPosPtr+1
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getKey
	lda iostat
	and #$08
	beq getKey
	sta iobase
	lda iobase
	cmp #enterKey
	beq gameInit
	cmp #keyS
	beq moveDown1
	cmp #keyW
	beq moveUp1
	cmp #keyK
	beq moveDown2
	cmp #keyI
	beq moveUp2
	rts
noKey
	rts
gameInit
	rts
moveDown1
	lda paddle1
	cmp #$98
	beq stallPaddle
	ldy #0
	lda #space
	sta (paddle1),Y
	clc
	lda #40
	adc paddle1
	sta paddle1
	lda #0
	adc paddle1+1
	sta paddle1+1
	lda begin,X
	sta (paddle1),Y
;	jmp getKey
	rts
moveUp1
	lda paddle1
	cmp #$28
	beq stallPaddle
	ldy #0
	lda #space
	sta (paddle1),Y
	sec
	lda paddle1
	sbc #40
	sta paddle1
	lda paddle1+1
	sbc #0
	sta paddle1+1
	lda begin,X
	sta (paddle1),Y
	rts
moveDown2
	lda paddle2
	cmp #$bf
	beq stallPaddle
	ldy #0
	lda #space
	sta (paddle2),Y
	clc
	lda #40
	adc paddle2
	sta paddle2
	lda #0
	adc paddle2+1
	sta paddle2+1
	lda begin,X
	sta (paddle2),Y
	rts
moveUp2	
	lda paddle2
	cmp #$4f
	beq stallPaddle
	ldy #0
	lda #space
	sta (paddle2),Y
	sec
	lda paddle2
	sbc #40
	sta paddle2
	lda paddle2+1
	sbc #0
	sta paddle2+1
	lda begin,X
	sta (paddle2),Y
	rts
stallPaddle
	jmp getKey
	
moveBall
	lda ballDir
	cmp #$01
	beq moveRight
	cmp homel
	beq moveLeft
moveRight
	lda #$01
	sta ballDir
	lda #space
	sta (ballPosPtr),Y
	clc
	lda #1
	adc ballPosPtr
	sta ballPosPtr
	lda #0
	adc ballPosPtr+1
	sta ballPosPtr+1
	lda ballPosPtr
	cmp paddle2
	beq moveLeft
	lda pongBall,X
	sta (ballPosPtr),Y
	rts
moveLeft
	lda #$00
	sta ballDir
	lda ballPosPtr
	cmp paddle1
	beq moveRight
	lda #space
	sta (ballPosPtr),Y
	sec
	lda ballPosPtr
	sbc #1
	sta ballPosPtr
	lda ballPosPtr+1
	sbc #0
	sta ballPosPtr+1
	lda pongBall,X
	sta (ballPosPtr),Y
	rts
	
gameTitle	.AS 'PONG'
developers	.AS 'BY QUENTIN PANGER & RYAN CALDWELL'
enterGame	.AS 'PRESS ENTER TO PLAY'
begin		.AS '+'
scrnBound	.AS '-'
pongBall	.AS '.'