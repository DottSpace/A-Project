org 0x0
bits 16

jmp main

%include "screen.asm"
%include "keyboard.asm"
%include "string.asm"

main:
    mov ax, ds
    mov ss, ax
    mov es, ax

    mov sp, 0
    mov bp, sp

    mov [driveNumber], dl

cmd_loop:
    mov si, prompt
    call print_string

    mov di, input_prompt
    mov bx, 64
    call input_string

    call print_newline

    mov bx, di
    call string_purify

    mov ah, ' '
    mov si, di
    call string_get_token

    mov [arguments], di

    mov ax, input_prompt
    call string_toUppercase

    ; First, let's check to see if it's an built in command...

    mov ax, clear
    mov bx, input_prompt
    call string_compare

    jnc clear_cmd

    jmp cmd_loop


clear_cmd:
    call screen_clear
    jmp cmd_loop


; data area ...
prompt db "> ",0
input_prompt times 64 db 0
arguments dw 0
driveNumber db 0

clear db "CLEAR", 0