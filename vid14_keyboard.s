; Define port addresses
PORTB = 0x6000  ; Port B address
PORTA = 0x6001  ; Port A address
DDRB  = 0x6002  ; Data Direction Register for Port B
DDRA  = 0x6003  ; Data Direction Register for Port A
PCR   = 0x600c  ; Peripheral Control Register
IFR   = 0x600d  ; Interrupt Flag Register
IER   = 0x600e  ; Interrupt Enable Register

kb_wptr = 0x0000
kb_rptr = 0x0001
kb_flags = 0x0002

RELEASE = 0b00000001
SHIFT = 0b00000010

kb_buffer = 0x0200 ;256 byte kb buffer 0200-02ff

E  = 0b10000000   ; Enable bit for LCD
RW = 0b01000000   ; Read/Write (0 = write)
RS = 0b00100000   ; Register Select for LCD



; Reset 
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

    lda #0x00
    sta kb_rptr
    sta kb_wptr
    sta kb_flags

loop: 
    sei
    lda kb_rptr
    cmp kb_wptr
    cli
    bne key_pressed
    jmp loop

key_pressed
    ldx kb_rptr
    lda kb_buffer, x
    jsr print_char
    inc kb_rptr
    jmp loop

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
 
keyboard_interrupt: 
    pha
    txa
    pha

    lda kb_flags 
    and #RELEASE
    beq read_key

    lda kb_flags ; can skip loading again
    eor #RELEASE 
    sta kb_flags 
    lda PORTA    
    cmp #0x12
    beq shift_up
    cmp #0x59
    beq shift_up
    jmp exit

shift_up
    lda kb_flags
    eor #SHIFT
    sta kb_flags
    jmp exit

read_key:
    lda PORTA
    cmp #0xf0
    beq key_release
    
    cmp #0x12
    beq shift_down
    cmp #059
    beq shift_down

    tax 
    lda kb_flags
    and #SHIFT
    bne shifted_key
    
    lda keymap, x
    jmp push_key

shifted_key:
  lda keymap_shifted, x

push_key:
    ldx kb_wptr
    sta kb_buffer, x
    inc kb_wptr
    jmp exit

shift_down
    lda kb_flags
    ora #SHIFT
    sta kb_flags
    jmp exit

key_release:
    lda kb_flags
    ora #RELEASE 
    sta kb_flags

exit:
    pla
    tax
    pla
    rti

nmi:
    rti

    .org 0xfd00

keymap:
  .byte "????????????? `?"      ; 00-0F
  .byte "?????q1???zsaw2?"      ; 10-1F
  .byte "?cxde43?? vftr5?"      ; 20-2F
  .byte "?nbhgy6???mju78?"      ; 30-3F
  .byte "?,kio09??./l;p-?"      ; 40-4F
  .byte "??'?[=?????]?\??"      ; 50-5F
  .byte "?????????1?47???"      ; 60-6F
  .byte "0.2568???+3-*9??"      ; 70-7F
  .byte "????????????????"      ; 80-8F
  .byte "????????????????"      ; 90-9F
  .byte "????????????????"      ; A0-AF
  .byte "????????????????"      ; B0-BF
  .byte "????????????????"      ; C0-CF
  .byte "????????????????"      ; D0-DF
  .byte "????????????????"      ; E0-EF
  .byte "????????????????"      ; F0-FF
keymap_shifted:
  .byte "????????????? ~?" ; 00-0F
  .byte "?????Q!???ZSAW@?" ; 10-1F
  .byte "?CXDE#$?? VFTR%?" ; 20-2F
  .byte "?NBHGY^???MJU&*?" ; 30-3F
  .byte "?<KIO)(??>?L:P_?" ; 40-4F
  .byte '??"?{+?????}?|??' ; 50-5F
  .byte "?????????1?47???" ; 60-6F
  .byte "0.2568???+3-*9??" ; 70-7F
  .byte "????????????????" ; 80-8F
  .byte "????????????????" ; 90-9F
  .byte "????????????????" ; A0-AF
  .byte "????????????????" ; B0-BF
  .byte "????????????????" ; C0-CF
  .byte "????????????????" ; D0-DF
  .byte "????????????????" ; E0-EF
  .byte "????????????????" ; F0-FF

    .org 0xfffa
    .word nmi
    .word reset
    .word keyboard_interrupt
