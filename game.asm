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
	sta $7208
	lda rightPaddle,X
	sta $722F
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
	lda #$08
	sta paddle1	
	lda #$72
	sta paddle1+1
	lda #$2f
	sta paddle2
	lda #$72
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
moveLD
	jsr moveLeftDown
	rts
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isPoint
	lda ballDir
	cmp #$00
	beq isPointPlyr2
	cmp #$01
	beq isPointPlyr1
	cmp #$02
	beq isPointPlyr1
	rts
isPointPlyr2
	lda ballPosPtr+1
	cmp #$70
	beq p2Q1
	cmp #$71
	beq p2Q2
	cmp #$72
	beq p2Q3
	cmp #$73
	beq p2Q4
	rts
p2Q1
	jsr point2InQtr1
	rts
p2Q2
	jsr point2InQtr2
	rts
p2Q3
	jsr point2InQtr3
	rts
p2Q4
	jsr point2InQtr4
	rts
isPointPlyr1
	lda ballPosPtr+1
	cmp #$70
	beq pQ1
	cmp #$71
	beq pQ2
	cmp #$72
	beq pQ3
	cmp #$73
	beq pQ4
	rts
pQ1
	jsr pointInQtr1
	rts
pQ2
	jsr pointInQtr2
	rts
pQ3
	jsr pointInQtr3
	rts
pQ4
	jsr pointInQtr4
	rts
point2InQtr1
	lda paddle1
	cmp ballPosPtr
	beq nP
	lda ballPosPtr
	cmp #$00
	beq point2Qtr1
	lda ballPosPtr
	cmp #$28
	beq point2Qtr1
	lda ballPosPtr
	cmp #$50
	beq point2Qtr1
	lda ballPosPtr
	cmp #$78
	beq point2Qtr1
	lda ballPosPtr
	cmp #$a0
	beq point2Qtr1
	lda ballPosPtr
	cmp #$c8
	beq point2Qtr1
	lda ballPosPtr
	cmp #$f0
	beq point2Qtr1
	rts
nP
	jsr noPoint
	rts
point2Qtr1
	jsr pointPlr2
	rts
point2InQtr2
	lda paddle1
	cmp ballPosPtr
	beq noPoint
	lda ballPosPtr
	cmp #$18
	beq pointPlr2
	lda ballPosPtr
	cmp #$40
	beq pointPlr2
	lda ballPosPtr
	cmp #$68
	beq pointPlr2
	lda ballPosPtr
	cmp #$90
	beq pointPlr2
	lda ballPosPtr
	cmp #$b8
	beq pointPlr2
	lda ballPosPtr
	cmp #$e0
	beq pointPlr2
	rts
point2InQtr3
	lda paddle1
	cmp ballPosPtr
	beq noPoint
	lda ballPosPtr
	cmp #$08
	beq pointPlr2
	lda ballPosPtr
	cmp #$30
	beq pointPlr2
	lda ballPosPtr
	cmp #$58
	beq pointPlr2
	lda ballPosPtr
	cmp #$80
	beq pointPlr2
	lda ballPosPtr
	cmp #$a8
	beq pointPlr2
	lda ballPosPtr
	cmp #$d0
	beq pointPlr2
	lda ballPosPtr
	cmp #$f8
	beq pointPlr2
	rts
point2InQtr4
	lda paddle1
	cmp ballPosPtr
	beq noPoint
	lda ballPosPtr
	cmp #$20
	beq pointPlr2
	lda ballPosPtr
	cmp #$48
	beq pointPlr2
	lda ballPosPtr
	cmp #$70
	beq pointPlr2
	lda ballPosPtr
	cmp #$98
	beq pointPlr2
	lda ballPosPtr
	cmp #$c0
	beq pointPlr2
	rts
noPoint
	rts
pointPlr2
	jmp startNewPlay
pointInQtr1
	lda paddle2
	cmp ballPosPtr
	beq nP2
	lda ballPosPtr
	cmp #$27
	beq pP1
	lda ballPosPtr
	cmp #$4f
	beq pP1
	lda ballPosPtr
	cmp #$77
	beq pP1
	lda ballPosPtr
	cmp #$9f
	beq pP1
	lda ballPosPtr
	cmp #$c7
	beq pP1
	lda ballPosPtr
	cmp #$ef
	beq pP1
	rts
pP1
	jsr pointPlr1
	rts
pointInQtr2
	lda paddle2
	cmp ballPosPtr
	beq nP2
	lda ballPosPtr
	cmp #$17
	beq pointPlr1
	lda ballPosPtr
	cmp #$3f
	beq pointPlr1
	lda ballPosPtr
	cmp #$67
	beq pointPlr1
	lda ballPosPtr
	cmp #$8f
	beq pointPlr1
	lda ballPosPtr
	cmp #$b7
	beq pointPlr1
	lda ballPosPtr
	cmp #$df
	beq pointPlr1
	rts
nP2
	jsr noPoint2
pointInQtr3
	lda paddle2
	cmp ballPosPtr
	beq noPoint2
	lda ballPosPtr
	cmp #$07
	beq pointPlr1
	lda ballPosPtr
	cmp #$2f
	beq pointPlr1
	lda ballPosPtr
	cmp #$57
	beq pointPlr1
	lda ballPosPtr
	cmp #$7f
	beq pointPlr1
	lda ballPosPtr
	cmp #$a7
	beq pointPlr1
	lda ballPosPtr
	cmp #$cf
	beq pointPlr1
	lda ballPosPtr
	cmp #$f7
	beq pointPlr1
	rts
pointInQtr4
	lda paddle2
	cmp ballPosPtr
	beq noPoint2
	lda ballPosPtr
	cmp #$1f
	beq pointPlr1
	lda ballPosPtr
	cmp #$47
	beq pointPlr1
	lda ballPosPtr
	cmp #$6f
	beq pointPlr1
	lda ballPosPtr
	cmp #$97
	beq pointPlr1
	lda ballPosPtr
	cmp #$bf
	beq pointPlr1
	lda ballPosPtr
	cmp #$e7
	beq pointPlr1
	rts
noPoint2
	rts
pointPlr1
	jmp startNewPlay


ballDir		.DW $00
gameTitle	.AS 'PONG'
developers	.AS 'BY QUENTIN PANGER & RYAN CALDWELL'
enterGame	.AS 'PRESS ENTER TO PLAY'
leftPaddle	.AS 'Q'
rightPaddle	.AS 'R'
uprScrnBnd	.AS '/'
lowScrnBnd	.AS '\'
pongBall	.AS '.'