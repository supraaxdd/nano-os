# Compiler & Flags
ASM 		= nasm
ASM_FLAGS 	= -f elf
LD 			= ld
LD_FLAGS 	= -m elf_i386 -s

# File names
SRC=boot.asm
BUILD_DIR=build
OBJ=$(BUILD_DIR)/boot.o
TARGET=$(BUILD_DIR)/boot

all: $(TARGET)

$(TARGET): $(OBJ)
	$(LD) $(LD_FLAGS) -o $@ $^

compile: $(OBJ)

$(OBJ): $(SRC) | $(BUILD_DIR)
	$(ASM) $(ASM_FLAGS) -o $@ $<

link: $(TARGET)

run: $(TARGET)
	./$(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)/*