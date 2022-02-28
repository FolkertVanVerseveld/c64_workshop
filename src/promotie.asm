BasicUpstart2(start)

#import "pseudo.lib"

.const colram = $d800

.var irq_line_init = $eb
.var irq_line_main = $ff
.var debug = false

start:
	jsr init
	
	// set screen memory ($0400) and charset bitmap offset ($2000)
	lda #$18
	sta $D018

	// set border color
	lda #$00
	sta $D020
	sta $D021

	// draw screen
	lda #$00
	sta $fb
	sta $fd
	sta $f7

	lda #$28
	sta $fc

	lda #$04
	sta $fe

	lda #$e8
	sta $f9
	lda #$2b
	sta $fa

	lda #$d8
	sta $f8

	ldx #$00
	ldy #$00
	lda ($fb),y
	sta ($fd),y
	lda ($f9),y
	sta ($f7),y
	iny
	bne *-9

	inc $fc
	inc $fe
	inc $fa
	inc $f8

	inx
	cpx #$04
	bne *-24

	// wait for keypress
	lda $c6
	beq *-2

	rts

init:
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
	.if (debug) {
	dec $d020
	}
	qri2 #irq_line_init : #irq_init

dummy:
	asl $d019
	rti

.var scroll_screen = $0400 + 24 * 40

set_scroll:
	rts

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


