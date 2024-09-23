; guessing_game.asm
; Tu Pham

; CPU configuration
; (16F84 with RC osc, watchdog timer off, power-up timer on)

    processor 16f84A
    include <p16F84A.inc>
    __config _RC_OSC & _WDT_OFF & _PWRTE_ON

; some handy macro definitions

IFSET macro fr,bit,label
    btfss fr,bit    ; if (fr.bit) then execute code following macro
    goto label      ; else goto label
    endm

IFCLR macro fr,bit,label
    btfsc fr,bit    ; if (! fr.bit) then execute code following macro
    goto label      ; else goto label
    endm

IFEQ macro fr,lit,label
    movlw lit
    xorwf fr,W
    btfss STATUS,Z      ; (fr == lit) then execute code following macro
    goto label          ; else goto label
    endm

IFNEQ macro fr,lit,label
    movlw lit
    xorwf fr,W
    btfsc STATUS,Z      ; (fr != lit) then execute code following macro
    goto label          ; else goto label
    endm

MOVLF macro lit,fr
    movlw lit
    movwf fr
    endm

MOVFF macro from,to
    movf from,W
    movwf to
    endm

; file register variables

nextState equ 0x0C      ; next state (output)
octr equ 0x0D           ; outer-loop counter for delays
ictr equ 0x0E           ; inner-loop counter for delays

; state definitions for Port B

S1 equ B'00000001'
S2 equ B'00000010'
S3 equ B'00000100'
S4 equ B'00001000'
SERR equ B'00010000'
SOK equ B'00100000'

; input bits on Port A

G4 equ 3
G3 equ 2
G2 equ 1
G1 equ 0

; beginning of program code

    org 0x00    ; reset at address 0

reset:      goto init   ; skip reserved program addresses

    org 0x08    ; beginning of user code

init:
; set up RB5-0 as outputs
    bsf STATUS, RP0     ; switch to bank 1 memory
    MOVLF B'11000000', TRISB    ; RB7-6 are inputs, RB5-0 are outputs 
    bcf STATUS, RP0 ; return to bank 0 memory

; initialize state variables
    MOVLF S1, nextState ; nextState = S1

mloop:      ; here begins the main program loop
    MOVFF nextState, PORTB ; PORTB = nextState, i.e. PORTB is the current state

; check current state, test inputs, and compute next state
    IFNEQ PORTB, S1, stateS1
    IFNEQ PORTB, S2, stateS2
    IFNEQ PORTB, S3, stateS3
    IFNEQ PORTB, S4, stateS4
    IFNEQ PORTB, SERR, stateSERR

stateSOK: IFCLR PORTA, G1, setOk
    IFCLR PORTA, G2, setOk
    IFCLR PORTA, G3, setOk
    IFCLR PORTA, G4, setOk
    MOVLF S1, nextState
    goto delay

stateSERR: IFCLR PORTA, G1, setErr
    IFCLR PORTA, G2, setErr
    IFCLR PORTA, G3, setErr
    IFCLR PORTA, G4, setErr
    MOVLF S1, nextState
    goto delay

stateS1: IFCLR PORTA, G2, setErr
    IFCLR PORTA, G3, setErr
    IFCLR PORTA, G4, setErr
    IFCLR PORTA, G1, setOk
    MOVLF S2, nextState
    goto delay

stateS2: IFCLR PORTA, G1, setErr
    IFCLR PORTA, G3, setErr
    IFCLR PORTA, G4, setErr
    IFCLR PORTA, G2, setOk
    MOVLF S3, nextState
    goto delay

stateS3: IFCLR PORTA, G1, setErr
    IFCLR PORTA, G2, setErr
    IFCLR PORTA, G4, setErr
    IFCLR PORTA, G3, setOk
    MOVLF S4, nextState
    goto delay

stateS4: IFCLR PORTA, G1, setErr
    IFCLR PORTA, G2, setErr
    IFCLR PORTA, G3, setErr
    IFCLR PORTA, G4, setOk
    MOVLF S1, nextState
    goto delay

setOk: MOVLF SOK, nextState
    goto delay

setErr: MOVLF SERR, nextState
    goto delay

delay:      ; create a delay of about 1 second
    MOVLF d'32',octr    ; initialize outer loop counter to 32

d1: clrf ictr   ; initialize inner loop counter to 256

d2: decfsz ictr,F       ; if (--ictr != 0) loop to d2
    goto d2 
    decfsz octr,F       ; if (--octr != 0) loop to d1
    goto d1

endloop:    ; end of main loop
    goto mloop
    end     ; end of program code