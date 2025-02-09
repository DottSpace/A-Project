bytes_per_sector:		dw 512
sectors_per_cluster:	db 1
reserved_sectors:		dw 1
fat_count:				db 2
dir_entries_count:		dw 0xe0
total_sectors:			dw 2880
sectors_per_fat:		dw 9
sectors_per_track:		dw 18
heads:					dw 2


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

list_file:
    push ax
    push cx
    push si
    push es

    mov ax, ROOTDIR_AND_FAT_SEGMENT
    mov es, ax
    mov word cx, [dir_entries_count]
    mov si, ROOTDIR_OFFSET

    add si, 32      ; discard the first entry because it's useless

.loop:
    call .print
    add si, 32
    loop .loop

    pop es
    pop si
    pop cx
    pop ax
    ret

.print:
    pusha

    mov cx, 11
    mov ah, 0xE
    xor bx, bx

.repeat:
    mov byte al, [es:si]
    or al, al
    jz .done

    int 10h

    inc si
    loop .repeat

    call print_newline

.done:
    popa
    ret

failed_init_msg: db "fat initialize failed !",10, 13