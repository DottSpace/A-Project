BUILD_DIR = build
FAT = mkfs.fat

#
# Floppy Image
#

floppyDisk: always $(BUILD_DIR)/main.img

$(BUILD_DIR)/main.img: bootloader.bin kernel.bin
	dd if=/dev/zero of=$(BUILD_DIR)/main.img bs=512 count=2880
	$(FAT) -F 12 -n "Aproject" $(BUILD_DIR)/main.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/main.img conv=notrunc
	mcopy -i $(BUILD_DIR)/main.img $(BUILD_DIR)/kernel.bin "::kernel.bin"

bootloader.bin: boot/boot.asm
	nasm -f bin  boot/boot.asm -o $(BUILD_DIR)/bootloader.bin

kernel.bin: kernel.asm
	nasm -f bin  kernel.asm -o $(BUILD_DIR)/kernel.bin

cygwin: FAT=/usr/local/sbin/mkfs.fat.exe
cygwin: floppyDisk

always:
	mkdir -p build/