BasicUpstart2(start)

#import "pseudo.lib"

.var TOP100 = "D:/c64/C64Music/HVSC_Top_100/Top100"
.var sidpath = TOP100 + "/Eliminator.sid"
.var music = LoadSid(sidpath)

.var irq_line = $f0

.var irq_line_init = $eb
.var irq_line_main = $ff

.var debug = true

.var zp_start = $80
.var zp_fade_time = zp_start + $0
.var zp_fade_text = zp_start + $1
.var zp_fade_idx = zp_start + $2
.var zp_fade_row_idx = zp_start + $3
.var zp_fade_row_top = zp_start + $4 // word
.var zp_fade_row_bot = zp_start + $6 // word
.var zp_fade_row_top_col = zp_start + $8 // word
.var zp_fade_row_bot_col = zp_start + $a // word
.var zp_fade_mode = zp_start + $c
.var zp_fade_row_step = zp_start + $d
.var zp_end = zp_fade_row_step + 1
.var zp_size = zp_end - zp_start

.const screen = $0400
.const screen_end = screen + 25 * 40

.const time_delay = $4
.const time_delay_init = $40

.pc=* "code 1"
start:
	jsr zp_init

	// setup irq
	sei

	// all ram pls
	lda #$35
	sta $1

	lda #<irq1
	sta $fffe
	lda #>irq1
	sta $ffff

	// dummy irqs
	lda #<irq_dummy
	sta $fffa
	sta $fffc
	lda #>irq_dummy
	sta $fffb
	sta $fffd

	lda #%00011011		// Load screen control:
				// Vertical scroll    : 3
				// Screen height      : 25 rows
				// Screen             : ON
				// Mode               : TEXT
				// Extended background: OFF
	sta $d011       	// Set screen control

	set_irq #irq_line : #irq1

	lda #$01		// Enable mask
	sta $d01a		// IRQ interrupt ON

	lda #%01111111		// Load interrupt control CIA 1:
				// Timer A underflow : OFF
				// Timer B underflow : OFF
				// TOD               : OFF
				// Serial shift reg. : OFF
				// Pos. edge FLAG pin: OFF
	sta $dc0d		// Set interrupt control CIA 1
	sta $dd0d		// Set interrupt control CIA 2

	lda $dc0d		// Clear pending interrupts CIA 1
	lda $dd0d		// Clear pending interrupts CIA 2

	lda #$00
	sta $dc0e

	jsr sid_clear
	lda #4 - 1
	jsr music.init

	lda #$01
	sta $d019		// Acknowledge pending interrupts

	cli

	.if (debug) {
	lda #'r'
	ldx #$e
	sta screen
	stx colram
	ldx #$3
	sta screen + 1
	stx colram + 1
	ldx #$d
	sta screen + 2
	stx colram + 2
	ldx #$1
	sta screen + 3
	stx colram + 3
	ldx #$d
	sta screen + 4
	stx colram + 4
	ldx #$f
	sta screen + 5
	stx colram + 5
	ldx #$c
	sta screen + 6
	stx colram + 6
	}

	// wait for irq to signal it's done running
!wait:
	lda zp_fade_mode
	cmp #3
	bne !wait-

	jsr copy_screen

	jsr wait_vblank

	// restart, do this before promo_init!
	jsr sid_clear
	lda #3 - 1
	jsr music.init

	jsr promo_init

	jmp *

wait_vblank:
!l:
	bit $d011
	bpl !l-
	lda $d012
!l:
	cmp $d012
	bmi !l-
	rts

zp_init:
	// zero out vars
	lda #0
	ldx #zp_size
