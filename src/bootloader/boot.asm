org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A

; FAT12 headers
jmp short start
nop

; BIOS Parameter block (https://wiki.osdev.org/FAT#FAT_12 - Look at BPB)
bdm_oem:                    db 'MSWIN4.1'           ; 8 bytes
bpb_bytes_per_sector:       dw 512                  ; 2 bytes
bpb_sectors_per_cluster:    db 1                    ; 1 byte
bpb_reserved_sectors:       dw 1                    ; 2 bytes
bpb_file_alloc_tables:      db 2                    ; 2 bytes
bpb_dir_entries_count:      dw 0E0h                 ; 2 bytes
bpb_total_sectors:          dw 2880                 ; 2880 * 512 = 1.44MB
bdb_media_descriptor_type:  db 0F0h                 ; F0 = 3.5" Floppy Disk
bpb_sectors_per_fat:        dw 9                    ; 9 sectors/fat
bpb_sectors_per_track:      dw 18
bpb_heads:                  dw 2
bpb_hidden_sectors:         dd 0
bpb_large_sector_count:     dd 0

; Extended Boot Record
ebr_drive_number:           dw 00h                  ; 0x00 Floppy, 0x80 HDD
ebr_flags:                  db 0                    ; Reserved for Windows NT (not applicable in this case)
ebr_sig:                    dw 0x29                 ; Must be 0x28 or 0x29
ebr_vol_no:                 db 12h, 34h, 56h, 78h   ; Serial Number. Value doesn't matter
ebr_vol_label:              db 'Nano OS    '        ; Volume label. 11 bytes padded with spaces
ebr_sys_id:                 db 'FAT12   '           ; FAT File system type. 8 bytes padded with spaces



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

    ; Read something from disk
    ; BIOS Should set DL to drive number
    mov [ebr_drive_number], dl

    mov ax, 1           ; LBA = 1, second sector from disk
    mov cl, 1           ; 1 sector to read
    mov bx, 0x7E00      ; data should be after the bootloader
    call disk_read

    ; Print Message
    mov si, msg
    call puts

    cli                 ; disable interrupts, this way the CPU can't get out of the "halt" state
    hlt

floppy_error:
    mov si, msg_disk_read_failed
    call puts
    jmp wait_for_key_and_reboot

wait_for_key_and_reboot:
    mov ah, 0
    int 16h             ; Wait for keypress
    jmp 0FFFFh:0        ; Jump to beginning of BIOS, should reboot

.halt
    cli                 ; disable interrupts, this way the CPU can't get out of the "halt" state
    hlt


; Disk Startup routines

; Converts an LBA address to a CHS address
; The BIOS can only work with the CHS addressing scheme (Cylinder; Head; Sector on a Floppy/HDD. LBA stands for Logical Block Addressing)
; Params:
;   ax = LBA Address
; Returns
;   cx [bits 0-5]: sector number
;   cx [bits 6-15]: cylinder
;   dh: head
;
; Note how the registers are referenced: the counter register (cx) is divided into the lower 8 bits (ch) (BECAUSE LITTLE ENDIAN!!) 
; and cl which is the higher 8 bits.
; This means that the cx register is a 16-bit register with 8 + 8 = 16

lba_to_chs_conversion:
    push ax
    push dx                             ; Push ax and dx onto the stack to save their states

    xor dx, dx                          ; dx = 0
    div word [bpb_sectors_per_track]    ; ax = LBA / Sectors Per Track
                                        ; dx = LBA % Sectors Per Track
    inc dx                              ; dx = (LBA % Sectors Per Track + 1) = Sector
    mov cx, dx                          ; cx = Sector

    xor dx, dx                          ; dx = 0
    div word [bpb_heads]                ; ax = (LBA / Sectors Per Track) / Heads
                                        ; dx = (LBA / Sectors Per Track) % Heads
    mov dh, dl                          ; dh = head
    mov ch, al                          ; ch = cylinder (lower 8 bits)
    shl ah, 6
    or cl, ah                           ; put the upper 2 bits of cylinder in cl

    pop ax
    mov dl, al                          ; restore dl
    pop ax
    ret

; Reads sectors from a disk
; Params:
; - ax: LBA address
; - cl: number of sectors to read (up to 128)
; - dl: drive number
; - es:bx: memory address where to store read data
disk_read:
    push ax                             ; Save registers we will modify
    push bx
    push cx
    push dx
    push di

    push cx                             ; Push cx onto stack to save its state
    call lba_to_chs_conversion          ; compute CHS
    pop ax                              ; AL = number of sectors to read
    
    mov ah, 02h
    mov di, 3                           ; retry count. This is stored in a register we haven't used

.retry:
    pusha                               ; Save all registers, we don't know what BIOS modifies
    stc                                 ; Set carry flag, some BIOS' don't set it
    int 13h                             ; carry flag cleared = success

    jnc .done                           ; ^ Jump if no carry ^

    ; Read failed
    popa
    call disk_reset

    dec di
    test di, di
    jnz .retry

.fail:
    ; After all attempts failed
    jmp floppy_error

.done:
    popa

    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    ret


; Resets disk controller
; Params:
; - dl: drive number
disk_reset:
    pusha 
    mov ah, 0
    stc
    int 13h
    jc floppy_error
    popa
    ret


msg: db 'Hello World!', ENDL, 0
msg_disk_read_failed: db 'Failed to read floppy!', ENDL, 0

; All of the below is done after the program is executed, therefore, what we are seeing is what the bootloader is doing
times 510-($-$$) db 0   ; Padding 512 bytes with 0s
dw 0AA55h               ; This is the signature which the BIOS looks for when loading the bootloader