// Character bitmap definitions 2k
*=$2000
	.byte	$3C, $66, $6E, $6E, $60, $62, $3C, $00
	.byte	$18, $3C, $66, $7E, $66, $66, $66, $00
	.byte	$7C, $66, $66, $7C, $66, $66, $7C, $00
	.byte	$3C, $66, $60, $60, $60, $66, $3C, $00
	.byte	$78, $6C, $66, $66, $66, $6C, $78, $00
	.byte	$7E, $60, $60, $78, $60, $60, $7E, $00
	.byte	$7E, $60, $60, $78, $60, $60, $60, $00
	.byte	$3C, $66, $60, $6E, $66, $66, $3C, $00
	.byte	$66, $66, $66, $7E, $66, $66, $66, $00
	.byte	$3C, $18, $18, $18, $18, $18, $3C, $00
	.byte	$1E, $0C, $0C, $0C, $0C, $6C, $38, $00
	.byte	$66, $6C, $78, $70, $78, $6C, $66, $00
	.byte	$60, $60, $60, $60, $60, $60, $7E, $00
	.byte	$63, $77, $7F, $6B, $63, $63, $63, $00
	.byte	$66, $76, $7E, $7E, $6E, $66, $66, $00
	.byte	$3C, $66, $66, $66, $66, $66, $3C, $00
	.byte	$7C, $66, $66, $7C, $60, $60, $60, $00
	.byte	$3C, $66, $66, $66, $66, $3C, $0E, $00
	.byte	$7C, $66, $66, $7C, $78, $6C, $66, $00
	.byte	$3C, $66, $60, $3C, $06, $66, $3C, $00
	.byte	$7E, $18, $18, $18, $18, $18, $18, $00
	.byte	$66, $66, $66, $66, $66, $66, $3C, $00
	.byte	$66, $66, $66, $66, $66, $3C, $18, $00
	.byte	$63, $63, $63, $6B, $7F, $77, $63, $00
	.byte	$66, $66, $3C, $18, $3C, $66, $66, $00
	.byte	$66, $66, $66, $3C, $18, $18, $18, $00
	.byte	$7E, $06, $0C, $18, $30, $60, $7E, $00
	.byte	$3C, $30, $30, $30, $30, $30, $3C, $00
	.byte	$0C, $12, $30, $7C, $30, $62, $FC, $00
	.byte	$3C, $0C, $0C, $0C, $0C, $0C, $3C, $00
	.byte	$00, $18, $3C, $7E, $18, $18, $18, $18
	.byte	$00, $10, $30, $7F, $7F, $30, $10, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$18, $18, $18, $18, $00, $00, $18, $00
	.byte	$66, $66, $66, $00, $00, $00, $00, $00
	.byte	$66, $66, $FF, $66, $FF, $66, $66, $00
	.byte	$18, $3E, $60, $3C, $06, $7C, $18, $00
	.byte	$62, $66, $0C, $18, $30, $66, $46, $00
	.byte	$3C, $66, $3C, $38, $67, $66, $3F, $00
	.byte	$06, $0C, $18, $00, $00, $00, $00, $00
	.byte	$0C, $18, $30, $30, $30, $18, $0C, $00
	.byte	$30, $18, $0C, $0C, $0C, $18, $30, $00
	.byte	$00, $66, $3C, $FF, $3C, $66, $00, $00
	.byte	$00, $18, $18, $7E, $18, $18, $00, $00
	.byte	$00, $00, $00, $00, $00, $18, $18, $30
	.byte	$00, $00, $00, $7E, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $18, $18, $00
	.byte	$00, $03, $06, $0C, $18, $30, $60, $00
	.byte	$3C, $66, $6E, $76, $66, $66, $3C, $00
	.byte	$18, $18, $38, $18, $18, $18, $7E, $00
	.byte	$3C, $66, $06, $0C, $30, $60, $7E, $00
	.byte	$3C, $66, $06, $1C, $06, $66, $3C, $00
	.byte	$06, $0E, $1E, $66, $7F, $06, $06, $00
	.byte	$7E, $60, $7C, $06, $06, $66, $3C, $00
	.byte	$3C, $66, $60, $7C, $66, $66, $3C, $00
	.byte	$7E, $66, $0C, $18, $18, $18, $18, $00
	.byte	$3C, $66, $66, $3C, $66, $66, $3C, $00
	.byte	$3C, $66, $66, $3E, $06, $66, $3C, $00
	.byte	$00, $00, $18, $00, $00, $18, $00, $00
	.byte	$00, $00, $18, $00, $00, $18, $18, $30
	.byte	$0E, $18, $30, $60, $30, $18, $0E, $00
	.byte	$00, $00, $7E, $00, $7E, $00, $00, $00
	.byte	$70, $18, $0C, $06, $0C, $18, $70, $00
	.byte	$3C, $66, $06, $0C, $18, $00, $18, $00
	.byte	$00, $00, $00, $FF, $FF, $00, $00, $00
	.byte	$08, $1C, $3E, $7F, $7F, $1C, $3E, $00
	.byte	$18, $18, $18, $18, $18, $18, $18, $18
	.byte	$00, $00, $00, $FF, $FF, $00, $00, $00
	.byte	$00, $00, $FF, $FF, $00, $00, $00, $00
	.byte	$00, $FF, $FF, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $FF, $FF, $00, $00
	.byte	$30, $30, $30, $30, $30, $30, $30, $30
	.byte	$0C, $0C, $0C, $0C, $0C, $0C, $0C, $0C
	.byte	$00, $00, $00, $E0, $F0, $38, $18, $18
	.byte	$18, $18, $1C, $0F, $07, $00, $00, $00
	.byte	$18, $18, $38, $F0, $E0, $00, $00, $00
	.byte	$C0, $C0, $C0, $C0, $C0, $C0, $FF, $FF
	.byte	$C0, $E0, $70, $38, $1C, $0E, $07, $03
	.byte	$03, $07, $0E, $1C, $38, $70, $E0, $C0
	.byte	$FF, $FF, $C0, $C0, $C0, $C0, $C0, $C0
	.byte	$FF, $FF, $03, $03, $03, $03, $03, $03
	.byte	$00, $3C, $7E, $7E, $7E, $7E, $3C, $00
	.byte	$00, $00, $00, $00, $00, $FF, $FF, $00
	.byte	$36, $7F, $7F, $7F, $3E, $1C, $08, $00
	.byte	$60, $60, $60, $60, $60, $60, $60, $60
	.byte	$00, $00, $00, $07, $0F, $1C, $18, $18
	.byte	$C3, $E7, $7E, $3C, $3C, $7E, $E7, $C3
	.byte	$00, $3C, $7E, $66, $66, $7E, $3C, $00
	.byte	$18, $18, $66, $66, $18, $18, $3C, $00
	.byte	$06, $06, $06, $06, $06, $06, $06, $06
	.byte	$08, $1C, $3E, $7F, $3E, $1C, $08, $00
	.byte	$18, $18, $18, $FF, $FF, $18, $18, $18
	.byte	$C0, $C0, $30, $30, $C0, $C0, $30, $30
	.byte	$18, $18, $18, $18, $18, $18, $18, $18
	.byte	$00, $00, $03, $3E, $76, $36, $36, $00
	.byte	$FF, $7F, $3F, $1F, $0F, $07, $03, $01
	.byte	$00, $00, $00, $00, $00, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0
	.byte	$00, $00, $00, $00, $FF, $FF, $FF, $FF
	.byte	$FF, $00, $00, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $00, $00, $FF
	.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
	.byte	$CC, $CC, $33, $33, $CC, $CC, $33, $33
	.byte	$03, $03, $03, $03, $03, $03, $03, $03
	.byte	$00, $00, $00, $00, $CC, $CC, $33, $33
	.byte	$FF, $FE, $FC, $F8, $F0, $E0, $C0, $80
	.byte	$03, $03, $03, $03, $03, $03, $03, $03
	.byte	$18, $18, $18, $1F, $1F, $18, $18, $18
	.byte	$00, $00, $00, $00, $0F, $0F, $0F, $0F
	.byte	$18, $18, $18, $1F, $1F, $00, $00, $00
	.byte	$00, $00, $00, $F8, $F8, $18, $18, $18
	.byte	$00, $00, $00, $00, $00, $00, $FF, $FF
	.byte	$00, $00, $00, $1F, $1F, $18, $18, $18
	.byte	$18, $18, $18, $FF, $FF, $00, $00, $00
	.byte	$00, $00, $00, $FF, $FF, $18, $18, $18
	.byte	$18, $18, $18, $F8, $F8, $18, $18, $18
	.byte	$C0, $C0, $C0, $C0, $C0, $C0, $C0, $C0
	.byte	$E0, $E0, $E0, $E0, $E0, $E0, $E0, $E0
	.byte	$07, $07, $07, $07, $07, $07, $07, $07
	.byte	$FF, $FF, $00, $00, $00, $00, $00, $00
	.byte	$FF, $FF, $FF, $00, $00, $00, $00, $00
	.byte	$00, $00, $00, $00, $00, $FF, $FF, $FF
	.byte	$03, $03, $03, $03, $03, $03, $FF, $FF
	.byte	$00, $00, $00, $00, $F0, $F0, $F0, $F0
	.byte	$0F, $0F, $0F, $0F, $00, $00, $00, $00
	.byte	$18, $18, $18, $F8, $F8, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $00, $00, $00, $00
	.byte	$F0, $F0, $F0, $F0, $0F, $0F, $0F, $0F
	.byte	$C3, $99, $91, $91, $9F, $99, $C3, $FF
	.byte	$E7, $C3, $99, $81, $99, $99, $99, $FF
	.byte	$83, $99, $99, $83, $99, $99, $83, $FF
	.byte	$C3, $99, $9F, $9F, $9F, $99, $C3, $FF
	.byte	$87, $93, $99, $99, $99, $93, $87, $FF
	.byte	$81, $9F, $9F, $87, $9F, $9F, $81, $FF
	.byte	$81, $9F, $9F, $87, $9F, $9F, $9F, $FF
	.byte	$C3, $99, $9F, $91, $99, $99, $C3, $FF
	.byte	$99, $99, $99, $81, $99, $99, $99, $FF
	.byte	$C3, $E7, $E7, $E7, $E7, $E7, $C3, $FF
	.byte	$E1, $F3, $F3, $F3, $F3, $93, $C7, $FF
	.byte	$99, $93, $87, $8F, $87, $93, $99, $FF
	.byte	$9F, $9F, $9F, $9F, $9F, $9F, $81, $FF
	.byte	$9C, $88, $80, $94, $9C, $9C, $9C, $FF
	.byte	$99, $89, $81, $81, $91, $99, $99, $FF
	.byte	$C3, $99, $99, $99, $99, $99, $C3, $FF
	.byte	$83, $99, $99, $83, $9F, $9F, $9F, $FF
	.byte	$C3, $99, $99, $99, $99, $C3, $F1, $FF
	.byte	$83, $99, $99, $83, $87, $93, $99, $FF
	.byte	$C3, $99, $9F, $C3, $F9, $99, $C3, $FF
	.byte	$81, $E7, $E7, $E7, $E7, $E7, $E7, $FF
	.byte	$99, $99, $99, $99, $99, $99, $C3, $FF
	.byte	$99, $99, $99, $99, $99, $C3, $E7, $FF
	.byte	$9C, $9C, $9C, $94, $80, $88, $9C, $FF
	.byte	$99, $99, $C3, $E7, $C3, $99, $99, $FF
	.byte	$99, $99, $99, $C3, $E7, $E7, $E7, $FF
	.byte	$81, $F9, $F3, $E7, $CF, $9F, $81, $FF
	.byte	$C3, $CF, $CF, $CF, $CF, $CF, $C3, $FF
	.byte	$F3, $ED, $CF, $83, $CF, $9D, $03, $FF
	.byte	$C3, $F3, $F3, $F3, $F3, $F3, $C3, $FF
	.byte	$FF, $E7, $C3, $81, $E7, $E7, $E7, $E7
	.byte	$FF, $EF, $CF, $80, $80, $CF, $EF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$E7, $E7, $E7, $E7, $FF, $FF, $E7, $FF
	.byte	$99, $99, $99, $FF, $FF, $FF, $FF, $FF
	.byte	$99, $99, $00, $99, $00, $99, $99, $FF
	.byte	$E7, $C1, $9F, $C3, $F9, $83, $E7, $FF
	.byte	$9D, $99, $F3, $E7, $CF, $99, $B9, $FF
	.byte	$C3, $99, $C3, $C7, $98, $99, $C0, $FF
	.byte	$F9, $F3, $E7, $FF, $FF, $FF, $FF, $FF
	.byte	$F3, $E7, $CF, $CF, $CF, $E7, $F3, $FF
	.byte	$CF, $E7, $F3, $F3, $F3, $E7, $CF, $FF
	.byte	$FF, $99, $C3, $00, $C3, $99, $FF, $FF
	.byte	$FF, $E7, $E7, $81, $E7, $E7, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $CF
	.byte	$FF, $FF, $FF, $81, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $E7, $E7, $FF
	.byte	$FF, $FC, $F9, $F3, $E7, $CF, $9F, $FF
	.byte	$C3, $99, $91, $89, $99, $99, $C3, $FF
	.byte	$E7, $E7, $C7, $E7, $E7, $E7, $81, $FF
	.byte	$C3, $99, $F9, $F3, $CF, $9F, $81, $FF
	.byte	$C3, $99, $F9, $E3, $F9, $99, $C3, $FF
	.byte	$F9, $F1, $E1, $99, $80, $F9, $F9, $FF
	.byte	$81, $9F, $83, $F9, $F9, $99, $C3, $FF
	.byte	$C3, $99, $9F, $83, $99, $99, $C3, $FF
	.byte	$81, $99, $F3, $E7, $E7, $E7, $E7, $FF
	.byte	$C3, $99, $99, $C3, $99, $99, $C3, $FF
	.byte	$C3, $99, $99, $C1, $F9, $99, $C3, $FF
	.byte	$FF, $FF, $E7, $FF, $FF, $E7, $FF, $FF
	.byte	$FF, $FF, $E7, $FF, $FF, $E7, $E7, $CF
	.byte	$F1, $E7, $CF, $9F, $CF, $E7, $F1, $FF
	.byte	$FF, $FF, $81, $FF, $81, $FF, $FF, $FF
	.byte	$8F, $E7, $F3, $F9, $F3, $E7, $8F, $FF
	.byte	$C3, $99, $F9, $F3, $E7, $FF, $E7, $FF
	.byte	$FF, $FF, $FF, $00, $00, $FF, $FF, $FF
	.byte	$F7, $E3, $C1, $80, $80, $E3, $C1, $FF
	.byte	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
	.byte	$FF, $FF, $FF, $00, $00, $FF, $FF, $FF
	.byte	$FF, $FF, $00, $00, $FF, $FF, $FF, $FF
	.byte	$FF, $00, $00, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $00, $00, $FF, $FF
	.byte	$CF, $CF, $CF, $CF, $CF, $CF, $CF, $CF
	.byte	$F3, $F3, $F3, $F3, $F3, $F3, $F3, $F3
	.byte	$FF, $FF, $FF, $1F, $0F, $C7, $E7, $E7
	.byte	$E7, $E7, $E3, $F0, $F8, $FF, $FF, $FF
	.byte	$E7, $E7, $C7, $0F, $1F, $FF, $FF, $FF
	.byte	$3F, $3F, $3F, $3F, $3F, $3F, $00, $00
	.byte	$3F, $1F, $8F, $C7, $E3, $F1, $F8, $FC
	.byte	$FC, $F8, $F1, $E3, $C7, $8F, $1F, $3F
	.byte	$00, $00, $3F, $3F, $3F, $3F, $3F, $3F
	.byte	$00, $00, $FC, $FC, $FC, $FC, $FC, $FC
	.byte	$FF, $C3, $81, $81, $81, $81, $C3, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $00, $00, $FF
	.byte	$C9, $80, $80, $80, $C1, $E3, $F7, $FF
	.byte	$9F, $9F, $9F, $9F, $9F, $9F, $9F, $9F
	.byte	$FF, $FF, $FF, $F8, $F0, $E3, $E7, $E7
	.byte	$3C, $18, $81, $C3, $C3, $81, $18, $3C
	.byte	$FF, $C3, $81, $99, $99, $81, $C3, $FF
	.byte	$E7, $E7, $99, $99, $E7, $E7, $C3, $FF
	.byte	$F9, $F9, $F9, $F9, $F9, $F9, $F9, $F9
	.byte	$F7, $E3, $C1, $80, $C1, $E3, $F7, $FF
	.byte	$E7, $E7, $E7, $00, $00, $E7, $E7, $E7
	.byte	$3F, $3F, $CF, $CF, $3F, $3F, $CF, $CF
	.byte	$E7, $E7, $E7, $E7, $E7, $E7, $E7, $E7
	.byte	$FF, $FF, $FC, $C1, $89, $C9, $C9, $FF
	.byte	$00, $80, $C0, $E0, $F0, $F8, $FC, $FE
	.byte	$01, $03, $07, $0F, $0F, $0F, $0F, $0F
	.byte	$0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
	.byte	$FF, $FF, $FF, $FF, $00, $00, $00, $00
	.byte	$00, $FF, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $FF, $00
	.byte	$3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
	.byte	$33, $33, $CC, $CC, $33, $33, $CC, $CC
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
	.byte	$FF, $FF, $FF, $FF, $33, $33, $CC, $CC
	.byte	$00, $01, $03, $07, $0F, $1F, $3F, $7F
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $FC, $FC
	.byte	$E7, $E7, $E7, $E0, $E0, $E7, $E7, $E7
	.byte	$FF, $FF, $FF, $FF, $F0, $F0, $F0, $F0
	.byte	$E7, $E7, $E7, $E0, $E0, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $07, $07, $E7, $E7, $E7
	.byte	$FF, $FF, $FF, $FF, $FF, $FF, $00, $00
	.byte	$FF, $FF, $FF, $E0, $E0, $E7, $E7, $E7
	.byte	$E7, $E7, $E7, $00, $00, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $00, $00, $E7, $E7, $E7
	.byte	$E7, $E7, $E7, $07, $07, $E7, $E7, $E7
	.byte	$3F, $3F, $3F, $3F, $3F, $3F, $3F, $3F
	.byte	$1F, $1F, $1F, $1F, $1F, $1F, $1F, $1F
	.byte	$F8, $F8, $F8, $F8, $F8, $F8, $F8, $F8
	.byte	$00, $00, $FF, $FF, $FF, $FF, $FF, $FF
	.byte	$00, $00, $00, $FF, $FF, $FF, $FF, $FF
	.byte	$FF, $FF, $FF, $FF, $FF, $00, $00, $00
	.byte	$FC, $FC, $FC, $FC, $FC, $FC, $00, $00
	.byte	$FF, $FF, $FF, $FF, $0F, $0F, $0F, $0F
	.byte	$F0, $F0, $F0, $F0, $FF, $FF, $FF, $FF
	.byte	$E7, $E7, $E7, $07, $07, $FF, $FF, $FF
	.byte	$0F, $0F, $0F, $0F, $FF, $FF, $FF, $FF
	.byte	$0F, $0F, $0F, $0F, $F0, $F0, $F0, $F0

// screen character data
*=$2800
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
*=$2be8
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
