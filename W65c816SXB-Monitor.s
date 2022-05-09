; Disassembly of W65816SXB SBC monitor ROM.
; Alicie, 2022, based on original work by "Keith".

        .setcpu "65816"

; Most of the time, the monitor uses 8-bit A and XY registers, even in
; 65816 native mode. So to keep it simple, we'll only use .A16 or .I16
; when necessary, and we'll only use .A8 and .I8 in the places needed
; to restore the assembler back to 8-bit mode. So we'll not use a .A8
; or a .I8 every time there is a SEP -- only when it is actually needed.

; Zero-page variables that are temporarily used when executing commands
; from the debugger. When the monitor is entered, their values are saved
; into the ZP save area in work RAM (RAM_ZP_SAVE), and restored before
; control is returned to the user's program, so their use by the debugger
; and monitor is transparent to the user.

; Imports. These are all exported by the linker.
        .import __HW_IO_ADDR__
        .import __HW_IO_SIZE__
        .import __VIA_USB_ADDR__
        .import __HW_BRK_ADDR__
        .import __WORK_RAM_LOAD__
        .import __SHADOW_VECTORS_LOAD__
        .import __SHADOW_VECTORS_SIZE__
        .import __MONITOR_HEADER_LOAD__
        .import __CPU_VECTORS_LOAD__

; Export some useful symbols so they are shown in the map file.
        .export RAM_A_SAVE
        .export RAM_X_SAVE
        .export RAM_Y_SAVE
        .export RAM_PC_SAVE
        .export RAM_DP_SAVE
        .export RAM_SP_SAVE
        .export RAM_P_SAVE
        .export RAM_E_SAVE
        .export RAM_PB_SAVE
        .export RAM_DB_SAVE
        .export RAM_CPU_TYPE
        .export RAM_IN_MONITOR
        .export RAM_ZP_SAVE
        .export IRQ_02_ENTRY_VECTOR
        .export NMI_02_ENTRY_VECTOR
        .export BRK_816_ENTRY_VECTOR
        .export NMI_816_ENTRY_VECTOR
        .export SHADOW_VEC_COP_816
        .export SHADOW_VEC_ABORT_816
        .export SHADOW_VEC_IRQ_816
        .export SHADOW_VEC_COP_02
        .export SHADOW_VEC_ABORT_02
        .export SHADOW_VEC_IRQ_02
        .export Pointer_Table
        .export RESET_entry

; Symbol definitions.
BOARD_ID                        := $58

        .zeropage

; Varibales used by the debugger. They are copied and restored to work-
; RAM, so their usage is transparent to the user's application.
DBG_VAR_00:                     .res 1
DBG_VAR_01:                     .res 1
DBG_VAR_02:                     .res 1
DBG_VAR_03:                     .res 1
DBG_VAR_04:                     .res 1

        .segment "WORK_RAM"

; Save-area in work-RAM for A.
RAM_A_SAVE:                     .res 2

; Save-area in work-RAM for X.
RAM_X_SAVE:                     .res 2

; Save-area in work-RAM for Y.
RAM_Y_SAVE:                     .res 2

; Save-area in work-RAM for PC.
RAM_PC_SAVE:                    .res 2

; Save-area in work-RAM for DP.
RAM_DP_SAVE:                    .res 2

; Save-area in work-RAM for the stack pointer.
RAM_SP_SAVE:                    .res 2

; Save-area in work-RAM for the P register.
RAM_P_SAVE:                     .res 1

; Save-area in work-RAM for the emulation bit. This can be thought of
; as an extenstion bit to P. If E=1, the CPU is in emulation mode.
RAM_E_SAVE:                     .res 1

; Save-area in work-RAM for the PB register.
RAM_PB_SAVE:                    .res 1

; Save-area in work-RAM for the DB register.
RAM_DB_SAVE:                    .res 1

; The auto-detected CPU type (0=65C02, 1=65816).
RAM_CPU_TYPE:                   .res 1

; 1 if the the monitor is currently being executed, 0 if user code.
RAM_IN_MONITOR:                 .res 2

; Why control has returned to the ROM monitor:
;    2: A BRK instruction was executed.
;    7: An NMI was generated.
RAM_ENTER_MONITOR_REASON :      .res 1

; Five-byte area where $00-$04 are saved.
RAM_ZP_SAVE:                    .res 5

; Flag variable at $7E19 of unknown use. It only ever gets set to 0.
RAM_VAR_7E19:                   .res 1

; Variable at $7E1A of unknown use. It gets set to 0, and apparently not used.
RAM_VAR_7E1A:                   .res 2

; Save-area in work-RAM for the system VIA's registers.
RAM_PCR_SAVE:                   .res 1
RAM_DDRB_SAVE:                  .res 1
RAM_DDRA_SAVE:                  .res 1

        .segment "RAW_VECTORS"

; Vectors in RAM which are called directly from the vectors in FLASH.
; These vectors are typically not overridden by the user, since they
; perform critical system and debugger operations.
IRQ_02_ENTRY_VECTOR:            .res 2
NMI_02_ENTRY_VECTOR:            .res 2
BRK_816_ENTRY_VECTOR:           .res 2
NMI_816_ENTRY_VECTOR:           .res 2

        .segment "SHADOW_VECTORS"

; Shadow vectors for 816 mode, which the user may set to hook the vector.
SHADOW_VEC_COP_816:             .res 2
SHADOW_VEC_BRK_816:             .res 2 ; unused
SHADOW_VEC_ABORT_816:           .res 2
SHADOW_VEC_NMI_816:             .res 2 ; unused
SHADOW_VEC_RSVD_816:            .res 2 ; unused
SHADOW_VEC_IRQ_816:             .res 2

; Shadow vectors for the 65816 running in '02 emulation mode.
SHADOW_VEC_RSVD1_02:            .res 2 ; unused
SHADOW_VEC_RSVD2_02:            .res 2 ; unused
SHADOW_VEC_COP_02:              .res 2
SHADOW_VEC_RSVD3_02:            .res 2 ; unused
SHADOW_VEC_ABORT_02:            .res 2

; Shadow vectors for all 65xx processors.
SHADOW_VEC_NMI_02:              .res 2 ; unused
SHADOW_VEC_RESET_02:            .res 2 ; unused
SHADOW_VEC_IRQ_02:              .res 2

        .segment "VIA_USB"

