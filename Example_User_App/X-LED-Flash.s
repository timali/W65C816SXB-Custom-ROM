; Alicie, 2022, based on original XLEDFLASH demo by WDC.
;
; Example application demonstrating the auto-exec ability of the
; customized ROM monitor. Application flashes the four chip select
; LEDs on the W65c816SXB board.

        .setcpu "65816"

; Imports. These are all exported by the linker.
        .import __XCS0_ADDR__
        .import __XCS1_ADDR__
        .import __XCS2_ADDR__
        .import __XCS3_ADDR__

; The user application starts in the CODE segment, which is the
; beginning of flash memory.
        .code

        ; This signature must be present here, at the beginning of the
        ; flash, for the custom ROM monitor to auto-execute the code.
        .byte   "WDC"

; When the ROM monitor executes the code, we're in '02' emulation mode
; with interrupts and decimal disabled. Everything else is undefined.
Start:
        ; Set up the stack.
        ldx     #$FF
        txs

Flash_LED:
; Access memory using the XCS0 chip select, lighting the LED.
        ldy     #$00
@L0B:   ldx     #$00
@L0A:   inc     __XCS0_ADDR__
        dex
        bne     @L0A
        dey
        bne     @L0B

        jsr     Delay
        jsr     Delay

; Access memory using the XCS1 chip select, lighting the LED.
        ldy     #$00
@L1B:   ldx     #$00
@L1A:   inc     __XCS1_ADDR__
        dex
        bne     @L1A
        dey
        bne     @L1B
        jsr     Delay
        jsr     Delay

; Access memory using the XCS2 chip select, lighting the LED.
        ldy     #$00
@L2B:   ldx     #$00
@L2A:   inc     __XCS2_ADDR__
        dex
        bne     @L2A
        dey
        bne     @L2B

        jsr     Delay
        jsr     Delay

; Access memory using the XCS3 chip select, lighting the LED.
        ldy     #$00
@L3B:   ldx     #$00
@L3A:   inc     __XCS3_ADDR__
        dex
        bne     @L3A
        dey
        bne     @L3B
        jsr     Delay
        jsr     Delay

        ; Repeat the entire LED flash sequence over again.
        bra     Flash_LED

; Delay For 65535 Cycles 
Delay:
        phx
        phy

        ldy     #$00
@L2:    ldx     #$00
@L1:    dex
        bne     @L1
        dey
        bne     @L2

        ply
        plx
        rts