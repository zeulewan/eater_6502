; Define port addresses
PORTB = 0x6000  ; Port B address
PORTA = 0x6001  ; Port A address
DDRB  = 0x6002  ; Data Direction Register for Port B
DDRA  = 0x6003  ; Data Direction Register for Port A
PCR   = 0x600c  ; Peripheral Control Register
IFR   = 0x600d  ; Interrupt Flag Register
IER   = 0x600e  ; Interrupt Enable Register

E  = 0b10000000   ; Enable bit for LCD
RW = 0b01000000   ; Read/Write (0 = write)
RS = 0b00100000   ; Register Select for LCD

value    = 0x0200  ; 2 bytes to store current value
mod10    = 0x0202  ; 2 bytes to store modulus result
message  = 0x0204  ; 6 bytes to store output message
counter  = 0x020a  ; 2 bytes for counter storage

; Reset routine
.org 0x8000      ; Set reset vector starting location

reset:
    ; Initialize stack pointer
    ldx #0xff
    txs
    cli           ; Clear interrupt disable flag

    lda #01
    sta PCR       ; Enable Peripheral Control Register

    lda #0x82
    sta IER       ; Set interrupt enable

    ; Configure Port B pins as output
    lda #0b11111111
    sta DDRB

    ; Configure Port A pins as input
    lda #0b00000000
    sta DDRA

    jsr lcd_init

    ; LCD Display configuration
    lda #0b00101000 ; 4-bit mode, 2 lines, 5x8 font
    jsr lcd_instruction
    lda #0b00001111 ; Display ON, cursor OFF
    jsr lcd_instruction
    lda #0b00000110 ; Set entry mode
    jsr lcd_instruction
    lda #0b00000001 ; Clear display
    jsr lcd_instruction

    lda #0
    sta counter
    sta counter + 1

loop:
    lda #0b00000010 ; Move cursor to home position
    jsr lcd_instruction

    lda #0
    sta message     ; Clear message buffer

; Start decimal conversion process
    sei
    lda counter     ; Load lower byte of counter
    sta value
    lda counter + 1 ; Load upper byte of counter
    sta value + 1
    cli

divide:
    ; Initialize remainder to zero
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16         ; Set X register to process 16 bits

divloop:
    ; Rotate quotient and remainder bits
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    ; Subtract divisor (10) from dividend
    sec             ; Set carry for subtraction
    lda mod10
    sbc #10         ; Subtract 10 from mod10
    tay             ; Save low byte of remainder in Y
    lda mod10 + 1
    sbc #0          ; Subtract zero from high byte with carry
    bcc ignore_result ; Branch if result is negative

    sty mod10       ; Store remainder in mod10
    sta mod10 + 1   ; Store high byte

ignore_result:
    dex             ; Decrement X register
    bne divloop     ; Continue if X is not zero
    rol value       ; Rotate final bits in value
    rol value + 1

    lda mod10
    clc
    adc #"0"        ; Convert to ASCII
    jsr push_char

    lda value 
    ora value + 1 
    bne divide      ; Continue division if value is non-zero

    ldx #0
print_message:
    lda message,x
    beq loop        ; Loop if end of message
    jsr print_char
    inx
    jmp print_message

; Push character to message buffer
push_char:
    pha
    ldy #0

char_loop:
    lda message,y   ; Load current byte in message buffer
    tax
    pla
    sta message,y   ; Store accumulator in message buffer
    iny
    txa
    pha
    bne char_loop

    pla
    sta message, y
    rts

lcd_wait:
    pha
    lda #0b11110000 ; Set Port B to output mode for control signals
    sta DDRB 

lcd_busy:
    lda #RW         ; Set RW for read mode
    sta PORTB 
    lda #(RW | E)   ; Set RW and Enable bits
    sta PORTB
    lda PORTB
    pha
    lda #RW 
    sta PORTB 
    lda #(RW | E)
    sta PORTB
    lda PORTB
    pla
    and #0b00001000 ; Check busy flag
    bne lcd_busy    ; Wait if busy flag is set

    lda #RW
    sta PORTB       ; Clear control bits
    lda #0b11111111 ; Set Port B to output mode
    sta DDRB
    pla
    rts

lcd_init:
  lda #%00000011   ; Set 8-bit mode (first initialization)
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00000011   ; Set 8-bit mode (second initialization)
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00000011   ; Set 8-bit mode (third initialization)
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB

  lda #%00000010   ; Set 4-bit mode
  sta PORTB
  ora #E
  sta PORTB
  and #%00001111
  sta PORTB
  rts

lcd_instruction:
    jsr lcd_wait
    pha
    lsr
    lsr
    lsr
    lsr
    sta PORTB
    ora #E
    sta PORTB
    eor #E
    sta PORTB
    pla
    and #%00001111
    sta PORTB
    ora #E
    sta PORTB
    eor #E
    sta PORTB
    rts

print_char:
    jsr lcd_wait
    pha 
    lsr
    lsr 
    lsr 
    lsr
    ora #RS
    sta PORTB
    ora #E
    sta PORTB
    eor #E
    sta PORTB

    pla 
    and #%00001111
    ora #RS
    sta PORTB
    ora #E
    sta PORTB 
    eor #E
    sta PORTB
    rts
 
irq: 
    pha
    lda PORTA
    sta counter
    pla
    rti

nmi:
    rti

.org 0xfffa
.word nmi
.word reset
.word irq