; IO for the VIA which is used for the USB debugger interface.
; Unused registers are commented-out.
SYSTEM_VIA_IOB          := __VIA_USB_ADDR__ + $00 ; Port B IO register
SYSTEM_VIA_IOA          := __VIA_USB_ADDR__ + $01 ; Port A IO register
SYSTEM_VIA_DDRB         := __VIA_USB_ADDR__ + $02 ; Port B data direction register
SYSTEM_VIA_DDRA         := __VIA_USB_ADDR__ + $03 ; Port A data direction register
;SYSTEM_VIA_T1C_L       := __VIA_USB_ADDR__ + $04 ; Timer 1 counter/latches, low-order
;SYSTEM_VIA_T1C_H       := __VIA_USB_ADDR__ + $05 ; Timer 1 high-order counter
;SYSTEM_VIA_T1L_L       := __VIA_USB_ADDR__ + $06 ; Timer 1 low-order latches
;SYSTEM_VIA_T1L_H       := __VIA_USB_ADDR__ + $07 ; Timer 1 high-order latches
;SYSTEM_VIA_T2C_L       := __VIA_USB_ADDR__ + $08 ; Timer 2 counter/latches, lower-order
;SYSTEM_VIA_T2C_H       := __VIA_USB_ADDR__ + $09 ; Timer 2 high-order counter
;SYSTEM_VIA_SR          := __VIA_USB_ADDR__ + $0A ; Shift register
SYSTEM_VIA_ACR          := __VIA_USB_ADDR__ + $0B ; Auxilliary control register
SYSTEM_VIA_PCR          := __VIA_USB_ADDR__ + $0C ; Peripheral control register
;SYSTEM_VIA_IFR         := __VIA_USB_ADDR__ + $0D ; Interrupt flag register
;SYSTEM_VIA_IER         := __VIA_USB_ADDR__ + $0E ; Interrupt enable register
;SYSTEM_VIA_ORA_IRA     := __VIA_USB_ADDR__ + $0F ; Port A IO register, but no handshake

        ; The monitor should begin with a header which includes a signature and version.
        .segment "MONITOR_HEADER"

        ; A Western Design Center mark at the beginning of the header.
        .byte   "WDC"
        .BYTE   $FF

Signature_String:
        .byte   $82,"$",$01,$FF

Monitor_Version_String:
        .asciiz   "WDC65c816SK WDCMON Version =  2.0.4.3Version Date = Wed Mar 26 2014  2:46"

        .segment "POINTER_TABLE"

; A table of important pointers. This is located at a fixed address $80 bytes
; into the monitor code, and is 128 bytes long in total. Not sure if the debugger
; uses this table for any reason, but user applications could use it, for example,
; to read and write to the USB FIFO. There is room for more pointers at the end.
Pointer_Table:

        ; Used entries in the pointer table.
        .addr   Signature_String
        .addr   Initialize_System
        .addr   Is_VIA_USB_RX_Data_Avail
        .addr   Sys_VIA_USB_Char_RX
        .addr   Sys_VIA_USB_Char_TX
        .addr   RAM_IN_MONITOR
        .addr   Monitor_Version_String
        .addr   IRQ_02_ENTRY_VECTOR
        .addr   IRQ_02_Entry_Vector_Default
        .addr   NMI_02_Entry_Vector_Default
        .addr   BRK_816_Entry_Vector_Default
        .addr   NMI_816_Entry_Vector_Default

        ; This is the start of the actual monitor code, placed in the code section.
        .code

; Called directly from FLASH vector on IRQ in emulation mode. IRQ and BRK
; are shared in this mode, so jump to monitor code which checks for BRK.
IRQ_02_entry:
        jmp     (IRQ_02_ENTRY_VECTOR)
        NOP

; Called directly from FLASH vector on NMI in emulation mode. Jump to monitor
; code to break into the debugger.
NMI_02_entry:
        jmp     (NMI_02_ENTRY_VECTOR)
        NOP

; Called directly from FLASH vector on BRK in 816 mode. Jump to monitor
; code to break into the debugger.
BRK_816_entry:
        jmp     (BRK_816_ENTRY_VECTOR)
        NOP

; Called directly from FLASH vector on NMI in 816 mode. Jump to monitor
; code to break into the debugger.
NMI_816_entry:
        jmp     (NMI_816_ENTRY_VECTOR)
        NOP

; Called directly from FLASH vector on COP in emulation mode. Call the
; user's handler through the shadow vector.
COP_02_entry:
        jmp     (SHADOW_VEC_COP_02)

; Called directly from FLASH vector on ABORT in emulation mode. Call the
; user's handler through the shadow vector.
ABORT_02_entry:
        jmp     (SHADOW_VEC_ABORT_02)

; Called directly from FLASH vector on IRQ in 816 mode.
; BRK and IRQ are separate in 816 mode, so no need to run any monitor code.
; Simply invoke the user's IRQ handler through the shadow vector.
IRQ_816_entry:
        jmp     (SHADOW_VEC_IRQ_816)

; Called directly from FLASH vector on ABORT in 816 mode.
ABORT_816_entry:
        jmp     (SHADOW_VEC_ABORT_816)

; Called directly from FLASH vector on COP in 816 mode.
COP_816_entry:
        jmp     (SHADOW_VEC_COP_816)

; Does nothing forever. Called directly from several reserved vectors, and
; is also the default handler for all shadow vectors.
Infinite_Loop:
        jsr     Do_Nothing_Subroutine_3
        BRA     Infinite_Loop

; Does nothing forever. Called directly from a reserved vector.
Infinite_Loop_2:
        SEP     #$20    ; Set A to 8-bit. The assembler is already in 8-bit mode.
        jsr     Do_Nothing_Subroutine_3
        BRA     Infinite_Loop_2

; Called directly from FLASH vector on RESET. Always executed in emulation mode.
RESET_entry:
        ; Save the CPU context, init vectors, and switch into emulation mode.
        JSR     Initialize_Upon_Reset

        ; Save a copy of ZP memory, and sync up with the debugger.
        jmp     Save_ZP_Sync_With_Debugger

; Called in emulation mode when the CPU is reset.
Initialize_Upon_Reset:
        ; Push processor status on stack. The stack is not initialized yet,
        ; but Continue_System_Init expects P and A to be pushed on the stack,
        ; and we know the stack will be somewhere in page 1, so there will be
        ; RAM there to support it.
        PHP

        ; Set A to 8-bit mode. But why? We know we're in emulation mode here.
        SEP     #$20

        ; Push A, load A with 1, and continue with initialization.
        pha
        lda     #$01
        BRA     Continue_System_Init

; Called to initialize the system. The only place this is explicitly called
; is from Initialize_Upon_Reset, which is executed in emulation mode when the
; CPU is reset. But, there is a pointer to this function in the data pointer
; table, so perhaps the debugger calls it to reset the system. As such, this
; function ensures it works correctly even if called from native mode.
Initialize_System:
        ; Push processor status on stack.
        PHP

        ; Set A to 8-bit mode and push it.
        SEP     #$20
        PHA

; If called from an actual RESET, the CPU will be in emulation mode. If called
; through the data pointer table, the CPU may be in native mode with 8-bit A.
; Upon return, the CPU will be in emulation mode.
Continue_System_Init:

        ; Disable interrupts and clear the decimal flag.
        SEI
        CLD

        ; Zero a couple of variables whose use is currently unknown.
        stz     RAM_VAR_7E1A
        STZ     RAM_VAR_7E19

        ; Switch to native mode.
        clc
        XCE

        ; Set XY to 16-bit mode and save them into the RAM save area.
        REP     #$10
.I16
        stx     RAM_X_SAVE
        STY     RAM_Y_SAVE

        ; Set A and XY to 8-bit mode. Assembler is 8-bit for A already.
        SEP     #$30
.I8

        ; Pull the prior value of A (8-bits) into X, and P into Y.
        plx
        PLY

        ; Save the processor status byte into the RAM save area.
        STY     RAM_P_SAVE

        ; Push 8-bit A back onto the stack.
        PHA

        ; Move the prior 8-bit value of A from X back into A.
        TXA

        ; Set A to 16-bit mode.
        REP     #$20
.A16

        ; Save A (all 16 bits) into the RAM save area.
        STA     f:RAM_A_SAVE

        ; Save DP (16 bits) into the RAM save area.
        TDC
        STA     f:RAM_DP_SAVE
        TSC

        ; Save the 16-bit stack pointer into the RAM save area.
        CLC
        ADC     #$03
        STA     f:RAM_SP_SAVE

        ; Set A and XY to 8-bit mode. Assembler for XY is already 8-bit.
        SEP     #$30
