; Name:                 Quentin Panger/Ryan Caldwell
; Course:               CpSc 370
; Instructor:           Dr. Conlon
; Date started:         February 8, 2015
; Last modification:    April 8, 2015
; Purpose of program:   Pong game written in 6502 Assembly language for
;                          Dr. Conlon's CpSc-370 Computer Organization and
;                          Architecture class.

				.CR     6502     ; Assemble 6502 language.
				.LI on,toff     ; Listing on, no timings included.
				.TF game1.prg,BIN ; Object file and format

space   	= $20           ;value of a space; used to clear the screen
home    	= $7000         ;Address of home on video screen
line2   	= $7028         ;Line 2 of video output
line3      	= $7050         ;Line 3 of video output
lastLine   	= $73c0         ;Last line used for screen boundary
homel   	= $00
homeh   	= $70
scrend  	= $73e7         ;Address of bottom right of video screen
screndl 	= $e7
screndh 	= $73
ballPos 	= $7244         ;Original position of pong ball
ballPosL   	= $44           ;Low byte of the original ball position
ballPosH   	= $72           ;High byte of the original ball position
pointer    	= $02           ;Pointer in zero-page
paddle1 	= $04           ;Pointer in zero-page
paddle2 	= $06           ;Pointer in zero-page
ballPosPtr 	= $08           ;Pointer in zero-page
iobase    	= $8800         ;6551 ACIA base address, data register
iostat      = iobase+1      ;Keyboard status register
iocmd       = iobase+2      ;Keyboard command register
ioctrl      = iobase+3      ;Keyboard control register.
keyS        = $73           ;Keyboard address of S (moves player 1 paddle down)
keyW        = $77           ;Keyboard address of W (moves player 1 paddle up)
keyI        = $69           ;Keyboard address of I (moves player 2 paddle up)
keyK        = $6b           ;Keyboard address of K (moves player 2 paddle down)
enterKey    = $0d           ;Keyboard address of enter (start game command)

                 .OR $0300
;Main of this program, does all the main function calls.
start   cld             ;Set binary mode.
    jsr initGame
    jsr getKey
startNewPlay                ;Starts a new round of play for the game
    jsr initPointers        ;Stores necessary information in zero-page
    jsr initScreen
    jsr showBeginning
gameLoop
    jsr getKey              ;Poll for a key
    jsr delayLoop           ;Used so the ball doesn't move too quickly
    jsr moveBall			;memory mapped i/o
    jmp gameLoop            ;Game loop is repeated until completion
    brk

;Displays the title and developer information.
initGame
    jsr initScreen          ;This clears the screen
    ldy #17                 ;Centers the text
    ldx #0
titlePrint                  ;"Pong" is displayed
    lda gameTitle,X
    iny
    cpy #22                 ;End of string
    beq devInfo
    sta home,Y
    inx
    jmp titlePrint
devInfo                    ;Prints our names to the screen
    ldy #3
    ldx #0
infoLoop
    lda developers,X
    iny
	cpy #37                ;End of string
    beq gameStart          ;Instructions to begin game
    sta line2,Y
    inx
    jmp infoLoop
gameStart
    ldy #7                 ;Centering the string
    ldx #0
enterLoop
    lda enterGame,X
    iny
    cpy #33                ;End of string
    beq initPointers
    sta line3,Y
    inx
    jmp enterLoop

;Initialize the screen to be cleared completely
initScreen
    lda #homel        ;Initializing pointers in zero-page
    sta pointer
    lda #homeh
    sta pointer+1
    ldy #$ff          ;Covers all of the low bytes
    lda #space
lowClr                ;Loads spaces into all of the low bytes of the screen
    ldx pointer+1
    cpx #$74
    beq done
    sta (pointer),Y
    dey
    beq highInc
    jmp lowClr
highInc              ;Increments the high byte
    sta (pointer),Y
    inc pointer+1
    ldy #$ff
    ldx pointer+1
    cpx #$73
    beq endScreen
    jmp lowClr
done
    rts
endScreen            ;Stops from clearing past the video screen
    ldy #$e8         ;Low byte of end of video screen
    jmp lowClr

;Begin displaying paddles, ball, and screen bounds
showBeginning
    ldx #0
    lda leftPaddle,X
	sta $7208            ;Center left
    lda rightPaddle,X
    sta $722F            ;Center right
    lda pongBall,X
    sta ballPos          ;Pong ball in between two paddles
    ldy #1
screenBounds             ;Prints '/' and '\' to show screen boundaries
    ldx #0
    lda uprScrnBnd,X
    sta home,Y
    lda lowScrnBnd,X
    sta lastLine,Y
    iny
    cpy #39              ;Length of the line, loop terminates when 39
    beq initialized
    jmp screenBounds