!l:
	dex
	sta zp_start, x
	bne !l-

	// init non-zero vars
	lda #time_delay_init
	sta zp_fade_time

	lda #<screen
	sta zp_fade_row_top
	lda #>screen
	sta zp_fade_row_top + 1

	lda #<screen + 24 * 40
	sta zp_fade_row_bot
	lda #>screen + 24 * 40
	sta zp_fade_row_bot + 1

	// TODO remove colram zp vars
	lda #<colram
	sta zp_fade_row_top_col
	sta zp_fade_row_bot_col

	lda #>colram
	sta zp_fade_row_top_col + 1
	sta zp_fade_row_bot_col + 1

	lda #13
	sta zp_fade_row_step

	rts

sid_clear:
	lda #0
	ldx #sid_size
!l:
	dex
	sta sid, x
	bne !l-
	rts

irq1:
	pha
	txa
	pha
	tya
	pha

	.if (debug) {
	inc $d020
	}
	jsr fade_ctl
	jsr music.play
	.if (debug) {
	dec $d020
	}


	asl $d019

	pla
	tay
	pla
	tax
	pla
	rti

irq_dummy:
	asl $d019
	rti

fade_ctl:
	// use jumptable
	ldx zp_fade_mode
	lda fade_vec_lo, x
	sta !j+ + 1
	lda fade_vec_hi, x
	sta !j+ + 2
!j:
	jmp $0000

fade_step:
	dec zp_fade_time
	bne !s+

	// check idx
	ldx zp_fade_idx
	lda fade_col, x
	cmp #$ff
	beq fade_restore

	// do fade
	ldx #0
!l:
	sta colram + 0 * $100, x
	sta colram + 1 * $100, x
	sta colram + 2 * $100, x
	sta colram + 3 * $100 - 24, x
	dex
	bne !l-

	inc zp_fade_idx

	// restore timer
	ldx #time_delay
	stx zp_fade_time
!s:
	rts

fade_restore:
	// advance mode
	lda #1
	sta zp_fade_mode

	// zero out chars
	lda #' '
	ldx #0
!l:
	sta screen + 0 * $100, x
	sta screen + 1 * $100, x
	sta screen + 2 * $100, x
	sta screen + 3 * $100 - 24, x
	dex
	bne !l-

	// restore colram
	lda #$e
	ldx #0
!l:
	sta colram + 0 * $100, x
	sta colram + 1 * $100, x
	sta colram + 2 * $100, x
	sta colram + 3 * $100 - 24, x
	dex
	bne !l-

	// restore timer
	ldx #time_delay
	stx zp_fade_time
	rts

fade_row:
	dec zp_fade_time
	bne !s+

	// fill top and bottom row
	ldy #40
	lda #$a0
!l:
	dey
	sta (zp_fade_row_top), y
	sta (zp_fade_row_bot), y
	bne !l-

	// increment top
	lda zp_fade_row_top
	clc
	adc #40
	sta zp_fade_row_top
	lda zp_fade_row_top + 1
	adc #0
	sta zp_fade_row_top + 1

	// decrement bottom
	sec
	lda zp_fade_row_bot
	sbc #40
	sta zp_fade_row_bot
	lda zp_fade_row_bot + 1
	sbc #0
	sta zp_fade_row_bot + 1

	// update step counter
	dec zp_fade_row_step
	beq !done+

	// restore timer
	ldx #time_delay
	stx zp_fade_time
!s:
	rts
!done:
fade_screen:
	// clear screen
	lda #' '
	ldx #0
!l:
	sta screen + 0 * $100, x
	sta screen + 1 * $100, x
	sta screen + 2 * $100, x
	sta screen + 3 * $100 - 24, x
	dex
	bne !l-

	// set background and border
	lda #$e
	sta $d020
	sta $d021

	// advance fade mode
	lda #2
	sta zp_fade_mode

	// reset col index
	lda #0
	sta zp_fade_idx

	// restore timer
	ldx #time_delay
	stx zp_fade_time
	rts

	// fill first rows
	ldx #40
	lda #'@'
!l:
	dex
	sta screen, x
	bne !l-

	jmp fade_restore