.A8

        ; Save the 8-bit program bank into the RAM save area.
        PHK
        pla
        STA     f:RAM_PB_SAVE

        ; Save the 8-bit data bank into the RAM save area.
        PHB
        PLA
        STA     f:RAM_DB_SAVE

        ; Save the emulation mode flag into the RAM save area. Note it gets
        ; saved as "1", which means the CPU will be in emulation mode once
        ; the context is restored and the user's code is executed.
        lda     #$01
        STA     f:RAM_E_SAVE

        ; CPU detection code. Determine if this CPU is a 65C02 or 65816.

        ; Try to switch into emulation mode.
        SEC
        XCE     ; This is a NOP on a 65C02.

        ; Try to switch into native mode.
        CLC
        XCE     ; This is a NOP on a 65C02. C will be set on a 65816.

        ; X = 0 if the CPU is a 65C02.
        LDX     #$00

        ; If carry is clear, the CPU is 65C02, not 65816.
        BCC     @skip_inx

        ; If the CPU is a 65816, carry will be set, and X will be 1.
        INX

@skip_inx:
        XCE     ; Switch into emulation mode. This is a NOP on a 65C02.
        STX     RAM_CPU_TYPE

        ; Pull the prior value of A, pushed before the call to
        ; Continue_System_Init. If this was called from a physical
        ; RESET, $01 is pushed. Otherwise, whatever was in A is pushed.
        PLA
        BEQ     @skip_shadow_vec_init

        ; a RESET has occurred, so initialize all the shadow vectors.
        ; Initialize all shadow vectors to point to an infinite loop.
        ; Done in two passes. This pass sets the LSB of the vector.
        lda     #<Infinite_Loop
        ldx     #$1C
@lsb_loop:
        sta     __SHADOW_VECTORS_LOAD__-2,x
        dex
        dex
        BNE     @lsb_loop

        ; Finish initializing the shadow registers by writing the MSB.
        lda     #>Infinite_Loop
        ldx     #$1C
@msb_loop:
        sta     __SHADOW_VECTORS_LOAD__-1,x
        dex
        dex
        BNE     @msb_loop

@skip_shadow_vec_init:
        ; We're now in the debugging monitor.
        LDA     #$01
        STA     RAM_IN_MONITOR

        ; Store 0 in the location after RAM_IN_MONITOR. Not sure why.
        dec
        STA     RAM_IN_MONITOR+1

        ; Set a pointer to the default BRK handler when in native mode.
        lda     #<BRK_816_Entry_Vector_Default
        sta     BRK_816_ENTRY_VECTOR
        lda     #>BRK_816_Entry_Vector_Default
        STA     BRK_816_ENTRY_VECTOR+1
        
        ; Set a pointer to the default NMI handler when in native mode.
        LDA     #<NMI_816_Entry_Vector_Default
        STA     NMI_816_ENTRY_VECTOR
        LDA     #>NMI_816_Entry_Vector_Default
        STA     NMI_816_ENTRY_VECTOR+1

        ; Set a pointer to the default IRQ entry vector.
        lda     #<IRQ_02_Entry_Vector_Default
        sta     IRQ_02_ENTRY_VECTOR
        lda     #>IRQ_02_Entry_Vector_Default
        STA     IRQ_02_ENTRY_VECTOR+1

        ; Set a pointer to the default NMI entry vector.
        lda     #<NMI_02_Entry_Vector_Default
        sta     NMI_02_ENTRY_VECTOR
        lda     #>NMI_02_Entry_Vector_Default
        STA     NMI_02_ENTRY_VECTOR+1

        jsr     Initialize_System_VIA
        rts

; Saves the first 5 bytes of zero-page memory, and syncs with the debugger,
; allowing it to control the device.
; Upon entry, the CPU will always be in emulation mode.
Save_ZP_Sync_With_Debugger:
        ; Copy the first 5 bytes of ZP to the work area in RAM.
        ldx     #$04
@copy_loop:
        lda     a:DBG_VAR_00,x
        sta     RAM_ZP_SAVE,x
        dex
        BPL     @copy_loop

@begin_debugger_sync:
        ; Read the first snc char from the debugger.
        JSR     Sys_VIA_USB_Char_RX

@check_for_0x55:
        ; If the first sync char is not $55, restart the sync process.
        cmp     #$55
        BNE     @begin_debugger_sync

        ; Read the second cync char from the debugger.
        JSR     Sys_VIA_USB_Char_RX

        ; If the second sync char is not $AA, check for %55.
        CMP     #$AA
        BNE     @check_for_0x55
        
        ; Send a $CC to the debugger.
        lda     #$CC
        JSR     Sys_VIA_USB_Char_TX

        ; Read the command byte from the debugger.
        JSR     Sys_VIA_USB_Char_RX

        ; See if the command is within the supported range. If not,
        ; restart the debugger sync sequence.
        sec
        sbc     #$00
        cmp     #$0A
        BCS     @begin_debugger_sync

        ; Set up a simulated function call to jump to the handler
        ; for the selected debugger command. Multiple the command
        ; by two since each function pointer is two bytes.
        asl
        TAX

        ; Push the address-1 to return to once the command is complete.
        ; We'll return to .begin_debugger_sync:.
        lda     #>(@begin_debugger_sync-1)
        pha
        lda     #<(@begin_debugger_sync-1)
        PHA

        ; Push the jump table address and issue the RTS to call the handler.
        lda     Cmd_Jump_Table+1,x
        pha
        lda     Cmd_Jump_Table,x
        pha
        rts

; Jump table for debugger commands.
Cmd_Jump_Table:
        .WORD   Dbg_Cmd_0_Send_Zero         - 1
        .WORD   Dbg_Cmd_1_Seq_Test          - 1
        .WORD   Dbg_Cmd_2_Write_Mem         - 1
        .WORD   Dbg_Cmd_3_Read_Mem          - 1
        .WORD   Dbg_Cmd_4_Sys_Info          - 1
        .WORD   Dbg_Cmd_5_Exec              - 1
        .WORD   Dbg_Cmd_6_No_Op             - 1
        .WORD   Dbg_Cmd_7_No_Op             - 1
        .WORD   Dbg_Cmd_8_BRK               - 1
        .WORD   Dbg_Cmd_9_Read_Byte_and_BRK - 1

; Debugger command 0. Simply sends $00 to the debugger.
Dbg_Cmd_0_Send_Zero:
        LDA     #$00
        jmp     Sys_VIA_USB_Char_TX

; Debugger command 1: some kind of sequence test. Debugger sends a 16-bit
; count of the bytes to test. The debugger must then send an incrementing
; sequence of bytes, starting at $00 to the monitor. The monitor sends
; back the next expected byte. If the monitor receives a byte it does not
; expect, it enters an infinite loop.
Dbg_Cmd_1_Seq_Test:

        ; DBG_VAR_02 is the next value in the sequence. Start with $00.
        lda     #$00
        STA     a:DBG_VAR_02

       ; Read the LSB of the byte count.
        JSR     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_00

        ; Read the MSB of the byte count.
        jsr     Sys_VIA_USB_Char_RX
        STA     a:DBG_VAR_01

        ; If the byte count is 0, we're done.
        ora     a:DBG_VAR_00
        BEQ     @done

        ; Set up the count's MSB to be 1-based.
        LDA     a:DBG_VAR_00
        beq     @read_next_byte
        INC     a:DBG_VAR_01