initialized              ;All beginning displays complete
    rts

;Stores necessary information in zero-page
initPointers
    cli                  ;Next four lines were taken from Dr. Conlon in class
    lda #$0b
    sta iocmd
    lda #$1a
    sta ioctrl
    lda #$08
    sta paddle1          ;Stores location of paddle1
    lda #$72
    sta paddle1+1
    lda #$2f
    sta paddle2          ;Stores location of paddle2
    lda #$72
    sta paddle2+1
	lda #ballPosL
    sta ballPosPtr       ;Stores location of ball position
    lda #ballPosH
    sta ballPosPtr+1
startGame
    lda iostat
    and #$08             ;Given by Dr. Conlon in class
    beq startGame
    sta iobase
    lda iobase
    cmp #enterKey
    beq gameInit         ;When enter key is pressed, game initialization begins
    jmp startGame
gameInit
    rts

;Polling used to read in from the keyboard - move paddles accordingly
getKey
    lda iostat
    and #$08
    beq counter		;if status is empty
    sta iobase	
    lda iobase		;if full, compare to a key
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
moveDown1              ;Used to move Player 1's paddle down
    lda paddle1
    cmp #$98
    beq stallPaddle    ;Limits paddle 1 from going below video screen
    ldy #0
    lda #space         ;Replaces previous position with space
    sta (paddle1),Y
    clc
    lda #40            ;Next line down
    adc paddle1        ;Will move the paddle1 to the next line down
    sta paddle1
    lda #0
    adc paddle1+1
    sta paddle1+1
    lda leftPaddle,X   ;Shows paddle in new position
	sta (paddle1),Y
    rts
moveUp1                ;Used to move Player 1's paddle up
    lda paddle1
    cmp #$28
    beq stallPaddle    ;Limits paddle 1 from going above video screen
	ldy #0
    lda #space         ;Replaces previous position with space
    sta (paddle1),Y
    sec
    lda paddle1
    sbc #40            ;Next line up
    sta paddle1
    lda paddle1+1
    sbc #0
    sta paddle1+1
    lda leftPaddle,X   ;Shows paddle in new position
    sta (paddle1),Y
    rts
moveDown2              ;Used to move Player 2's paddle down
    lda paddle2
    cmp #$bf
    beq stallPaddle    ;Limits paddle 2 from going below video screen
    ldy #0
    lda #space         ;Replaces previous position with space
    sta (paddle2),Y
    clc
    lda #40
    adc paddle2        ;Moves paddle2 to next line down
	sta paddle2
    lda #0
    adc paddle2+1
    sta paddle2+1
    lda rightPaddle,X  ;Shows paddle in new position
    sta (paddle2),Y
	rts
moveUp2                ;Used to move Player 2's paddle up
    lda paddle2
    cmp #$4f
    beq stallPaddle    ;Limits paddle 2 from going above video screen
    ldy #0
    lda #space         ;Replaces previous position with space
    sta (paddle2),Y
    sec
    lda paddle2
    sbc #40            ;Moves paddle to next line up
    sta paddle2
    lda paddle2+1
    sbc #0
    sta paddle2+1
    lda rightPaddle,X  ;Shows paddle in new position
    sta (paddle2),Y
    rts
stallPaddle            ;No printing occurs, just polls for next character
    jmp getKey

;Moves the ball along the screen
moveBall
    jsr isPoint             ;Checks to see if point was scored
    lda ballDir             ;Ball can have 3 different direction states
    cmp #$00                ;State 1 - move ball left down
    beq moveLeftDown
    cmp #$01                ;State 2 - move ball right down
    beq moveRD
    cmp #$02                ;State 3 - move ball right up
    beq moveRU
moveLD                      ;These functions prevent calls being out of range
    jsr moveLeftDown
    rts
moveRD
    jsr moveRightDown
    rts
moveRU
    jsr moveRightUp
    rts

;Moves the ball in the down-right direction
moveRightDown
    lda #$01
    sta ballDir             ;Changes the state of the ball
    lda ballPosPtr
    cmp paddle1             ;Checks for contact with left paddle
    beq reDraw1             ;Redraws the paddle after ball contact
    cmp paddle2             ;Checks for contact with right paddle
    beq moveLeftCheck
    ldy #0
	lda (ballPosPtr),Y
    cmp #$2f                ;Compares to the upper screen bound
    beq drawContactTop1     ;Redraws the upper bound after contact with ball
    lda #space
    sta (ballPosPtr),Y      ;Clears ball's current position
