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
ballPos		= $7244
ballPosL	= $44
ballPosH	= $72
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
startNewPlay
	jsr initPointers
	jsr initScreen		
	jsr showBeginning
gameLoop
	jsr getKey
	jsr delayLoop
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
	lda leftPaddle,X	
	sta line2
	lda rightPaddle,X
	sta scrend-40
	lda pongBall,X
	sta ballPos
	ldy #1
screenBounds
	ldx #0
	lda uprScrnBnd,X
	sta home,Y
	lda lowScrnBnd,X
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
startGame
	lda iostat
	and #$08
	beq startGame
	sta iobase
	lda iobase
	cmp #enterKey
	beq gameInit
	jmp startGame
gameInit
	rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getKey
	lda iostat
	and #$08
	beq counter
	sta iobase
	lda iobase
	cmp #keyS
	beq moveDown1
	cmp #keyW
	beq moveUp1
	cmp #keyK
	beq moveDown2
	cmp #keyI
	beq moveUp2
	rts
counter
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
	lda leftPaddle,X
	sta (paddle1),Y
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
	lda leftPaddle,X
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
	lda rightPaddle,X
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
	lda rightPaddle,X
	sta (paddle2),Y
	rts
stallPaddle
	jmp getKey
	
moveBall
	jsr isPoint
	lda ballDir
	cmp #$00
	beq moveLeftDown
	cmp #$01
	beq moveRD
	cmp #$02
	beq moveRU
;moveLD
;	jsr moveLeftDown
;	rts
moveRD
	jsr moveRightDown
	rts
moveRU
	jsr moveRightUp
	rts
	
moveRightDown
	lda #$01
	sta ballDir
	lda ballPosPtr
	cmp paddle1
	beq reDraw1
	cmp paddle2
	beq moveLeftCheck
	ldy #0
	lda (ballPosPtr),Y
	cmp #$2f
	beq drawContactTop1
	lda #space
	sta (ballPosPtr),Y
continueMove1
	clc
	lda #41
	adc ballPosPtr
	sta ballPosPtr
	lda #0
	adc ballPosPtr+1
	sta ballPosPtr+1
	jsr isBounce
	lda pongBall,X
	sta (ballPosPtr),Y
	rts
moveLeftCheck
	lda ballPosPtr+1
	cmp paddle2+1
	beq cnfrmLeft
	rts
cnfrmLeft
	jsr moveLeftDown
	rts
reDraw1
	lda ballPosPtr+1
	cmp paddle1+1
	beq cnfrmReDraw1
	rts
cnfrmReDraw1
	lda leftPaddle,X
	sta (ballPosPtr),Y
	jmp continueMove1
drawContactTop1
	lda uprScrnBnd,X
	sta (ballPosPtr),Y
	jmp continueMove1
	
moveLeftDown
	lda #$00
	sta ballDir
	lda ballPosPtr
	cmp paddle2
	beq reDraw2
	cmp paddle1
	beq moveRightCheck
	lda #space
	sta (ballPosPtr),Y
continueMove2
	sec
	lda ballPosPtr
	sbc #1
	sta ballPosPtr
	lda ballPosPtr+1
	sbc #0
	sta ballPosPtr+1
;	jsr isBounce
	lda pongBall,X
	sta (ballPosPtr),Y
	rts
moveRightCheck
	lda ballPosPtr+1
	cmp paddle1+1
	beq cnfrmRight
	rts
cnfrmRight
	jsr moveRightDown
	rts
reDraw2
	lda ballPosPtr+1
	cmp paddle2+1
	beq cnfrmReDraw2
	rts
cnfrmReDraw2
	lda rightPaddle,X
	sta (ballPosPtr),Y
	jmp continueMove2
	

moveRightUp
	lda #$02
	sta ballDir
	lda ballPosPtr
	cmp paddle1
	beq reDraw3
	cmp paddle2
	beq moveLeftCheck2
	ldy #0
	lda (ballPosPtr),Y
	cmp #$5c
	beq drawContactBtm1
	lda #space
	sta (ballPosPtr),Y
continueMove3
	sec
	lda ballPosPtr
	sbc #39
	sta ballPosPtr
	lda ballPosPtr+1
	sbc #0
	sta ballPosPtr+1
	jsr isBounce
	lda pongBall,X
	sta (ballPosPtr),Y
	rts
moveLeftCheck2
	lda ballPosPtr+1
	cmp paddle2+1
	beq cnfrmLeft2
	rts
cnfrmLeft2
	jsr moveLeftDown
	rts
reDraw3
	lda ballPosPtr+1
	cmp paddle1+1
	beq cnfrmReDraw3
	rts
cnfrmReDraw3
	lda leftPaddle,X
	sta (ballPosPtr),Y
	jmp continueMove3
drawContactBtm1
	lda lowScrnBnd,X
	sta (ballPosPtr),Y
	jmp continueMove3
	
	
delayLoop
	jsr delayInit
	jsr delayInit
	jsr delayInit
	rts
	
delayInit
	ldy #100000
	ldx #100000
delay
	dex
	nop
	bne delay
	dey
	nop
	bne delay
	jmp delayOver
delayOver
	rts
	
isPoint
	lda ballDir
	cmp #homel
	beq isPointPlyr2
	cmp #$01
	beq isPointPlyr1
	rts
isPointPlyr2
	lda ballPosPtr
	cmp #$90
	beq isContact1
	rts
isContact1
	lda paddle1
	cmp ballPosPtr
	beq noPoint1
	bne isPoint2
isPoint2
	jmp startNewPlay
noPoint1
	rts	
isPointPlyr1
	lda ballPosPtr
	cmp #$b7
	beq isContact2
	rts
isContact2
	lda paddle2
	cmp ballPosPtr
	beq noPoint2
	bne isPoint1
isPoint1
	jmp startNewPlay
noPoint2
	rts	

isBounce
	ldy #0
	lda (ballPosPtr),Y
	cmp #$5c
	beq bounceUp
	cmp #$2f
	beq bounceDown
	rts
bounceUp
	jsr moveRightUp
	rts
bounceDown
	lda ballDir
	cmp #$02
	beq bounceDownRight
bounceDownRight
	jsr moveRightDown
	rts

ballDir		.DW $00
gameTitle	.AS 'PONG'
developers	.AS 'BY QUENTIN PANGER & RYAN CALDWELL'
enterGame	.AS 'PRESS ENTER TO PLAY'
leftPaddle	.AS 'Q'
rightPaddle	.AS 'R'
uprScrnBnd	.AS '/'
lowScrnBnd	.AS '\'
pongBall	.AS '.'