@read_next_byte:
        ; Read the next byte in the sequence from the debugger.
        JSR     Sys_VIA_USB_Char_RX

        ; See if the received byte matches the next one in the sequence.
        CMP     a:DBG_VAR_02
        BEQ     @continue

        ; If the sequence is not correct, enter an infinite loop.
@infinite_loop:
        jsr     Do_Nothing_Subroutine_2
        BRA     @infinite_loop
        
@continue:
        ; Send the next byte in the sequence to the debugger.
        inc
        JSR     Sys_VIA_USB_Char_TX

        ; Save the next byte in the sequence.
        INC     a:DBG_VAR_02

        ; Decrement the byte count.
        dec     a:DBG_VAR_00
        bne     @read_next_byte
        dec     a:DBG_VAR_01
        BNE     @read_next_byte

        ; All done with the command.
@done:  rts

; Debugger command 2: write memory. The debugger sends a 24-bit starting
; address, then a 16-bit count, and then the data to write. Memory writes
; to the first 5 bytes of memory are automatically redirected to the save
; area in work-RAM for these memory locations.
Dbg_Cmd_2_Write_Mem:

        ; Read the 24-bit starting address, LSB-first.
        jsr     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_00	; 16-bit addr LSB
        jsr     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_01	; 16-bit addr MSB
        jsr     Sys_VIA_USB_Char_RX
        STA     a:DBG_VAR_02	; bank

        ; Branch if bank is > $00.
        lda     #$00
        cmp     a:DBG_VAR_02
        BCC     @read_byte_count

        ; At this point, bank is $00. Branch if page (16-bit MSB) is > $80.
        lda     #$80
        cmp     a:DBG_VAR_01
        BCC     @read_byte_count

        ; At this point, bank=0, page <= $80. Branch if addr LSB > $00.
        lda     #$00
        cmp     a:DBG_VAR_00
        BCC     @read_byte_count

        ; At this point, bank=0, page <= $80, addr_LSB=0, which is the
        ; first byte of any page in RAM, plus the first page of FLASH,
        ; in bank 0. Now branch if bank <= 1, which is always the case,
        ; since bank is $00 at this point. Why are they doing all this?
        lda     #$01
        cmp     a:DBG_VAR_02
        BCS     @read_byte_count

        ; This code stores $01 in RAM_VAR_7E19, but this code is apparently
        ; never executed. This means RAM_VAR_7E19 will always be $00.
        lda     #$01
        sta     RAM_VAR_7E19
        BRA     @next_addr

@read_byte_count:
        ; Read the 16-bit byte count from the debugger, LSB-first.
        JSR     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_03
        jsr     Sys_VIA_USB_Char_RX
        STA     a:DBG_VAR_04

        ; If the tranfer count is 0, cleanup and return.
        ora     a:DBG_VAR_03
        BEQ     @cleanup

        ; Set the MSB of the transfer count to be 1-based.
        ldy     #$00
        lda     a:DBG_VAR_03
        beq     @transfer_byte
        INC     a:DBG_VAR_04

@transfer_byte:
        ; If the address is not in the first bank and first page, then
        ; transfer the memory contents from the actual memory location.
        lda     a:DBG_VAR_01
        ora     a:DBG_VAR_02
        BNE     @transfer_byte_from_real_addr

        ; Now see if the address is within the first five bytes of RAM.
        ; This address is used for debugger command parameters.
        lda     a:DBG_VAR_00
        cmp     #$05
        BCS     @transfer_byte_from_real_addr

        ; The address is within the 5-byte debugger area in the zero-
        ; page. First, read the byte from the debugger to write.
        tay
        JSR     Sys_VIA_USB_Char_RX

        ; Now save the byte into the save area in work-RAM.
        STA     RAM_ZP_SAVE,y

        ; Move to the next byte to transfer.
        ldy     #$00
        BEQ     @next_addr

@transfer_byte_from_real_addr:
        ; Read the byte to write from the debugger.
        JSR     Sys_VIA_USB_Char_RX

        ; See if we're running on a 65C02 or a 65816.
        ldx     RAM_CPU_TYPE
        BNE     @cpu_is_65816

        ; For the 65C02, ignore the bank, and only use the 16-bit addr.
        sta     (DBG_VAR_00),y
        BEQ     @next_addr

@cpu_is_65816:
        ; Use the ZP-indirect-long mode to write to the full 24-bit addr.
        STA     [0]

@next_addr:
        ; Move to the next address.
        INC     a:DBG_VAR_00
        bne     @dec_count
        inc     a:DBG_VAR_01
        bne     @dec_count
        INC     a:DBG_VAR_02

@dec_count:
        ; Decrement the transfer count, and see if we're done.
        DEC     a:DBG_VAR_03
        bne     @transfer_byte
        dec     a:DBG_VAR_04
        BNE     @transfer_byte

@cleanup:
        ; Clear RAM_VAR_7E19 for some unknown reason. But it would never
        ; get set in the first place, so this code seems unnecessary.
        LDA     RAM_VAR_7E19
        beq     @done
        STZ     RAM_VAR_7E19

@done:  rts

; Debugger command 3: read memory. The debugger sends a 24-bit starting
; address, then a 16-bit count. and then the monitor sends the request
; memory contents to the debugger. Memory reads to the first 5 bytes of
; memory are automatically redirected to the save area in work-RAM for
; these memory locations.
Dbg_Cmd_3_Read_Mem:
        ; Read the 24-bit starting address, LSB-first.
        jsr     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_00	; 16-bit LSB
        jsr     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_01	; Page
        jsr     Sys_VIA_USB_Char_RX
        STA     a:DBG_VAR_02	; Bank

        ; Read the 16-bit byte count, LSB-first.
        jsr     Sys_VIA_USB_Char_RX
        sta     a:DBG_VAR_03	; Count LSB
        jsr     Sys_VIA_USB_Char_RX
        STA     a:DBG_VAR_04	; Count MSB

        ; If the byte count is 0, then we're done.
        ora     a:DBG_VAR_03
        BEQ     @done

        ; Set up the count MSB to be 1-based.
        ldy     #$00
        lda     a:DBG_VAR_03
        beq     @transfer_byte
        INC     a:DBG_VAR_04

@transfer_byte:
        ; If the address is not in the first bank and first page, then
        ; transfer the memory contents from the actual memory location.
        lda     a:DBG_VAR_01
        ora     a:DBG_VAR_02
        BNE     @transfer_byte_from_real_addr

        ; Now see if the address is within the first five bytes of RAM.
        ; This address is used for debugger command parameters.
        lda     a:DBG_VAR_00
        cmp     #$05
        BCS     @transfer_byte_from_real_addr

        ; The address is within the 5-byte debugger area in the zero-page,
        ; so send the contents of the save area in RAM to the debugger.
        tay
        LDA     RAM_ZP_SAVE,y

        ; Move to the next byte to transfer.
        ldy     #$00
        BEQ     @next_addr

@transfer_byte_from_real_addr:
        ; See if we're running on a 65C02 or a 65816.
        lda     RAM_CPU_TYPE
        BNE     @cpu_is_65816

        ; For the 65C02, ignore the bank, and only use the 16-bit addr.
        lda     (DBG_VAR_00),y
        BRA     @next_addr

