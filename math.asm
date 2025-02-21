; ------------------------------------------------------------------
; bcd_to_int -- Converts binary coded decimal number to an integer
; IN: AX = BCD number; OUT: AX = integer value
bcd_to_int:
    ; I tried to use this formula: number = digit * 10^position + number
    ; for e.g:      -----> digit * 10 ^ 0 + number = number --> number = 9
    ;               |
    ;           0x229
    ;              -----> digit * 10 ^ 1 + number = number -> number = 9+20 = 29
    ;              |
    ;           0x229
    ; and so on ...
    push bx
    push cx
    push dx

    xor cx, cx  ; position will be in cx
    xor dx, dx  ; the number in dx

.loop:
    mov bx, ax
    and bx, 0x0f    ; the digit in bx

    push ax         ; because .pow modifies it

    call .pow

    push dx         ; because mul modifies it
    mul bx
    pop dx

    add dx, ax

    pop ax

    shr ax, 4
    or ax, ax
    jz .done

    inc cx
    jmp .loop
    

.done:
    mov ax, dx

    pop dx
    pop cx
    pop bx
    ret

.pow:
    push cx
    push dx

    mov ax, 1

.loop_pow:
    or cx, cx
    jz .done_pow

    mov dx, 10
    mul dx

    dec cx
    jmp .loop_pow

.done_pow:
    pop dx
    pop cx
    ret
