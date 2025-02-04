; ------------------------------------------------------------------
; convert a logical block address to cylinder head sector address
; IN: AX = LBA index 
; OUT: cx [bits 0-5]: sector number; cx [bits 6-15]: cylinder; dh: head 
lba2chs:
	push ax

	xor dx, dx
	div word [bpb_sectors_per_track]
	inc dx
	mov cl, dl ;sector

	xor dx, dx
	div word [bpb_heads]
	mov ch, al
	shl ah, 6
	or cl, ah ;cylinder

	shl dx, 8 ;in dh: head

	pop ax
	ret


; ------------------------------------------------------------------
; read a given number of sector on the disk
; IN: AX = LBA index; BX = number of sector to read; ES = memory segment
;     DI = memory offset
; OUT: es:di
disk_read:
	pusha

	call lba2chs

	mov al, bl
	mov dl, [driveNumber]
	mov bx, di
	mov di, 3       ;counter for retry_disk (must retry if at least 3 times if disk read failed)

.retry_disk:
	stc
	mov ah, 0x2
	int 0x13

	jnc .done_read
	call disk_reset

	dec di
	or di, di
	jnz .retry_disk

.done_read:
	popa
	ret

; ------------------------------------------------------------------
; reset the disk controller
; IN/OUT: Nothing
disk_reset:
	pusha

	mov ah, 0x0
	stc
	int 13h
	jc failDiskRead

	popa
	ret