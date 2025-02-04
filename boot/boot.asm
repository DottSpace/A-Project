org 07C00h             ; The bootloader is loaded at address 0x07C00
BITS 16

jmp short start
nop

;*********************************************
;    BIOS Parameter Block (BPB) for FAT12
;*********************************************

bpb_oem:					db 'MSWIN4.1'
bpb_bytes_per_sector:		dw 512
bpb_sectors_per_cluster:	db 1
bpb_reserved_sectors:		dw 1
bpb_fat_count:				db 2
bpb_dir_entries_count:		dw 0xe0
bpb_total_sectors:			dw 2880
bpb_media_descriptor_type:	db 0xf0
bpb_sectors_per_fat:		dw 9
bpb_sectors_per_track:		dw 18
bpb_heads:					dw 2
bpb_hidden_sectors:			dd 0
bpb_large_sector_count:		dd 0

ebr_drive_number:			db 0
							db 0
ebr_signature:				db 0x29
ebr_volume_id:				db 0x12, 0x34, 0x56, 0x78
ebr_volume_label:			db "VICE OS    "
ebr_system_id:				db "FAT12   "

start:
    mov ax, 07C00h      ; Set up stack segment
    add ax, 288         ; Add 288h to get space for 4KB stack
    mov ss, ax
    mov sp, 4096        ; Set stack to 4KB

    xor ax, ax
    mov ds, ax          ; Set data segment to 0

	mov [ebr_drive_number], dl ; BIOS should set DL to drive number

    mov si, file_name
    mov ax, 0x2000          ; kernel segment
    mov es, ax
    xor di, di              ; kernel offset
    call loadFile_fromFat

    mov ds, ax          		; setting up the data segment for the kernel
	mov dl, [ebr_drive_number]	; passing drive number to the kernel
    jmp 0x2000:0				; Jump to the address where the kernel is loaded

    jmp $

;=========================================
;load the a file from a fat12 partition
;input: 
;	- file name in si
;	- memory segment in es
;	- memory offset in di
;output: es:di
;=========================================
loadFile_fromFat:
	push si
	push di
	push es
	push ax
	push bx
	push cx

	
	push di         ;have to save to the stack, because it contain the file offset
	push es         ;""""""""""""""""""""""""", because it contain the file segment

;##########################
;loading the root dir table
;##########################
    xor ax, ax
	mov es, ax ; segement where to store data (disk_read parameter)
	mov ax, 19
	mov bx, 14
	mov di, ROOTDIR_AND_FAT_OFFSET
	call disk_read

;########################################
;searching for the file in the root table
;########################################

	xor bx, bx ; init the counter for .search_file
.search_file:
	push si
	push di
	
	mov cx, 11 ; file name length for fat12 (counter loop for repe)
	repe cmpsb

	pop di
	pop si

	je .file_found

	add di, 32 ; next dir entry
	inc bx
	cmp bx, [bpb_dir_entries_count]
	jl .search_file

	jmp file_not_found

.file_found:
	mov cx, [di+26] ; first logical cluster filled
	mov [file_cluster], cx

	;##########################
	;loading the fat table
	;##########################
	mov ax, 1
	mov bx, 18
	mov di, ROOTDIR_AND_FAT_OFFSET ; we just override the root dir table
	call disk_read

	pop es ; restore the file segment
	pop di ; restore the file offset

.file_cluster_loop:
	mov ax, [file_cluster]
	add ax, 31
	mov bx, [bpb_sectors_per_cluster]
	call disk_read
	add di, [bpb_bytes_per_sector] ;adding the size of the read data to avoid overwriting existing data

	mov ax, [file_cluster]
	mov cx, 3
	mul cx
	mov cx, 2
	div cx

	mov si, ROOTDIR_AND_FAT_OFFSET
	add si, ax
	lodsw

	or dx, dx
	jz .even

.odd:
	shr ax, 4
	jmp .nextClusterTest
.even:
	and ax, 0x0fff

.nextClusterTest:
	cmp ax, 0x0ff8
	jae .end_load_file

	mov [file_cluster], ax
	jmp .file_cluster_loop

.end_load_file:
	pop cx
	pop bx
	pop ax
	pop es
	pop di
	pop si
	ret

;=========================================
;convert a logical block address to 
;cylinder head sector address
;input: 
;	- LBA index in ax
;output:
;	- cx [bits 0-5]: sector number
;	- cx [bits 6-15]: cylinder
;	- dh: head 
;=========================================
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


;=========================================
;read a given number of sector on the disk
;input: 
;	- LBA index in ax
;	- number of sector to read in bx
;	- memory segment in es
;	- memory offset in di
;output: es:di
;=========================================
disk_read:
	push ax
	push bx
	push cx
	push dx
	push si
	push di

	call lba2chs

	mov al, bl
	mov dl, 0x0
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
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	ret

disk_reset:
	pusha

	mov ah, 0x0
	stc
	int 13h
	jc failDiskRead

	popa
	ret

print_string:         ; Routine to print a string, input on si
    mov ah, 0Eh       ; BIOS interrupt function 0Eh for printing characters
.repeat:
    lodsb             ; Load the next byte of the string into AL
    cmp al, 0         ; If it's 0 (string terminator), end
    je .done
    int 10h           ; Execute BIOS interrupt to print the character
    jmp .repeat
.done:
    ret

;handling error section
failDiskRead:
	mov si, read_failure
	call print_string
	hlt
	jmp halt

file_not_found:
	mov si, msg_file_not_found
	call print_string
	jmp halt

halt:
    cli     ;disable interrupt
    hlt
    jmp halt

text_string db 'Loading kernel...', 0
read_failure DB "failed t read disk !", 13, 10, 0
file_name DB "KERNEL  BIN"
file_cluster DW 0
msg_file_not_found DB "this file doesn't exist !", 13, 10, 0
ROOTDIR_AND_FAT_OFFSET EQU 0xc000
KERNEL_SEGMENT EQU 0x2000

times 510-($-$$) db 0   ; Padding to complete 512 bytes
dw 0xAA55               ; Standard boot signature for bootloader