fade_out:
	dec zp_fade_time
	bne !s+

	ldx zp_fade_idx
	lda fade_col2, x
	cmp #$ff
	beq !done+

	sta $d020
	sta $d021

	inc zp_fade_idx

	// restore timer
	ldx #time_delay
	stx zp_fade_time
!s:
	rts

!done:
	lda #3
	sta zp_fade_mode
	rts

wait:
	rts

fade_vec_lo:
	.byte <fade_step, <fade_row, <fade_out, <wait
fade_vec_hi:
	.byte >fade_step, >fade_row, >fade_out, >wait

fade_col:
	.byte $e, $3, $d, $1, $d, $f, $e, $6, $ff

fade_col2:
	.byte $e, $6, $c, $b, $0, $ff

// music begin
	*=music.location "Music"
	.fill music.size, music.getData(i)

//----------------------------------------------------------
	// Print the music info while assembling
	.print ""
	.print "SID Data"
	.print "--------"
	.print "location=$"+toHexString(music.location)
	.print "init=$"+toHexString(music.init)
	.print "play=$"+toHexString(music.play)
	.print "songs="+music.songs
	.print "startSong="+music.startSong
	.print "size=$"+toHexString(music.size)
	.print "name="+music.name
	.print "author="+music.author
	.print "copyright="+music.copyright

	.print ""
	.print "Additional tech data"
	.print "--------------------"
	.print "header="+music.header
	.print "header version="+music.version
	.print "flags="+toBinaryString(music.flags)
	.print "speed="+toBinaryString(music.speed)
	.print "startpage="+music.startpage
	.print "pagelength="+music.pagelength
// music end


// screen color data orig at 2be8
// screen character data orig at 2800
// character bitmap definitions at 2000

.pc=* "code 2"

copy_screen:
	// set screen memory ($2400) and charset bitmap offset ($1000)
	lda #$94
	sta $D018

	// set border color
	lda #$00
	sta $D020
	sta $D021

	ldx #0
!l:
	lda coldata + 0 * $100, x
	sta colram + 0 * $100, x
	lda coldata + 1 * $100, x
	sta colram + 1 * $100, x
	lda coldata + 2 * $100, x
	sta colram + 2 * $100, x
	lda coldata + 3 * $100 - 24, x
	sta colram + 3 * $100 - 24, x
	dex
	bne !l-

	rts

promo_init:
	sei
	lda #$35		// Disable KERNAL and BASIC ROM
	sta $01			// Enable all RAM

	lda #<irq_init		// Setup IRQ vector
	sta $fffe
	lda #>irq_init
	sta $ffff

	lda #<dummy
	sta $fffa
	sta $fffc
	lda #>dummy
	sta $fffb
	sta $fffd

	lda #%00011011		// Load screen control:
				// Vertical scroll    : 3
				// Screen height      : 25 rows
				// Screen             : ON
				// Mode               : TEXT
				// Extended background: OFF
	sta $d011       	// Set screen control

	set_irq #irq_line_init : #irq_init

	lda #$01		// Enable mask
	sta $d01a		// IRQ interrupt ON

	lda #%01111111		// Load interrupt control CIA 1:
				// Timer A underflow : OFF
				// Timer B underflow : OFF
				// TOD               : OFF
				// Serial shift reg. : OFF
				// Pos. edge FLAG pin: OFF
	sta $dc0d		// Set interrupt control CIA 1
	sta $dd0d		// Set interrupt control CIA 2

	lda $dc0d		// Clear pending interrupts CIA 1
	lda $dd0d		// Clear pending interrupts CIA 2

	lda #$00
	sta $dc0e

	lda #$01
	sta $d019		// Acknowledge pending interrupts

	cli			// Start firing interrupts
	rts

irq_init:
	irq
	.if (debug) {
	inc $d020
	}
	// pas horizontale verplaatsing toe
	lda #$c0
	ora scroll_xpos
	sta $d016
	.if (debug) {
	dec $d020
	}
	qri2 #irq_line_main : #irq_main

