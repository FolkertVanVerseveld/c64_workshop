BasicUpstart2(start)

#import "pseudo.lib"

.var TOP100 = "D:/c64/C64Music/HVSC_Top_100/Top100"
.var sidpath = TOP100 + "/Eliminator.sid"
.var music = LoadSid(sidpath)

.var irq_line = $f0
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

	jmp *

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
	rts

fade_vec_lo:
	.byte <fade_step, <fade_row, <fade_out
fade_vec_hi:
	.byte >fade_step, >fade_row, >fade_out

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
