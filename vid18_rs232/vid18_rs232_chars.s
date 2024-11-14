; Define port addresses
PORTB = $6000  ; Port B address
PORTA = $6001  ; Port A address
DDRB  = $6002  ; Data Direction Register for Port B
DDRA  = $6003  ; Data Direction Register for Port A
PCR   = $600c  ; Peripheral Control Register
IFR   = $600d  ; Interrupt Flag Register
IER   = $600e  ; Interrupt Enable Register

E  = %10000000   ; Enable bit for LCD
RW = %01000000   ; Read/Write (0 = write)
RS = %00100000   ; Register Select for LCD


; Reset routine
    .org $8000      ; Set reset vector starting location

reset:
    ; Initialize stack pointer
    ldx #$ff
    txs

    ; Configure Port B pins as output
    lda #%11111111
    sta DDRB

    ; Configure Port A pins as input
    lda #%10111111
    sta DDRA

    jsr lcd_init

    ; LCD Display configuration
    lda #%00101000 ; 4-bit mode, 2 lines, 5x8 font
    jsr lcd_instruction
    lda #%00001111 ; Display ON, cursor OFF
    jsr lcd_instruction
    lda #%00000110 ; Set entry mode
    jsr lcd_instruction
    lda #%00000001 ; Clear display
    jsr lcd_instruction

    clc
    clv


rx_wait:
    bit PORTA ; puts the value of PORTA pin6 in the zero flag
    bvs rx_wait ; wait until the zero flag is set

    jsr half_bit_delay

    ldx #8

read_bit:
    jsr bit_delay
    bit PORTA
    bvs recv_1
    clc
    jmp rx_done
recv_1:
    sec
    nop
    nop
rx_done:
    ror
    dex
    bne read_bit

    jsr print_char
    jsr bit_delay
    jmp rx_wait

bit_delay:
    phx
    ldx #13
bit_delay_1:
    dex
    bne bit_delay_1
    plx
    rts

half_bit_delay:
    phx
    ldx #6
half_bit_delay_1:
    dex
    bne half_bit_delay_1
    plx
    rts


lcd_wait:
    pha
    lda #%11110000 ; Set Port B to output mode for control signals
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
    and #%00001000 ; Check busy flag
    bne lcd_busy    ; Wait if busy flag is set

    lda #RW
    sta PORTB       ; Clear control bits
    lda #%11111111 ; Set Port B to output mode
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
    rti

nmi:
    rti

    .org $fffa
    .word nmi
    .word reset
    .word irq