irq_main:
	irq
	.if (debug) {
	inc $d020
	}

	// herstel horizontale verplaatsing
	lda #$c8
	sta $d016

	jsr scroll
	jsr music.play
	.if (debug) {
	dec $d020
	}
	qri2 #irq_line_init : #irq_init

dummy:
	asl $d019
	rti

.var scroll_screen = $2400 + 24 * 40

set_scroll:
	rts

// screen character data
*=$2400 "promo screen"
	.byte	$20, $20, $20, $20, $20, $20, $E9, $DF, $20, $20, $E9, $DF, $20, $20, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $51, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $5F, $A0, $DF, $E9, $A0, $69, $20, $20, $20, $20, $20, $A0, $20, $20, $20, $E9, $A0, $DF, $20, $A0, $A0, $A0, $20, $A0, $20, $A0, $A0, $DF, $20, $E9, $A0, $A0, $20, $20
	.byte	$20, $20, $20, $E9, $A0, $20, $20, $5F, $A0, $A0, $69, $20, $20, $A0, $DF, $20, $20, $A0, $20, $20, $20, $A0, $79, $69, $20, $20, $E9, $69, $20, $A0, $20, $A0, $20, $A0, $20, $A0, $20, $A0, $20, $20
	.byte	$20, $20, $E9, $69, $20, $20, $20, $E9, $A0, $A0, $DF, $20, $20, $20, $5F, $DF, $20, $A0, $20, $20, $20, $A0, $63, $20, $20, $E9, $69, $20, $20, $A0, $20, $A0, $20, $A0, $20, $5F, $A0, $A0, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $E9, $A0, $69, $5F, $A0, $DF, $20, $20, $20, $A0, $20, $A0, $A0, $A0, $20, $5F, $A0, $69, $20, $A0, $A0, $A0, $20, $A0, $20, $A0, $20, $A0, $20, $20, $20, $A0, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $5F, $69, $20, $20, $5F, $69, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $E9, $A0, $69, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $A0, $20, $20, $0F, $16, $05, $12, $20, $04, $05, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $E9, $DF, $20, $20, $E9, $DF, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $5F, $A0, $DF, $E9, $A0, $69, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $03, $0F, $0D, $0D, $0F, $04, $0F, $12, $05, $20, $36, $34, $20, $20, $20, $20, $20, $20
	.byte	$20, $E9, $69, $20, $20, $20, $20, $5F, $A0, $A0, $69, $20, $20, $20, $20, $5F, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $5F, $DF, $20, $20, $20, $20, $E9, $A0, $A0, $DF, $20, $20, $20, $20, $E9, $69, $20, $04, $0F, $0F, $12, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $E9, $A0, $69, $5F, $A0, $DF, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $5F, $69, $20, $20, $5F, $69, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $06, $0F, $0C, $0B, $05, $12, $14, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $E9, $DF, $20, $20, $E9, $DF, $20, $20, $20, $A0, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $A0, $20, $20, $20, $5F, $A0, $DF, $E9, $A0, $69, $20, $20, $20, $A0, $20, $20, $20, $6D, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $31, $30, $20, $0D, $01, $01, $12, $14, $20, $20
	.byte	$20, $20, $5F, $DF, $20, $20, $20, $5F, $A0, $A0, $69, $20, $20, $20, $E9, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $40, $40, $40, $40, $40, $40, $40, $40, $73, $20
	.byte	$20, $20, $20, $5F, $A0, $20, $20, $E9, $A0, $A0, $DF, $20, $20, $A0, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $31, $37, $3A, $30, $30, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $E9, $A0, $69, $5F, $A0, $DF, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $40, $40, $40, $40, $40, $40, $40, $40, $73, $20
	.byte	$20, $20, $20, $20, $20, $20, $5F, $69, $20, $20, $5F, $69, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $03, $30, $2E, $30, $35, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $40, $40, $40, $40, $40, $40, $40, $40, $73, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $28, $0C, $05, $1A, $09, $0E, $07, $20, $09, $13, $20, $31, $20, $03, $0F, $0C, $2E, $10, $15, $0E, $14, $20, $17, $01, $01, $12, $04, $29, $20, $20, $31, $39, $38, $32, $40, $32, $30, $32, $32
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20
	.byte	$20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20, $20

