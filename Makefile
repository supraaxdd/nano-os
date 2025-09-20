# Compiler & Flags
ASM 		= nasm
ASM_FLAGS 	= -f bin
QEMU		= qemu-system-i386
QEMU_FLAGS  = -fda 

SRC_DIR=src
BUILD_DIR=build

$(BUILD_DIR)/boot.img: $(BUILD_DIR)/boot.bin | $(BUILD_DIR)
	cp $(BUILD_DIR)/boot.bin $(BUILD_DIR)/boot.img
	truncate -s 1440k $(BUILD_DIR)/boot.img

$(BUILD_DIR)/boot.bin: $(SRC_DIR)/boot.asm | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) $(SRC_DIR)/boot.asm -o $(BUILD_DIR)/boot.bin

run: $(BUILD_DIR)/boot.img
	$(QEMU) $(QEMU_FLAGS) $(BUILD_DIR)/boot.img

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*