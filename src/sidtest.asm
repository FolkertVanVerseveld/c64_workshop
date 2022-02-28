BasicUpstart2(start)

#import "pseudo.lib"

.var TOP100 = "D:/c64/C64Music/HVSC_Top_100/Top100"
//.var sidpath = TOP100 + "/Kinetix.sid"
//.var sidpath = TOP100 + "/Armalyte.sid"
.var sidpath = TOP100 + "/Eliminator.sid"
.var music = LoadSid(sidpath)

.var irq_line = $80
.var debug = true

start:
	//jsr zp_init
	
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
	
	// setup music
	jsr sid_clear
	lda #music.startSong - 1
	//lda #3
	jsr music.init

	lda #$01
	sta $d019		// Acknowledge pending interrupts
	
	cli
	
	jmp *

irq1:
	irq
	
	.if (debug) {
	inc $d020
	}
	
	jsr music.play
	
	.if (debug) {
	dec $d020
	}
	
	qri

sid_clear:
	lda #0
	ldx #sid_size
!l:
	dex
	sta sid, x
	bne !l-
	rts

irq_dummy:
	lda #$ff
	sta $d019
	rti

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