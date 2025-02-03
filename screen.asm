print_string:         ; Routine to print a string, input on ds:si
    pusha

    xor bh, bh
    mov ah, 0Eh       ; BIOS interrupt function 0Eh for printing characters
.repeat:
    lodsb             ; Load the next byte of the string into AL
    cmp al, 0         ; If it's 0 (string terminator), end
    je .done
    int 10h           ; Execute BIOS interrupt to print the character
    jmp .repeat
.done:

    popa
    ret

; ------------------------------------------------------------------
; input_string: Routine to input a string
; IN: es:di = output address, BX = maximum bytes of output string (buffer size)
; OUT: Nothing
input_string:
    push cx
    push ax
    push di

    or bx, bx
    jz .done            ; character count = 0, nothing to do

    dec bx              ; string length without '\0'
    mov cx, bx

.get_char:
    call wait_for_key

    cmp al, 8
	je .backspace

	cmp al, 13			; The ENTER key ends the string
	je .end_string      ; the only way to get out of this procedure

    ; Do not add any characters if the maximum size has been reached.
	jcxz .get_char

    ; Only add printable characters (ASCII Values 32-126)
	cmp al, ' '
	jb .get_char

	cmp al, 126
	ja .get_char

    call .add_char

    dec cx
    jmp .get_char

.backspace:
    cmp cx, bx
    jae .get_char           ; if the buffer is empty, nothing to do

    dec di                  ;remove the character from buffer
    call .reverse_cursor

    mov al, ' '
    call .add_char
    dec di                  ; beaucause .add_char does inc di automatically

    call .reverse_cursor
    inc cx
    jmp .get_char
    


.end_string:
    mov byte [es:di], 0x0

.done:
    pop di
    pop ax
    pop cx
    ret

.reverse_cursor:
    push dx
    
    call get_cursor_position

    or dl, dl
    jnz .normal_reverse
    dec dh
    mov dl, 79
    jmp .reverse

.normal_reverse:
    dec dl
.reverse:
    call set_cursor_position

    pop dx
    ret

.add_char:
	stosb               ; in es:di

    pusha

	mov ah, 0x0E	    ; Teletype Function
	mov bh, 0			; Video Page 0
	int 0x10

	popa
	ret

; ------------------------------------------------------------------
; get_cursor_position
; IN: Nothing; OUT: DH = row, DL = column
get_cursor_position:
    push ax
    push bx
    push cx
    push bp
    push si
    push di
    push sp

    xor bh, bh
    mov ah, 0x3
    int 0x10

    pop sp
    pop di
    pop si
    pop bp
    pop cx
    pop bx
    pop ax

    ret

; ------------------------------------------------------------------
; set_cursor_position
; OUT: Nothing; IN: DH = row, DL = column
set_cursor_position:

    pusha

    xor bh, bh
    mov ah, 0x2
    int 0x10

    popa

    ret

; ------------------------------------------------------------------
; print_newline -- Reset cursor to start of next line
; IN/OUT: Nothing (registers preserved)
print_newline:
	pusha

	mov ah, 0xe
    mov bh, 0

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret

; ------------------------------------------------------------------
; screen_clear -- Clears the screen
; IN/OUT: Nothing (registers preserved)
screen_clear:
    pusha

	mov dx, 0			; Position cursor at top-left
	call set_cursor_position

	mov ah, 6			
	mov al, 0			; Scroll full-screen
	mov bh, 7			; Normal white on black
	mov cx, 0			; Top-left
	mov dh, 24			; Bottom-right
	mov dl, 79
	int 10h

	popa
	ret