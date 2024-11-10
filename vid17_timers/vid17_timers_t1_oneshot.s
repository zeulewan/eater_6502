; Define port addresses
PORTB = $6000  ; Port B address
PORTA = $6001  ; Port A address
DDRB  = $6002  ; Data Direction Register for Port B
DDRA  = $6003  ; Data Direction Register for Port A
T1CL = $6004   ; Timer 1 Counter Low
T1CH = $6005   ; Timer 1 Counter High
ACR = $600B    ; Auxiliary Control Register
IFR = $600D ; Interrupt Flag Register


; Reset 
    .org $8000      ; Set reset vector starting location

reset:
    lda #%11111111   ; Set all bits of Port A to output
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

delay:
    lda #$ff
    sta T1CL
    lda #$ff
    sta T1CH
    
delay1:
    bit IFR
    bvc delay1
    lda T1CL
    rts 

    .org $fffc
    .word reset
    .word $0000
