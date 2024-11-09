; Define port addresses
PORTB = 0x6000  ; Port B address
PORTA = 0x6001  ; Port A address
DDRB  = 0x6002  ; Data Direction Register for Port B
DDRA  = 0x6003  ; Data Direction Register for Port A

MOSI =  0b00000001
SCK  =  0b00000010
MISO =  0b00000100
CS   =  0b00001000


; Reset 
    .org 0x8000      ; Set reset vector starting location

reset:
    ; Initialize SPI
    lda #CS
    sta PORTA

    lda #0b00001011 ; /nc/nc/nc/nc/cs/miso/sck/mosi
    sta DDRA

    ; begin bit bang 0xd0

    ;1
    lda #MOSI
    sta PORTA
    lda #(SCK | MOSI)
    sta PORTA

    ;1
    lda #MOSI
    sta PORTA
    lda #(SCK | MOSI)
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;1
    lda #MOSI
    sta PORTA
    lda #(SCK | MOSI)
    sta PORTA
    
    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ; end bit bang 0xd0
    ; send anther byte 0x00
    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    ;0
    lda #0
    sta PORTA
    lda #SCK
    sta PORTA

    lda #CS
    sta PORTA



    .org 0xfffc
    .word reset
    .word 0x0000
