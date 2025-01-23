org 0x0
bits 16

main:
    mov ax, ds
    mov ss, ax
    mov es, ax
    mov sp, 0

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

; ------------------------------------------------------------------
; string_purify -- Strip leading and trailing spaces from a string
; IN: DS:BX = string location
string_purify:
    push cx
    push ax
    push si
    push di

    xor cx, cx
    mov si, bx

    ; count number of leading spaces
.keep_counting:
    lodsb
    cmp al, ' '
    jne .counted

    inc cx
    jmp .keep_counting

.counted:
    or cx, cx
    jz .end_strip       ; if 0 spaces at the begining

    mov si, bx
    mov di, si
    add si, cx

    ; otherwise we shift the string to fill the spaces
.keep_shifting:
    lodsb
    mov byte [es:di], al
    inc di
    
    or al, al
    jnz .keep_shifting

    ; now we need to fill the trailing spaces with 0
.end_strip:
    mov si, bx
    call string_length
    add si, cx          ; we are at the end of the string

.fill_spaces:
    dec si
    mov byte al, [ds:si]

    cmp al, ' '
    jne .done

    mov byte [ds:si], 0x0
    jmp .fill_spaces

.done:
    pop di
    pop si
    pop ax
    pop cx

    ret

; ------------------------------------------------------------------
; string_length -- 
; IN: DS:SI = string location; OUT: CX = length
string_length:
    push ax
    push si

    xor cx, cx

.keep_counting:
    lodsb
    or al, al
    jz .done

    inc cx
    jmp .keep_counting

.done:
    pop si
    pop ax
    ret

; ------------------------------------------------------------------
; string_compare -- 
; IN: DS:AX = first string location DS:BX = second string location
; OUT: carry flag clear if equal or set if not equal
string_compare:
    push ax
    push bx
    push cx
    push dx
    push si

    mov si, ax
    call string_length
    mov dx, cx

    mov si, bx
    call string_length
    
    cmp cx, dx          ; we first check for the length
    jne .not_equal

    mov si, ax
    mov di, bx

.keep_comparing:
    mov byte dl, [ds:si]
    mov byte dh, [ds:di]
    cmp dh, dl
    jne .not_equal
    
    dec cx
    jcxz .equal

    inc si
    inc di
    
    jmp .keep_comparing

.not_equal:
    stc
    jmp .done

.equal:
    clc

.done:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ------------------------------------------------------------------
; string_get_token -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AH = separator char, DS:SI = beginning; OUT: DS:DI = next token or 0 if none
string_get_token:
    push ax
    push si

    ; we search for the specified char
.keep_searching:
    mov byte al, [ds:si]
    or al, al
    jz .done                ; we are at the end of the string, done.

    cmp ah, al
    je .send_token          ; we found it

    inc si
    jmp .keep_searching

.send_token:
    mov byte [ds:si], 0x0   ; we replace it by 0
    inc si 

.done:
    mov di, si              ; out put the next token or 0             
    pop si
    pop ax
    ret

; ------------------------------------------------------------------
; string_toUppercase -- Convert zero-terminated string to upper case
; IN/OUT: DS:AX = string location
string_toUppercase:
    push ax
    push si

    mov si, ax

.keep_up:
    cmp byte [ds:si], 0
    je .done

    cmp byte [ds:si], 'a'
    jb .not_alpha

    cmp byte [ds:si], 'z'
    ja .not_alpha

    sub byte [ds:si], 0x20

    inc si
    jmp .keep_up

.not_alpha:
    inc si
    jmp .keep_up

.done:
    pop si
    pop ax
    ret


; data area ...
prompt db "> ",0
input_prompt times 64 db 0
arguments dw 0

clear db "CLEAR", 0