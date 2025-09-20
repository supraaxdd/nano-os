org 0x7C00
bits 16

main:
    hlt

.halt
    jmp .halt

times 510-($-$$) db 0   ; Padding 512 bytes with 0s
dw 0AA55h               ; This is where the BIOS looks for the bootloader