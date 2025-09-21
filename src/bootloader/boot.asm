org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

; FAT12 headers
jmp short start
nop

; BIOS Parameter block
bdm_oem:                    db 'MSWIN4.1'       ; 8 bytes
bpb_bytes_per_sector:       dw 512              ; 2 bytes
bpb_sectors_per_cluster:    db 1                ; 1 byte
bpb_reserved_sectors:       dw 2                ; 2 bytes
bpb_file_alloc_tables:      db 2                ; 2 bytes
bpb_dir_entries_count:      dw 0E0h             ; 2 bytes
bpb_total_sectors:          dw 2880             ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h             ; F0 = 3.5" Floppy Disk
bpb_sectors_per_fat:        dw 9
bpb_sectors_per_track:      dw 18
bpb_heads:                  dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sector_count:     dd 0


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

    mov ah, 0x0e    ; Move instruction into ah register
    mov bh, 0
    int 0x10        ; Call BIOS Interrupt

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