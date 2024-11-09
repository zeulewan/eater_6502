; Define port addresses
PORTB = 0x6000 ; Port B address
PORTA = 0x6001 ; Port A address
DDRB = 0x6002 ; Data Direction Register for Port B address
DDRA = 0x6003 ; Data Direction Register for Port A address
PCR = 0x600c ; peripheral control register
IFR = 0x600d ; intettupt flag register
IER = 0x600e ;interrput enable register

E = 0b10000000 ;enable
RW = 0b01000000 ; read/write, well this sets it to write mode
RS = 0b00100000 ; register select



value= 0x0200 ; 2 bytes
mod10 = 0x0202 ; 2 bytes
message = 0x0204 ; 6 bytes
counter = 0x020a ; 2 bytes


; Reset routine
    .org 0x8000 ; Set relative start location
reset: 
    ; Initialize stack pointer
    ldx #0xff
    txs 
    cli ; clear interrupt disable bitk

    lda #0x82
    sta IER ; =this is setting interrupt active direction
    lda #00
    sta PCR

    ; Enable output on Port B for all pins
    lda #0b11111111 ; ff Sets all pins on port B to output
    sta DDRB ; 6002 is register for data direction for register B

    ; Set some Port A pins to output (right-to-left, highest bits first)
    lda #0b11100000 
    sta DDRA

    ; Configure LCD display settings
    lda #0b00111000 ; Set 8-bit mode, 2 line display, and 5x8 font. function set
    jsr lcd_instruction
    lda #0b00001111 ; Display on or off
    jsr lcd_instruction
    lda #0b00000110 ; Entry mode set
    jsr lcd_instruction
    lda #0b00000001 ; Clear display
    jsr lcd_instruction

    lda #0
    sta counter
    sta counter + 1

loop:
    lda #0b00000010 ; Home cursor
    jsr lcd_instruction

    lda #0
    sta message

; beignning of the conversion
    sei
    lda counter ; Loads the lower 8 bits of the 16-bit number into the accumulator aka a register
    sta value
    lda counter + 1 ; Loads upper byte of value into accumulator
    sta value + 1
    cli

divide:
    ; init remainder to zero 
    lda #0 
    sta mod10
    sta mod10 + 1
    clc

    ldx #16 ; load x register with ascii 16
divloop:
    ; rotate quotient and remainder
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    ; a,y = dividend - divisor:
    sec ; set carry 1
    lda mod10 
    sbc #10 ; subtract 10
    tay ; save low byte in y
    lda mod10 + 1
    sbc #0 ; subtract 0. since it's a subtract with carry, a reg ends up in 255 if carry is 0 from previous subtraction. SBC inverts C and subtracts it
    bcc ignore_result ; branch if dividend < divisor. branch if carry = 0 
    sty mod10  
    sta mod10 + 1
    
ignore_result:
    dex ; decrement x register
    bne divloop ; branch if zero flag is not set, aka brach not equal. a reg is not zero question: why isn't it just a bcc divloop?
    rol value 
    rol value + 1

    lda mod10 
    clc ; clear carry
    adc #"0" ; adding 0 converts it to an ascii number
    jsr push_char

    lda value 
    ora value + 1 
    bne divide ; this says if there is still shit to divide, keep looping

    ldx #0
print_message    ; from helloworld.s program
    lda message,x
    beq loop
    jsr print_char
    inx
    jmp print_message


number: .word 1729 ; 1729 is the number to be converted to decimal

push_char:
    pha             ; push a reg to stack
    ldy #0          ; load y reg with 0

char_loop
    lda message,y   ; load a reg with message bit
    tax             ; transfer a reg to x reg
    pla             ; pull stack to a reg
    sta message,y   ; store a reg in message bit
    iny
    txa             ; where is null terminator coming from
    pha
    bne char_loop

    pla
    sta message, y
    rts

lcd_wait:
    pha ; push accumulator to stack
    lda #0b00000000;ff Sets all pins on port B to output
    sta DDRB ; 6002 is register for data direction for register B

lcd_busy:
    lda #RW ; load accumulator with operataion to enable write to port A. you would never really want to read from port A, thats for setting the data direction and enabling the screen
    sta PORTA ; register A is still output, but B is input
    lda #( RW | E) ; enable. since read is enabled, you read
    sta PORTA
    lda PORTB
    and #0b10000000
    bne lcd_busy ; if zero processor flag is set to 1, loop to lcd_wait

    lda #RW
    sta PORTA   ; clear RS/RW/E bits

    lda #0b11111111 ; ff Sets all pins on port B to output
    sta DDRB ; 6002 is register for data direction for register B
    pla ; pull accumulator from stack
    rts

lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0      ; clear RS/RW/E bits
    sta PORTA
    lda #E      ; Set E bit to send instruction
    sta PORTA
    lda #0
    sta PORTA   ; Clear RS/RW/E bits after instruction send
    rts
 
; Print a character on the LCD display
print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS ; Load register select value to Port A
    sta PORTA
    lda #( RS | E)
    sta PORTA
    lda RS
    sta PORTA
    rts

nmi:
irq: 
    pha 
    txa
    pha

    inc counter 
    bne exit_irq
    inc counter + 1

exit_irq:

    ldx #0xff
delay:    
    dex
    bne delay

    bit PORTA  

    pla
    tax
    pla

    rti

    .org 0xfffa
    .word nmi
    .word reset
    .word irq