// screen color data
*=$2800 "promo color"
coldata:
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $02, $06, $06, $0E, $02, $02, $02, $02, $06, $06, $06, $0E, $02, $06, $06, $0E, $06, $06, $02, $02, $02, $06, $06
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0A, $06, $0E, $0E, $0A, $0A, $0A, $0E, $0A, $0A, $0A, $0E, $0A, $06, $0A, $0A, $0A, $06, $0A, $0A, $0A, $06, $06
	.byte	$0E, $0E, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $0E, $07, $06, $0E, $0E, $07, $07, $07, $0E, $0E, $07, $07, $0E, $07, $06, $07, $0E, $07, $06, $07, $06, $07, $06, $06
	.byte	$0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $0D, $06, $06, $0E, $0D, $0D, $06, $0E, $0D, $0D, $0E, $0E, $0D, $06, $0D, $06, $0D, $06, $0D, $0D, $0D, $06, $06
	.byte	$0E, $06, $06, $06, $06, $0E, $06, $06, $06, $06, $06, $06, $0E, $06, $06, $06, $06, $0E, $0E, $0E, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $0E, $06, $0E, $06, $06, $06, $0E, $06, $06
	.byte	$0E, $0E, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $06, $0E, $0E, $06, $06, $0E, $06, $06, $06, $06, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $06, $0E, $04, $04, $04, $06, $0E
	.byte	$06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $01, $01, $01, $01, $01, $06, $01, $01, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $0E, $0E, $0E, $0E
	.byte	$0E, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $06, $06, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $01, $01, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$06, $06, $06, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$06, $06, $06, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $0E, $0E, $06, $06, $06, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $06, $06, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $0E, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $06, $0E, $06, $06, $06, $0E, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $06, $06, $06, $06, $0E, $06, $06, $06, $06, $06, $06, $0E, $06, $06, $06, $06, $06, $06, $00, $0E, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E
	.byte	$0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $06, $06, $06, $0E, $0E, $0E, $06, $0E, $0E, $0E, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E
	.byte	$0E, $0E, $06, $06, $06, $0E, $0E, $06, $06, $06, $06, $0E, $0E, $06, $06, $06, $0E, $06, $06, $06, $0E, $06, $06, $06, $06, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $06, $06, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $0E, $06, $06, $06, $06, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E, $01, $01, $01, $01, $01, $0E, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $06, $0E, $06, $0E, $0E, $0E, $0E, $01, $01, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $06, $06, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E
	.byte	$0E, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.byte	$0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $0E, $0E, $0E, $01, $01, $01, $01, $01, $01, $01, $01, $01
	.byte	$0B, $09, $08, $02, $07, $0D, $0E, $0F, $01, $01, $01, $01, $01, $01, $0F, $0E, $0D, $07, $0A, $02, $02, $0A, $07, $0D, $0E, $0F, $01, $01, $01, $01, $01, $01, $0F, $0E, $0D, $07, $02, $08, $09, $0B

.pc=* "code 3"

scroll:
	// verplaats horizontaal
	lda scroll_xpos
	sec
!spdptr:
	sbc scroll_speed_tbl
	and #$07
	sta scroll_xpos
	bcc !move+
	jmp !klaar+
!move:
	// verplaats alles één naar links
	ldx #$00
!l:
	lda scroll_screen + 1, x
	sta scroll_screen, x
	inx
	cpx #40
	bne !l-

	// haal eentje op uit de rij