@cpu_is_65816:
        ; Use the ZP-indirect-long mode to read from the full 24-bit addr.
        LDA     [0]

@next_addr:
        ; Send the byte read from memory to the debugger.
        JSR     Sys_VIA_USB_Char_TX

        ; Move to the next address.
        inc     a:DBG_VAR_00
        bne     @dec_count
        inc     a:DBG_VAR_01
        bne     @dec_count
        INC     a:DBG_VAR_02

@dec_count:
        ; Decrement the transfer count, and see if we're done.
        DEC     a:DBG_VAR_03
        bne     @transfer_byte
        dec     a:DBG_VAR_04
        BNE     @transfer_byte

@done:  rts

; Debugger command 4. Get System Info.
Dbg_Cmd_4_Sys_Info:
        ; Send the start of the monitor work-RAM. This same address is also sent
        ; later, for some reason. Not sure if these represent two different things
        ; which happen to have the same address, but each one seems to be used. If
        ; this copy is changed to something invalid, the debugger has issues, so it
        ; seems to be used by the debugger, and not ignored.
        lda     #<__WORK_RAM_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__WORK_RAM_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #^__WORK_RAM_LOAD__
        JSR     Sys_VIA_USB_Char_TX

        ; Auto-detected CPU type.
        lda     RAM_CPU_TYPE
        JSR     Sys_VIA_USB_Char_TX

        ; Board ID.
        lda     #BOARD_ID
        JSR     Sys_VIA_USB_Char_TX

        ; Send the work-RAM start address again. Not sure why, but this copy is
        ; the value that is displayed in the "Target Connection Information"
        ; screen on the debugger, so this copy is used, and not ignored.
        lda     #<__WORK_RAM_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__WORK_RAM_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        LDA     #^__WORK_RAM_LOAD__
        jsr     Sys_VIA_USB_Char_TX

        ; Send the monitor starting address.
        lda     #<__MONITOR_HEADER_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__MONITOR_HEADER_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #^__MONITOR_HEADER_LOAD__
        JSR     Sys_VIA_USB_Char_TX

        ; Shadow vector start (24-bit address, LSB-first).
        lda     #<__SHADOW_VECTORS_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        LDA     #>__SHADOW_VECTORS_LOAD__
        JSR     Sys_VIA_USB_Char_TX
        lda     #^__SHADOW_VECTORS_LOAD__
        JSR     Sys_VIA_USB_Char_TX

        ; Shadow vector end address + 1.
        lda     #<(__SHADOW_VECTORS_LOAD__ + __SHADOW_VECTORS_SIZE__)
        jsr     Sys_VIA_USB_Char_TX
        lda     #>(__SHADOW_VECTORS_LOAD__ + __SHADOW_VECTORS_SIZE__)
        jsr     Sys_VIA_USB_Char_TX
        LDA     #^(__SHADOW_VECTORS_LOAD__ + __SHADOW_VECTORS_SIZE__)
        jsr     Sys_VIA_USB_Char_TX

        ; Send the hardware vector address.
        lda     #<__CPU_VECTORS_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__CPU_VECTORS_LOAD__
        jsr     Sys_VIA_USB_Char_TX
        LDA     #^__CPU_VECTORS_LOAD__
        jsr     Sys_VIA_USB_Char_TX

        ; Send the hardware base IO address.
        lda     #<__HW_IO_ADDR__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__HW_IO_ADDR__
        jsr     Sys_VIA_USB_Char_TX
        LDA     #^__HW_IO_ADDR__
        jsr     Sys_VIA_USB_Char_TX

        ; Not sure, but assume this is the last byte of the hardware IO area.
        lda     #<(__HW_IO_ADDR__ + __HW_IO_SIZE__ - 1)
        jsr     Sys_VIA_USB_Char_TX
        lda     #>(__HW_IO_ADDR__ + __HW_IO_SIZE__ - 1)
        jsr     Sys_VIA_USB_Char_TX
        LDA     #^(__HW_IO_ADDR__ + __HW_IO_SIZE__ - 1)
        jsr     Sys_VIA_USB_Char_TX

        ; Send the hardware breakpoint address.
        lda     #<__HW_BRK_ADDR__
        jsr     Sys_VIA_USB_Char_TX
        lda     #>__HW_BRK_ADDR__
        jsr     Sys_VIA_USB_Char_TX
        lda     #^__HW_BRK_ADDR__
        jmp     Sys_VIA_USB_Char_TX

; Debugger command 5. Restore the CPU context and execute from the saved context.
Dbg_Cmd_5_Exec:

        ; Restore the user's state of the VIA's PCR register.
        JSR     Restore_VIA_PCR_State

        ; Restore the 5 zero-page variables from the copies in work-RAM.
        LDX     #$04
@copy_zp_var:
        lda     RAM_ZP_SAVE,x
        sta     a:DBG_VAR_00,x
        dex
        BPL     @copy_zp_var

        ; See if the CPU was running in emulation mode.
        lda     RAM_E_SAVE
        BEQ     @was_in_native_mode

        ; The CPU was in emulation mode. Restore the CPU context. Start off
        ; by restoring the stack and the index registers.
        ldx     RAM_SP_SAVE
        txs
        ldx     RAM_X_SAVE
        LDY     RAM_Y_SAVE

        ; See what CPU type we're running.
        lda     RAM_CPU_TYPE
        BNE     @cpu_is_65816

        ; CPU is 65C02. The below code pushes the saved direct-page contents
        ; onto the stack. Not sure why, since in emulation mode, these will
        ; always both be 0.
        lda     RAM_DP_SAVE+1
        pha
        lda     RAM_DP_SAVE
        PHA

        ; Pull the direct-page register from the stack. But, since this is
        ; running on a 65C02, this will actually be a no-op. Seems like the
        ; stack will have two extra bytes on it (the direct page). Why?!?
        PLD

@cpu_is_65816:
        ; Set up a simulated ISR on the stack.
        LDA     RAM_PC_SAVE+1
        pha
        lda     RAM_PC_SAVE
        pha
        lda     RAM_P_SAVE
        PHA

        ; We're no longer in the ROM monitor since we're going to execute user code.
        lda     #$00
        STA     RAM_IN_MONITOR

        ; Restore the A register.
        LDA     RAM_A_SAVE

        ; Perform an RTI, restoring the CPU context as it was.
        rti

@was_in_native_mode:
        ; Set the CPU to native mode.
        CLC
        XCE

        ; Set XY to 16-bit, and A to 8-bit. The assembler is already in 8-bit for A.
        SEP     #$20
        REP     #$10
.I16

        ; Restore the 16-bit stack and Direct Page registers.
        ldx     RAM_SP_SAVE
        txs
        ldx     RAM_DP_SAVE
        phx
        PLD

        ; Set up a simulated ISR on the stack.
        lda     RAM_PB_SAVE
        pha
        ldx     RAM_PC_SAVE
        phx
        lda     RAM_P_SAVE
        pha
        ldx     RAM_X_SAVE
        LDY     RAM_Y_SAVE

        ; We're no longer in the ROM monitor since we're going to execute user code.
        lda     #$00
        STA     RAM_IN_MONITOR

        ; Restore the data bank register.
        lda     RAM_DB_SAVE
        pha
        PLB

        ; Set A to 16-bit mode.
        REP     #$20
