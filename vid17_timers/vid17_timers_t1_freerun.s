; Define port addresses
PORTB = $6000  ; Port B address
PORTA = $6001  ; Port A address
DDRB  = $6002  ; Data Direction Register for Port B
DDRA  = $6003  ; Data Direction Register for Port A
T1CL = $6004   ; Timer 1 Counter Low
T1CH = $6005   ; Timer 1 Counter High
ACR = $600B    ; Auxiliary Control Register
IFR = $600D ; Interrupt Flag Register
IER = $600E ; Interrupt Enable Register

ticks = $00
toggle_time = $04

; Reset 
    .org $8000      ; Set reset vector starting location

reset:
    lda #%01111111   ; Set all bits of Port A to output
    sta DDRA
    lda #0 
    sta PORTA
    jsr init_timer

loop:
    sec
    lda ticks
    sbc toggle_time
    cmp #25
    bcc loop

    lda #$01
    eor PORTA
    sta PORTA
    lda ticks
    sta toggle_time
    jmp loop

init_timer:
    lda #$00
    sta toggle_time
    sta ticks
    sta ticks + 1
    sta ticks + 2
    sta ticks + 3

    lda #%01000000 ; Set Timer 1 to free run mode
    sta ACR 
    lda #$0E 
    sta T1CL 
    lda #$27
    sta T1CH

    lda #%11000000 ; Enable Timer 1 interrupt
    sta IER
    cli
    rts
    
delay1:
    bit IFR
    bvc delay1
    lda T1CL
    rts 

irq:    
    bit T1CL
    inc ticks
    bne end_irq
    inc ticks + 1
    bne end_irq
    inc ticks + 2
    bne end_irq
    inc ticks + 3
    bne end_irq 

end_irq:
    rti

    .org $fffc
    .word reset
    .word irq
