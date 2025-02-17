bytes_per_sector:		    dw 512
sectors_per_cluster:	    db 1
reserved_sectors:		    dw 1
fat_count:				    db 2
dir_entries_count:		    dw 0xe0
total_sectors:			    dw 2880
sectors_per_fat:		    dw 9
sectors_per_track:		    dw 18
heads:					    dw 2


ROOTDIR_AND_FAT_SEGMENT EQU 0xFA
FAT_OFFSET EQU              0x00
ROOTDIR_OFFSET EQU          0x3000

; ------------------------------------------------------------------
; fat_initialize --  initializing some essential data for disk management.
;IN/OUT: Nothing (registers preserved)
fat_initialize:
    push ax
    push bx
    push cx
    push dx
    push es
    push di

    call disk_getDriveParms

    xor ch, ch              ; cylinder count is useless
    shl cl, 2
    shr cl, 2

    mov word [sectors_per_track], cx

    inc dh                  ; don't know why but disk_getDriveparms return head value - 1
    shr dx, 8

    mov word [heads], dx

    mov ax, ROOTDIR_AND_FAT_SEGMENT
    mov es, ax

    mov word ax, [sectors_per_fat]
    xor bx, bx
    mov byte bl, [fat_count]
    mul bx

    mov bx, ax
    push ax

    mov word ax, [reserved_sectors]

    mov di, FAT_OFFSET
    call disk_read
    jc .init_failed

    mov word ax, [dir_entries_count]
    xor bx, bx
    mov bx, 16
    div bx

    mov bx, ax

    pop ax
    mov word dx, [reserved_sectors]
    add ax, dx

    mov di, ROOTDIR_OFFSET
    call disk_read
    jc .init_failed

    jmp .done

.init_failed:
    mov si, failed_init_msg
    call print_string

.done:
    pop di
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ------------------------------------------------------------------
; get_file_list --  Generate comma-separated string of files on disk
; IN: DS:DI = location to store zero-terminated filename string
; OUT: DS:DI = location where zero-terminated filename string was placed
get_file_list:
    push ax
    push cx
    push si
    push di
    push es
    push ds

;exchange es and ds for lodsb and stosb
    push es
    push ds
    pop es
    pop ds

    mov ax, ROOTDIR_AND_FAT_SEGMENT
    mov ds, ax

    mov word cx, [dir_entries_count]
    mov si, ROOTDIR_OFFSET

    add si, 32      ; discard the first entry because it's useless
    dec cx

.next_entry:

    cmp byte [ds:si], 0 ; check if the entry has a file in it
    jne .not_empty

    dec cx          ; next entry
    or cx, cx
    jz .done

    jmp .next_entry

.not_empty:
    call .process_entry
    add si, 32
    
    dec cx
    or cx, cx
    jz .done

    mov byte [es:di], ','   ; add separator after the test
    inc di
    jmp .next_entry

.done:
    mov byte [es:di], 0     ; must be a zero terminated string

    pop ds
    pop es
    pop di
    pop si
    pop cx
    pop ax
    ret

.process_entry:
    push si
    push cx

    mov cx, 8   ; length for file name

.loop_name:
    mov byte al, [ds:si]

    cmp al, ' '         
    je .loop_extension  ; if no more character for the file name

    inc si
    stosb

    loop .loop_name

.loop_extension:
    add si, cx

    mov byte [es:di], '.'   ; add a period for the extension
    inc di

    mov cx, 3   ; length for extension

.start:
    lodsb

    cmp al, ' '
    je .done_process    ; no more character for the extension

    stosb

    loop .start

.done_process:
    pop cx
    pop si
    ret



failed_init_msg: db "fat initialize failed !",10, 13