; Define port addresses
PORTB = 0x6000  ; Port B address
PORTA = 0x6001  ; Port A address
DDRB  = 0x6002  ; Data Direction Register for Port B
DDRA  = 0x6003  ; Data Direction Register for Port A
T1CL = 0x6004   ; Timer 1 Counter Low
T1CH = 0x6005   ; Timer 1 Counter High
ACR = 0x600B    ; Auxiliary Control Register

; Reset 
    .org 0x8000      ; Set reset vector starting location

reset:
    lda #0b11111111   ; Set all bits of Port A to output
    sta DDRA
    lda #0 
    sta PORTA
    sta ACR

loop:
    inc PORTA
    jsr delay
    dec PORTA
    jsr delay
    jmp loop

delay 
    ldy #0xff
delay2
    ldx #0xff
delay1
    nop
    dex
    bne delay1
    dey
    bne delay2
    rts    


    .org 0xfffc
    .word reset
    .word 0x0000
