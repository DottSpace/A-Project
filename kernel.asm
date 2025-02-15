org 0x0
bits 16

KERNEL_SEGMENT EQU 0x2000

jmp main

%include "fat.asm"
%include "screen.asm"
%include "keyboard.asm"
%include "string.asm"
%include "disk.asm"

main:
    mov ax, ds
    mov ss, ax
    mov es, ax

    mov sp, 0
    mov bp, sp

    mov [bootDrive], dl

    call fat_initialize

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

    mov ax, dir
    mov bx, input_prompt
    call string_compare

    jnc dir_cmd

    jmp cmd_loop


clear_cmd:
    call screen_clear
    jmp cmd_loop

dir_cmd:
    mov di, dir_list_buffer
    call get_file_list

    xor cx, cx  ; init counter

.print_loop:
    mov si, di

    mov ah, ','
    call string_get_token

    call print_string
    
    inc cx

    mov ax, cx
    and ax, 0x03

    or al, al           ; if it's a multiple of 4 we are in the last column
    jnz .set_column
    call print_newline  ; therefore we start to the first column by printing a new line

.set_column:
    call get_cursor_position

    mov ax, cx
	and al, 0x03        ; get the current column
	mov bl, 20          ; compute the next column
	mul bl

	mov dl, al
    call set_cursor_position

    cmp byte [ds:di], 0
    jne .print_loop

    call print_newline
    jmp cmd_loop


; data area ...
prompt db "> ",0
input_prompt times 64 db 0
dir_list_buffer times 0xA80 db 0
arguments dw 0
bootDrive db 0

clear db "CLEAR", 0
dir db "DIR", 0