continueMove1               ;Updates ball position and draws new position
    clc
    lda #41                 ;Moves diagonally down 1 from previous position
    adc ballPosPtr
    sta ballPosPtr          ;Updates ball position (low byte)
    lda #0
    adc ballPosPtr+1
    sta ballPosPtr+1        ;Updates ball position (high byte)
    jsr isBounce            ;Checks to see if ball hit a boundary
    lda pongBall,X
    sta (ballPosPtr),Y      ;Redraws the ball
    rts
moveLeftCheck               ;Compares the high byte - moves ball left
    lda ballPosPtr+1
    cmp paddle2+1
    beq cnfrmLeft
    rts
cnfrmLeft                   ;Addresses match - move left down
    jsr moveLeftDown
    rts
reDraw1                     ;Checks high byte to redraw
    lda ballPosPtr+1
    cmp paddle1+1
    beq cnfrmReDraw1
    rts
cnfrmReDraw1                ;Redraws the left paddle
    lda leftPaddle,X
    sta (ballPosPtr),Y
    jmp continueMove1
drawContactTop1             ;Redraws the upper bound after contact
    lda uprScrnBnd,X
    sta (ballPosPtr),Y
    jmp continueMove1
	
;Moves the ball in the left direction
moveLeftDown
    lda #$00
    sta ballDir             ;Makes ball state 1
    lda ballPosPtr
    cmp paddle2             ;Checks for contact with right paddle
    beq reDraw2             ;Redraws the paddle after ball contact
    cmp paddle1             ;Checks for contact with right paddle
    beq moveRightCheck      ;Possible collision with paddle 1
    lda #space
    sta (ballPosPtr),Y      ;Clears ball's current position
continueMove2               ;Updates ball position and draws new position
    sec
    lda ballPosPtr
    sbc #1                  ;Moves one position to the left on video screen
    sta ballPosPtr
    lda ballPosPtr+1
    sbc #0
    sta ballPosPtr+1
    lda pongBall,X
    sta (ballPosPtr),Y      ;Redraws the ball
    rts
moveRightCheck              ;Compares the high byte - moves ball right
    lda ballPosPtr+1
    cmp paddle1+1
    beq cnfrmRight
    rts
cnfrmRight                  ;Addresses match - move right down
    jsr moveRightDown
    rts
reDraw2                     ;Checks high byte to redraw
    lda ballPosPtr+1
    cmp paddle2+1
    beq cnfrmReDraw2
    rts
cnfrmReDraw2                ;Redraws the right paddle
    lda rightPaddle,X
    sta (ballPosPtr),Y
    jmp continueMove2
	
;Moves ball to the up right direction
moveRightUp
    lda #$02
    sta ballDir         ;Changes the state of the ball
    lda ballPosPtr
    cmp paddle1         ;Checks for contact with left paddle
    beq reDraw3         ;Redraws the paddle after ball contact
    cmp paddle2         ;Checks for contact with right paddle
    beq moveLeftCheck2
    ldy #0
    lda (ballPosPtr),Y
    cmp #$5c            ;Checks for contact with lower bound
    beq drawContactBtm1 ;Redraws lower bound after contact with ball
    lda #space
    sta (ballPosPtr),Y  ;Clears ball's current position
continueMove3           ;Updates ball position and draw new position
    sec
    lda ballPosPtr
    sbc #39             ;Moves ball diagonally up (right) from current position
    sta ballPosPtr
    lda ballPosPtr+1
    sbc #0
    sta ballPosPtr+1
    jsr isBounce
    lda pongBall,X
    sta (ballPosPtr),Y  ;Redraws the ball
    rts
moveLeftCheck2          ;Compares the high byte - moves ball left
    lda ballPosPtr+1
    cmp paddle2+1
    beq cnfrmLeft2
	rts
cnfrmLeft2
    jsr moveLeftDown    ;Addresses match - move left
	rts
reDraw3                 ;Check high byte to redraw
    lda ballPosPtr+1
	cmp paddle1+1
    beq cnfrmReDraw3
    rts
cnfrmReDraw3            ;Redraws the left paddle
    lda leftPaddle,X
    sta (ballPosPtr),Y
    jmp continueMove3
drawContactBtm1         ;Redraws the lower screen bound on contact
    lda lowScrnBnd,X
    sta (ballPosPtr),Y
    jmp continueMove3
	
;Runs a delay subroutine three times for appropriate ball speed
delayLoop
	jsr delayInit
    jsr delayInit
    jsr delayInit
	jsr delayInit
    rts

;Basic idea to use this loop was taken from 6502 delay loops using Applesoft
;Used to slow down the speed of the ball by doing lots of computations
;Decrement y from 100,000 to zero, then do the same with x.
delayInit
    ldy #100000       ;Variable to be counted down to zero
    ldx #100000       ;Second variable to be counted down to zero
delay
    dex
    nop               ;No-op is used to take up some CPU clock cycles
    bne delay
    dey
    nop
    bne delay
	jmp delayOver     ;All computations have been completed
