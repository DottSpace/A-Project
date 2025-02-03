; ------------------------------------------------------------------
; wait_for_key -- Waits for keypress and returns key
; IN: Nothing; OUT: AH = scancode, AL = ascii code
wait_for_key:
    push bx
    push cx
    push dx
    push bp
    push si
    push di
    push sp

.wait_again:
    mov ah, 0x11
    int 0x16

    hlt
    jz .wait_again
    
    mov ah, 0x10
	int 0x16

    pop sp
    pop di
    pop si
    pop bp
    pop dx
    pop cx
    pop bx
	ret