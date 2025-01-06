org 0x0
bits 16

mov si, msg
call print_string
jmp $

print_string:         ; Routine to print a string, input on si
    mov ah, 0Eh       ; BIOS interrupt function 0Eh for printing characters
.repeat:
    lodsb             ; Load the next byte of the string into AL
    cmp al, 0         ; If it's 0 (string terminator), end
    je .done
    int 10h           ; Execute BIOS interrupt to print the character
    jmp .repeat
.done:
    ret

msg db "kernel is speaking...",0

jmp $