.A16

        ; Restore the 16-bit A register.
        LDA     f:RAM_A_SAVE

        ; Perform an RTI, restoring the CPU context as it was.
        RTI

        ; This is the end of the subroutine. The CPU will switch to emulation/native,
        ; and 8/16 bit A/XY according to E and P stored on the stack, but we need to
        ; put the assembler back in 8-bit mode since the following code is always
        ; executed in 8-bit mode.
.A8
.I8

; Debugger commands 6 and 7. They do nothing.
Dbg_Cmd_6_No_Op:
Dbg_Cmd_7_No_Op:

        ; Return, making this debug command a no-op.
        rts

        ; This code is apparently never called.
        jmp     Sys_VIA_USB_Char_TX
        lda     #$25
        bra     Dbg_Cmd_8_Done
        PLD
        stx     $A9
        bra     @branch
@branch:
        JSR     Sys_VIA_USB_Char_TX
        ; See notes for Dbg_Cmd_8_BRK about 8-bit LDA and BRK vs. 16-bit LDA.
        LDA     #$00
        BRK     ; Single-byte BRK instruction.
        jmp     Sys_VIA_USB_Char_TX

; Debugger command 8. Executes a BRK instruction, causing the monitor to send
; a $02 to the debugger, as it normally does when a BRK is executed. Not sure why
; this debugger command exists, or how/if it is useful at all.
Dbg_Cmd_8_BRK:
        jsr     @clear_carry
        BCC     @on_carry_clear

        ; The following code is apparently never executed. See notes below
        ; regarding an 8-bit immediate LDA and BRK vs. a 16-bit immediate LDA.
        LDA     #$01
        BRK     ; Single-byte BRK instruction.
        jmp     Sys_VIA_USB_Char_TX

@on_carry_clear:

        ; Perform an 8-bit immediate load, and generate a BRK. The BRK in this
        ; case is only a single byte, instead of two bytes which is typical.
        ; This could also be interpreted as a 16-bit immediate load of $0000,
        ; but since the CPU is always in emulation mode when this code is
        ; executed, it is clearer to write it as an 8-bit load and a BRK.
        LDA     #$00
        BRK     ; Single-byte BRK instruction.

        ; This is not executed because of the BRK above.
        jmp     Sys_VIA_USB_Char_TX

@clear_carry:
        CLC

Dbg_Cmd_8_Done:
        RTS

; Debugger command 9. Reads a byte from the debugger, and then executes a BRK
; instruction, which then sends a $02 to the debugger. Not sure why this
;debugger command exists, or how/if it is useful at all.
Dbg_Cmd_9_Read_Byte_and_BRK:
        ; Read a data byte from the debugger.
        JSR     Sys_VIA_USB_Char_RX

        jsr     @clear_carry
        BCC     @on_carry_clear

        ; The following code is apparently never executed. See DBG_CMD_8_BRK
        ; regarding an 8-bit immediate LDA and BRK vs. a 16-bit immediate LDA.
        LDA     #$01
        BRK     ; Single-byte BRK instruction.
        jmp     Sys_VIA_USB_Char_TX

@on_carry_clear:
        ; The following code is apparently never executed. See DBG_CMD_8_BRK
        ; regarding an 8-bit immediate LDA and BRK vs. a 16-bit immediate LDA.
        LDA     #$00
        BRK     ; Single-byte BRK instruction.

        ; This is not executed because of the BRK above.
        jmp     Sys_VIA_USB_Char_TX

@clear_carry:
        CLC
        rts

; The default handler for IRQ when in '02 emulation mode.
; At this point, we are in emulation mode, so A and XY are in 8-bit mode.
IRQ_02_Entry_Vector_Default:
        PHA     ; Save the LSB of A on the stack.

        ; We're now executing the ROM monitor code.
        lda     #$01
        STA     f:RAM_IN_MONITOR
        PHX     ; Save X on the stack.

        ; Get the pushed P (status reg). This includes the B flag which
        ; was pushed. We're in '02 mode, so we know the stack is at $100.
        tsx
        lda     $103,x
        PLX

        ; See if the pushed copy of B is set, indicating a BRK vs IRQ.
        and     #$10
        BNE     @on_BRK

        ; An IRQ was received. Clean up the stack and call the user's
        ; IRQ vector through the shadow vector at $7EFE.
        lda     #$00
        STA     f:RAM_IN_MONITOR        ; No longer in ROM monitor code.

        pla
        jmp     (SHADOW_VEC_IRQ_02)

; Called when a BRK instruction is executed.
@on_BRK:
        ; Set RAM_ENTER_MONITOR_REASON to 2, indicating a BRK was executed.
        LDA     #$02
        jmp     Save_Context_Enter_Monitor_02_Mode

; The default handler for NMI when in '02 emulation mode.
NMI_02_Entry_Vector_Default:
        PHA     ; Save the LSB of A on the stack.

        ; See if we were running monitor code or user code.
        LDA     f:RAM_IN_MONITOR
        BNE     @was_running_monitor_code

        ; We were running user code, but now we're in the monitor.
        lda     #$01
        STA     f:RAM_IN_MONITOR

        ; Set RAM_ENTER_MONITOR_REASON to 7, indicating an NMI was generated.
        lda     #$07
        BRA     Save_Context_Enter_Monitor_02_Mode
        
@was_running_monitor_code:
        ; An NMI ocurred while running the monitor code. Ignore it by
        ; restoring the context and returning from the interrupt.
        pla
        rti

; Called while in '02 emulation mode to save the CPU context and
; then enter the ROM monitor.
;
; On entry, A must contain the reason the monitor will be entered.
Save_Context_Enter_Monitor_02_Mode:

        ; Enter native mode.
        BRA     @enter_native_mode

        ; The above is not a subroutine call, so it does not return.
        ; I don't think the following code is ever executed. Instead,
        ; the BRA above switches the CPU into native mode, and then
        ; the native-mode routine is called to save the CPU context.

        ; Save the reason we're entering the monitor into work-RAM.
        STA     RAM_ENTER_MONITOR_REASON

        ; Save the 8-bit CPU context into work-RAM.
        pla
        sta     RAM_A_SAVE
        stx     RAM_X_SAVE
        sty     RAM_Y_SAVE
        pla
        sta     RAM_P_SAVE
        pla
        sta     RAM_PC_SAVE
        pla
        STA     RAM_PC_SAVE+1

        ; We were in 6502 mode, so save 0 to the bank registers and
        ; the high bytes of the 16-bit registers.
        stz     RAM_PB_SAVE
        stz     RAM_DB_SAVE
        stz     RAM_DP_SAVE
        stz     RAM_DP_SAVE+1
        stz     RAM_A_SAVE+1
        stz     RAM_X_SAVE+1
        STZ     RAM_Y_SAVE+1

        ; Save the LSB (8-bits) of the stack to work-RAM.
        tsx
        STX     RAM_SP_SAVE

        ; We know we're in emulation mode, so save "1" to the high-byte
        ; of the stack pointer and the E(mulation) flag save area.
        lda     #$01
        sta     RAM_SP_SAVE+1
        STA     RAM_E_SAVE

        ; Per the comments above, I don't think this is ever actually
        ; called from here. Another reason is that the subroutine expects
        ; the CPU to be in emulation mode, and if this code were to be
        ; executed, it would be in we're in native mode now.
        JMP     Send_Enter_Reason_and_Sync_With_Debugger