!textptr:
	lda scroll_text
	cmp #$ff
	bne !nowrap+
	jsr scroll_herstel
!nowrap:
	sta scroll_screen + 39
	// werk textptr bij
	inc !textptr- + 1
	bne * + 5
	inc !textptr- + 2
	// werk timer bij
	inc scroll_timer
	// kijk of hij verlopen is
	lda scroll_timer
!timeptr:
	cmp scroll_time_tbl
	bcc !klaar+
	// hij is verlopen
.if (debug) {
	// laat het op het scherm zien
	inc $0500
}
	lda #0
	sta scroll_timer
	// werk timer ptr bij
	inc !timeptr- + 1
	bne * + 5
	inc !timeptr- + 2
	// werk speed ptr bij
	inc !spdptr- + 1
	bne * + 5
	inc !spdptr- + 2
	// kijk nu of de speedptr op het einde is
	// zo ja, herstel de timers
	lda !spdptr- + 1
	sta !ptr+ + 1
	lda !spdptr- + 2
	sta !ptr+ + 2
!ptr:
	lda scroll_speed_tbl
	cmp #$ff
	bne !klaar+
	jsr scroll_time_herstel
!klaar:
	rts

scroll_time_herstel:
	// herstel timer
	lda #0
	sta scroll_timer
.if (debug) {
	lda #' '
	sta $0500
}
	// herstel time ptr
	lda #<scroll_time_tbl
	sta !timeptr- + 1
	lda #>scroll_time_tbl
	sta !timeptr- + 2
	// herstel speed ptr
	lda #<scroll_speed_tbl
	sta !spdptr- + 1
	lda #>scroll_speed_tbl
	sta !spdptr- + 2
	rts

scroll_herstel:
	// haal dit uit commentaar als je de snelheid
	// ook wil herstellen als de tekst rondgaat:
	//jsr scroll_time_herstel
	// herstel ptr
	lda #<scroll_text
	sta !textptr- + 1
	sta !ptr+ + 1
	lda #>scroll_text
	sta !textptr- + 2
	sta !ptr+ + 2
!ptr:
	lda scroll_text
	rts

scroll_xpos:
	.byte 0
scroll_text:
	.text " heb je altijd willen weten hoe mensen vroeger software konden maken die in 64 kilobytes of minder past? of heb je nog nooit een 40 jaar oude computer gezien? "
	.text "woon dan deze lezing bij waarin we gaan kijken hoe personal computers er vroeger uitzagen, wat je er mee kan doen en waarom het gewoon heel leuk is om er mee te spelen! "
	.text "de lezing duurt 1 uur en we gaan op een speelse wijze kijken naar verschillende uitdagingen die men vroeger tegenkwam. jullie worden ook gestimuleerd om zelf vragen te stellen! "
	.text "deze lezing is 1 colloquiumpunt waard. voor deze lezing hoef je je niet aan te melden."
	.byte $ff

/*

Heb je altijd al willen weten hoe mensen vroeger software konden maken die in 64 kilobytes of minder past? Of heb je nog nooit een 40 jaar oude computer gezien?

Woon dan deze lezing bij waarin we gaan kijken hoe personal computers er vroeger uitzagen, wat je er mee kon doen en waarom het gewoon heel leuk is om er mee te spelen!

De lezing duurt één uur en we gaan op een speelse wijze kijken naar verschillende uitdagingen die men vroeger tegenkwam. Jullie worden ook gestimuleerd om zelf vragen te stellen!

Deze lezing is 1 colloquiumpunt waard.

Voor deze lezing hoef je je niet aan te melden.

*/

scroll_timer:
	.byte 0

// tafels voor het scrollen met variërende snelheid
// de speed tafel moet eindigen met $ff en dus eentje langer zijn dan time_tbl
scroll_time_tbl:
	.byte 2, 2, 2, 2, 2, 4
scroll_speed_tbl:
	.byte 2, 3, 4, 3, 2, 1, $ff
