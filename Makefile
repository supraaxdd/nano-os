# Compiler & Flags
ASM 		= nasm
ASM_FLAGS 	= -f bin
QEMU		= qemu-system-i386
QEMU_FLAGS  = -fda 

BOOTLOADER_SRC_DIR=src/bootloader
KERNEL_SRC_DIR=src/kernel
SRC_DIR=src
BUILD_DIR=build

.PHONY: all img kernel bootloader clean always

# Image build
$(BUILD_DIR)/nano.img: bootloader | kernel
	dd if=/dev/zero of=$(BUILD_DIR)/nano.img bs=512 count=2880
	mkfs.fat -F 12 -n "NBOS" $(BUILD_DIR)/nano.img
	dd if=$(BUILD_DIR)/bootloader.bin of=$(BUILD_DIR)/nano.img conv=notrunc
	mcopy -i $(BUILD_DIR)/nano.img $(BUILD_DIR)/kernel.bin "::kernel.bin"
# 	cp $(BUILD_DIR)/bootloader.bin $(BUILD_DIR)/nano.img
# 	truncate -s 1440k $(BUILD_DIR)/nano.img

# Bootloader binary
bootloader: $(BUILD_DIR)/bootloader.bin
$(BUILD_DIR)/bootloader.bin: always
	$(ASM) $(ASM_FLAGS) $(BOOTLOADER_SRC_DIR)/boot.asm -o $(BUILD_DIR)/bootloader.bin

# Kernel binary
kernel: $(BUILD_DIR)/kernel.bin
$(BUILD_DIR)/kernel.bin: always
	$(ASM) $(ASM_FLAGS) $(KERNEL_SRC_DIR)/main.asm -o $(BUILD_DIR)/kernel.bin

run: $(BUILD_DIR)/nano.img
	$(QEMU) $(QEMU_FLAGS) $(BUILD_DIR)/nano.img

always:
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*