@enter_native_mode:
        ; Switch to native mode.
        CLC
        XCE

        ; Set XY and A to 8-bit mode. The assembler is already in 8-bit mode.
        SEP     #$30

        ; Save the reason we're entering the monitor into work-RAM.
        STA     f:RAM_ENTER_MONITOR_REASON

        ; We were previously in emulation mode, so indicate this.
        LDA     #$1
        STA     f:RAM_E_SAVE

        ; Save the CPU context and enter the ROM monitor.
        JMP     Save_Context_Enter_Monitor

; Unless the user overrides the default vector, then this is called
; when a BRK instruction is executed while in 816 native mode.
BRK_816_Entry_Vector_Default:
        ; Set the A register to 8-bit mode and push the low part of it.
        ; The assembler is already in 8-bit mode, so no need for .A8.
        SEP     #$20
        PHA

        ; We're now running monitor code.
        lda     #$01
        STA     f:RAM_IN_MONITOR

        ; Set RAM_ENTER_MONITOR_REASON to 2, indicating a BRK was executed.
        lda     #$02
        BRA     Save_Context_Enter_Monitor_816_Mode_With_Reason

; Unless the user overrides the default vector, then this is called
; upon an NMIA while the CPU is in 816 native mode.
NMI_816_Entry_Vector_Default:
        ; Set the A register to 8-bit mode and push the low part of it.
        ; The assembler is already in 8-bit mode, so no need for .A8.
        SEP     #$20
        PHA

        ; See if we were running monitor code when the NMI ocurred.
        LDA     f:RAM_IN_MONITOR
        BNE     @was_running_monitor_code

        ; We're now running monitor code.
        lda     #$01
        STA     f:RAM_IN_MONITOR

        ; Set RAM_ENTER_MONITOR_REASON to 7, indicating an NMI was generated.
        lda     #$07
        BRA     Save_Context_Enter_Monitor_816_Mode_With_Reason

@was_running_monitor_code:
        ; An NMI ocurred while running the monitor code. Ignore it by
        ; restoring the context and returning from the interrupt.
        pla
        rti

; Called while in 816 native mode to save the CPU context and
; then enter the ROM monitor.
Save_Context_Enter_Monitor_816_Mode_With_Reason:
        SEP     #$20    ; Set the A register to 8-bit mode.
        ; The assembler is already in 8-bit mode, so no need for .A8.

        ; Save the reason we're entering the monitor into work-RAM.
        STA     f:RAM_ENTER_MONITOR_REASON

        ; We were previously in 816 native mode, so indicate this.
        lda     #$00
        STA     f:RAM_E_SAVE

; Saves the CPU context and enters the ROM monitor, syncing with the debugger.
; This code is ultimately used by the BRK and NMI handlers in both native and
; emulation mode (after switching to native mode).
;
; Upon entry, the CPU must be in native 816 mode, with A set to 8-bit mode,
; with the low 8-bits of A already pushed to the stack.
Save_Context_Enter_Monitor:
        ; Save the LSB of A into work-RAM.
        PLA
        STA     f:RAM_A_SAVE

        ; Save the MSB of A into work-RAM.
        XBA
        STA     f:RAM_A_SAVE+1

        ; Save the data bank into work-RAM.
        PHB
        pla
        STA     f:RAM_DB_SAVE

        ; Switch to data bank 0.
        lda     #$00
        pha
        PLB

        ; Save 0 into the program bank save area in work-RAM. This value will
        ; remain if the CPU was in emulation mode, but it will be overwritten
        ; with the correct value later if the CPU was in native mode.
        STA     f:RAM_PB_SAVE

        ; Save the CPU status register to the area in work-RAM.
        pla
        STA     f:RAM_P_SAVE

        ; Set 16-bit A and XY registers.
        REP     #$30
.I16
.A16

        ; Save the direct-page register to the save area in work-RAM.
        TDC
        STA     f:RAM_DP_SAVE

        ; Set the direct-page register to page 0. This is a 16-bit load.
        lda     #$00
        TCD

        ; Save the X and Y registers (all 16-bits each) to work-RAM.
        stx     RAM_X_SAVE
        STY     RAM_Y_SAVE

        ; Pull the 16-bit PC and save it to work RAM.
        pla
        STA     RAM_PC_SAVE

        ; Set A to 8-bit mode.
        SEP     #$20
.A8

        ; See if the CPU was in '02 '816 mode when it was interrupted.
        LDA     RAM_E_SAVE
        BNE     @was_in_emulation_mode

        ; The CPU was in native mode. Pull the program bank and save it.
        pla
        STA     RAM_PB_SAVE

@was_in_emulation_mode:
        ; Save all 16-bits of the stack pointer. If the CPU was in emulation
        ; mode, the MSB will be saved as "1".
        tsx
        STX     RAM_SP_SAVE

        ; Set 8-bit XY registers. At this point, A and XY are both 8-bit.
        SEP     #$10
.I8

        ; The user's CPU context is now fully saved into work-RAM. Switch
        ; back into emulation mode.
        SEC
        XCE

; Sends the reason the monitor (debugger) was entered, and then syncs
; with the debugger, allowing the debugger to control the device.
Send_Enter_Reason_and_Sync_With_Debugger:

        ; Save the state of the system VIA's PCR so it can be restored later.
        JSR     Save_VIA_PCR_State

        ; Send the reason we entered the monitor to the debugger.
        LDA     RAM_ENTER_MONITOR_REASON
        JSR     Sys_VIA_USB_Char_TX

        ; Save the first five zero-page values, and sync with debugger.
        JMP     Save_ZP_Sync_With_Debugger

; Called in emulation mode upon system reset.
; Initializes the system VIA (the USB debugger), and syncs with the USB chip.
Initialize_System_VIA:

        ; Disable PB7, shift register, timer T1 interrupt.
        lda     #$00
        STA     SYSTEM_VIA_ACR

        ; Cx1/Cx2 as inputs with negative active edge, for both ports. These
        ; aren't used for the system VIA debugging interface, but the Cx2
        ; lines are connected to the FLASH, and they select the bank. Setting
        ; them as inputs allows the pullups to automatically select the bank
        ; which contains the factory-programmed FLASH bank with the monitor.
        lda     #$00
        STA     SYSTEM_VIA_PCR

        ; Save the PCR in work-RAM so it can be restored later.
        STA     RAM_PCR_SAVE

        ; Preset port B output for $18 (TUSB_RDB and PB4-not-connected high).
        lda     #$18
        STA     SYSTEM_VIA_IOB

        ; Set PB2 (TUSB_WR), PB3 (TUSB_RDB), and PB4 (N.C.) as outputs. This
        ; has the effect of writing $FF to the USB FIFO when the RESET button
        ; is pressed. When RESET is pressed, it causes the system VIA to output
        ; high on TUSB_WR, then when this write sets TUSB_WR low, the high-to-
        ; low transition on TUSB_WR triggers a write to the USB FIFO. At this
        ; point, port A (the USB FIFO data lines) are not being driven, and
        ; either float high, or are pulled high internally, because this
        ; triggers a write of $FF to the USB FIFO.
        lda     #$1C
        STA     SYSTEM_VIA_DDRB

        ; Save DDRB in work-RAM. Not sure why, since it is never used again.
        STA     RAM_DDRB_SAVE

        ; Set all IO on port A to inputs.
        LDA     #$00
        STA     SYSTEM_VIA_DDRA

        ; Save DDRA in work-RAM. Not sure why, since it is never used again.
        STA     RAM_DDRA_SAVE

        ; Read port B (USB status and control lines) and save it on the stack.
        lda     SYSTEM_VIA_IOB
        PHA

        ; Mask out bit 4, which is not connected.
        AND     #$EF

        ; Write the result back. Not sure why since only bit 4 changes, and
        ; it is not connected (according to schematic rev. C, Dec. 15, 2020).
        STA     SYSTEM_VIA_IOB

        ; Delay for $5D*256 loop cycles.
        LDX     #$5D
        JSR     Delay_Loop

        ; Pull the original port B value, and write it back to the port.
        PLA
        STA     SYSTEM_VIA_IOB

        ; Wait until PB5 (TUSB_PWRENB) goes low, indicating it's powered up.
        lda     #$20
