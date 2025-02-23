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