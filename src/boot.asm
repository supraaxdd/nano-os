org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

start: ; Entry point of the bootloader
    jmp main

;
; Prints a string to the screen
; Params:
;   - ds:si points to string
;
puts:
    ; Save the registers we will modify
    push si
    push ax

.loop:
    lodsb       ; Loads next character in al
    or al, al   ; Verify if next character is null
    jz .done    ; Go to .done if flag register is 0

    mov ah, 0x0e    ; Call BIOS interrupt
    mov bh, 0
    int 0x10

    jmp .loop   ; Jump back into the loop

.done ; Restore registers after printing to screen
    pop ax
    pop si
    ret

main:
    ; Setup Data Segment and Extra Segment
    mov ax, 0
    mov ds, ax ; Can't write to ds directly
    mov es, ax ; Can't write to es directly

    ; Setup Stack Segment and Stack Pointer
    mov ss, ax     ; Move the value of ax register into the Stack Segment (0)
    mov sp, 0x7C00 ; Move the stack pointer register to the start of our OS, past the bootloader. The stack grows downwards!

    ; Print Message
    mov si, msg
    call puts

    hlt

.halt
    jmp .halt

msg: db 'Hello World!', ENDL, 0

; All of the below is done after the program is executed, therefore, what we are seeing is what the bootloader is doing
times 510-($-$$) db 0   ; Padding 512 bytes with 0s
dw 0AA55h               ; This is the signature which the BIOS looks for when loading the bootloader