@loop:  bit     SYSTEM_VIA_IOB
        BNE     @loop

        ; If PB6 (not connected) is 0, then make a no-op call. Why?!?
        LDA     SYSTEM_VIA_IOB
        and     #$40
        BEQ     Do_Nothing_Subroutine_1

        ; All done.
        RTS

; Returns 1 in A if there is data available to be read, 0 if not.
Is_VIA_USB_RX_Data_Avail:

        ; Set all bits on port A to inputs.
        LDA     #$00
        STA     SYSTEM_VIA_DDRA

        ; See if PB1 (TUSB_RXFB) is high.
        LDA     #$02
        bit     SYSTEM_VIA_IOB
        bne     @not_zero

        ; It is low, meaning there is data available to read.
        LDA     #$01
        RTS

@not_zero:
        ; It is high, meaning there is no data available to read.
        LDA     #$00
        RTS

; Waits for a byte to be ready on the USB FIFO and then reads it, returning
; the value read in the A register.
Sys_VIA_USB_Char_RX:
        ; Set all bits on port A to inputs.
        lda     #$00
        STA     SYSTEM_VIA_DDRA

        ; Set up to test PB1 (TUSB_RXFB).
        LDA     #$02

        ; Wait for PB1 (TUSB_RXFB) to be low. This indicates data can be
        ; read from the FIFO by strobing PB3 low then high again.
@wait_for_rxfb_low:
        bit     SYSTEM_VIA_IOB
        BNE     @wait_for_rxfb_low

        ; Perform a read-modify-write on port B, clearing PB3 (TUSB_RDB).
        ; This triggers the FIFO to drive the received byte on port A.
        lda     SYSTEM_VIA_IOB
        ora     #$08    ; Save a copy of port B with PB3 set high.
        tax     ; This will be used later.
        and     #$F7
        STA     SYSTEM_VIA_IOB

        ; Wait for the FIFO to drive the data and the lines to settle
        ; (between 20ns and 50ns, according to the datasheet).
        nop
        nop
        nop
        NOP

        ; Read the data byte from the FIFO on port A.
        LDA     SYSTEM_VIA_IOA

        ; Restore the original value of port B, while setting PB3 high again.
        stx     SYSTEM_VIA_IOB

        ; We're done. The byte read is in A.
        RTS

        ; Apparently unused code.
        lda     #$EE
        rts

; Sends the byte stored in A to the debugger, waiting until it can be sent.
Sys_VIA_USB_Char_TX:

        ; Set all bits on port A to inputs.
        ldx     #$00
        STX     SYSTEM_VIA_DDRA

        ; Write register A to port A. This has no effect on the actual
        ; output pin until port A is set as an output.
        STA     SYSTEM_VIA_IOA

        ; Set up register A to test port B, bit 0 (TUSB_TXEB).
        LDA     #$01

        ; Wait for PB0 (TUSB_TXEB) to be low. This indicates data can be
        ; written to the FIFO by strobing PB2 (TUSB_WR) high then low.
@wait_for_txeb_low:
        bit     SYSTEM_VIA_IOB
        BNE     @wait_for_txeb_low

        ; Perform a read-modify-write on port B, setting bit 2 (TUSB_WR).
        ; Save the original value in X temporarily.
        lda     SYSTEM_VIA_IOB
        AND     #$FB	; Save a copy of port B with PB2 low.
        TAX
        ora     #$04	; Set PB2 high.
        STA     SYSTEM_VIA_IOB

        ; Set all bits on port A to outputs. This causes the pin outputs
        ; to be set to what we wrote to port A earlier in the subroutine.
        lda     #$FF
        STA     SYSTEM_VIA_DDRA

        ; Wait for the port A outputs to settle. The datasheet says this
        ; must be held at least 20 ns before PB2 (TUSB_WR) is brought low.
        NOP
        NOP

        ; Write the original port B value back, setting PB2 back to low.
        STX     SYSTEM_VIA_IOB

        ; Read port A. But why? The values read should be the actual
        ; values driven on the pins, which may not be what we commanded
        ; them to if, for example, they are heavily loaded. This value
        ; is returned in the A register, and could be examined by the
        ; caller. But this is not used anywhere in the monitor.
        LDA     SYSTEM_VIA_IOA

        ; Set all bits in port A as inputs.
        ldx     #$00
        STX     SYSTEM_VIA_DDRA

        ; All done.
        rts

; A subroutine which does absolutely nothing.
Do_Nothing_Subroutine_1:
        rts

; Delays by looping 256*X times.
Delay_Loop:
        phx
        ldx     #$00
@loop_256_times:
        dex
        bne     @loop_256_times
        plx
        dex
        bne     Delay_Loop
        rts

; Saves the current VIA PCR state into work-RAM. This is done after running
; user code, and before modifying PCR once returning to the monitor. This is
; necessary in case the user modifies PCR, for example, to control the active
; banks on the FLASH.
Save_VIA_PCR_State:
        lda     SYSTEM_VIA_PCR
        sta     RAM_PCR_SAVE
        rts

; Restores the state of the system VIA's PCR register to what it was when
; the monitor interrupted the user's code.
Restore_VIA_PCR_State:
        lda     RAM_PCR_SAVE
        sta     SYSTEM_VIA_PCR
        rts

; The second subroutine which does absolutely nothing.
Do_Nothing_Subroutine_2:
        rts

; The third subroutine which does absolutely nothing.
Do_Nothing_Subroutine_3:
        rts
        rts
        rts
        RTS

        .segment "CPU_VECTORS"

        ; 65816 Native-Mode Vectors
COP_816:    .addr   COP_816_entry       ; $FFE4
BRK_816:    .addr   BRK_816_entry       ; $FFE6
ABORT_816:  .addr   ABORT_816_entry     ; $FFE8
NMI_816:    .addr   NMI_816_entry       ; $FFEA
RSVD_FFEC:  .addr   Infinite_Loop_2     ; $FFEC
IRQ_816:    .addr   IRQ_816_entry       ; $FFEE

        ; 65C02 Emulation-Mode Vectors
RSVD_FFF0:  .addr   Infinite_Loop       ; $FFF0
RSVD_FFF2:  .addr   Infinite_Loop       ; $FFF2
COP_02:     .addr   COP_02_entry        ; $FFF4
RSVD_FFF6:  .addr   Infinite_Loop       ; $FFF6
ABORT_02:   .addr   ABORT_02_entry      ; $FFF8
NMI_02:     .addr   NMI_02_entry        ; $FFFA
RESET:      .addr   RESET_entry         ; $FFFC
IRQ_02:     .addr   IRQ_02_entry        ; $FFFE