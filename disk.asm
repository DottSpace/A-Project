; ------------------------------------------------------------------
; convert a logical block address to cylinder head sector address
; IN: AX = LBA index 
; OUT: cx [bits 0-5]: sector number; cx [bits 6-15]: cylinder; dh: head 
lba2chs:
	push ax

	xor dx, dx
	div word [sectors_per_track]
	inc dx
	mov cl, dl ;sector

	xor dx, dx
	div word [heads]
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
; OUT: es:di, carry flag clear set if failed
disk_read:
	pusha

	call lba2chs

	mov al, bl
	mov dl, [bootDrive]
	mov bx, di
	mov di, 3       ;counter for retry_disk (must retry if at least 3 times if disk read failed)

.retry_disk:
	mov ah, 0x2
	int 0x13

	jnc .done_read
	call disk_reset

	stc				; because disk_reset might succeed

	dec di
	or di, di
	jnz .retry_disk

.done_read:
	popa
	ret

; ------------------------------------------------------------------
; disk_reset -- reset the disk controller
; IN/OUT: Nothing, carry flag clear set if failed
disk_reset:
	pusha

	mov ah, 0x0
	mov dl, [bootDrive]
	int 13h

	popa
	ret

; ------------------------------------------------------------------
; disk_getDriveParms -- Reports disk drive parameters
; IN: Nothing
; OUT: CH = Maximum value for cylinder (10-bit value; upper 2 bits in CL)
;	   CL = Maximum value for sector
;	   DH = Maximum value for heads
disk_getDriveParms:
	push ax
	push bx
    push bp
    push si
    push di
    push sp

	mov ah, 0x08
	mov dl, [bootDrive]
	int 13h

	pop sp
    pop di
    pop si
    pop bp
    pop bx
	pop ax
	ret