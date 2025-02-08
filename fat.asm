bytes_per_sector:		dw 512
sectors_per_cluster:	db 1
reserved_sectors:		dw 1
fat_count:				db 2
dir_entries_count:		dw 0xe0
total_sectors:			dw 2880
sectors_per_fat:		dw 9
sectors_per_track:		dw 18
heads:					dw 2

; ------------------------------------------------------------------
; fat_initialize --  initializing some essential data for disk management.
;IN/OUT: Nothing (registers preserved)
fat_initialize:
    push cx
    push dx

    call disk_getDriveParms

    xor ch, ch              ; cylinder count is useless
    shl cl, 2
    shr cl, 2

    mov word [sectors_per_track], cx

    inc dh                  ; don't know why but disk_getDriveparms return head value - 1
    shr dx, 8

    mov word [heads], dx

    ; TODO: load the fat and directory table at a fixed address

    pop dx
    pop cx
    ret