delayOver
    rts

;Determines if the ball hit a lower or upper screen bound
;This will determine the next direction of the ball
isBounce
    ldy #0
    lda (ballPosPtr),Y    ;Dereferences for '/' or '\' check
    cmp #$5c              ;Lower screen bound
    beq bounceUp
    cmp #$2f              ;Upper screen bound
    beq bounceDown
    rts
bounceUp
    jsr moveRightUp
    rts
bounceDown
    lda ballDir
    cmp #$02              ;Checks ball's previous state to go new direction
    beq bounceDownRight
bounceDownRight
    jsr moveRightDown
	rts

;The rest of this program simply determines if a point was scored by either
;player. This is essentially all hard coded. Future updates can put this
;code into loop formats to reduce number of lines of code. However,
;this method does work correctly.
isPoint
    lda ballDir           ;Checks the state of ball to determine whose point
    cmp #$00              ;State 1 - traveling left, so player 2's point
    beq isPointPlyr2
    cmp #$01              ;State 2 - traveling right down, player 1's point
    beq isPointPlyr1
    cmp #$02              ;State 3 - traveling right up, player 1's point
    beq isPointPlyr1
    rts
isPointPlyr2              ;Loads high byte to determine what quarter of screen
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
p2Q1                      ;These are added to eliminate out of range errors
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
isPointPlyr1              ;Loads high byte to determine what quarter of screen
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
pQ1                       ;These are added to eliminate out of range errors
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
point2InQtr1              ;Checks for point in first left quarter of goal
    lda paddle1
    cmp ballPosPtr
    beq nP                ;Collision with paddle, no point
    lda ballPosPtr
    cmp #$00              ;All following comparisons are low byte checks
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
point2InQtr2             ;Checks for point in second left quarter of goal
    lda paddle1
    cmp ballPosPtr
    beq noPoint          ;Collision with paddle, no point
    lda ballPosPtr
    cmp #$18             ;All following comparisons are low byte checks
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
point2InQtr3           ;Checks for point in third left quarter of goal
    lda paddle1
    cmp ballPosPtr
    beq noPoint        ;Collision with paddle, no point
    lda ballPosPtr
    cmp #$08           ;All following comparisons are low byte checks
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
point2InQtr4            ;Checks for point in fourth left quarter of goal
    lda paddle1
    cmp ballPosPtr
    beq noPoint         ;Collision with paddle, no point
    lda ballPosPtr
    cmp #$20            ;All following comparisons are low byte checks
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
noPoint                 ;Returns, no point scored
    rts
pointPlr2               ;Point was scored by player 2, start new game
    jmp startNewPlay
pointInQtr1             ;Checks for point in first right quarter of goal
    lda paddle2
    cmp ballPosPtr
    beq nP2             ;Collision with paddle, no point
    lda ballPosPtr
    cmp #$27            ;All following comparisons are low byte checks
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
pP1                    ;Returns, no point scored
    jsr pointPlr1
    rts
pointInQtr2            ;Checks for point in second right quarter of goal
    lda paddle2
    cmp ballPosPtr
    beq nP2            ;Returns, no point scored
    lda ballPosPtr
	cmp #$17           ;All following comparisons are low byte checks
    beq pP1
	lda ballPosPtr
    cmp #$3f
    beq pP1
    lda ballPosPtr
    cmp #$67
    beq pP1
    lda ballPosPtr
    cmp #$8f
    beq pP1
    lda ballPosPtr
    cmp #$b7
    beq pP1
    lda ballPosPtr
    cmp #$df
    beq pP1
    rts
nP2                   ;No point scored
    jsr noPoint2
	rts
pointInQtr3           ;Checks for point in third right quarter of goal
    lda paddle2
    cmp ballPosPtr
    beq noPoint2      ;Returns, no point scored
    lda ballPosPtr
    cmp #$07          ;All following comparisons are low byte checks
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
pointInQtr4         ;Checks for point in fourth right quarter of goal
	lda paddle2
	cmp ballPosPtr
	beq noPoint2    ;Returns, no point scored
	lda ballPosPtr
	cmp #$1f        ;All following comparisons are low byte checks
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
noPoint2            ;Returns, no point scored
	rts
pointPlr1           ;Point scored, start new game
	jmp startNewPlay

ballDir         .DW $00     ;Variable for ball direction, starts going left
gameTitle       .AS 'PONG'
developers      .AS 'BY QUENTIN PANGER & RYAN CALDWELL'
enterGame       .AS 'PRESS ENTER TWICE TO PLAY'
leftPaddle      .AS 'Q'
rightPaddle     .AS 'R'
uprScrnBnd      .AS '/'
lowScrnBnd      .AS '\'
pongBall        .AS '.'