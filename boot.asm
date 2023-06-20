[BITS 16]     ;Running at a 16 bit Mode
[ORG 0x7c00]  ;First Sector of the Memory Disk

;Segement Register all to 0
start:
    xor ax,ax
    mov ds,ax
    mov es,ax
    mov ss,ax
    ;Sets Starting point for the Stack, Where the program begins
    mov sp, 0x7c00

TestDiskExtension:
    mov [DriveId],dl ;Transfers Control to the boot Code, Write into memory with Brackets
    mov ah, 0x41     ; 0x41 is a BIOS operation that checks Extensions    
    mov bx, 0x55aa   ; End of the Sector, Last 2 bytes 
    int 0x13        ; Real Mode Interupt in BIOS. Provides read/write operations using CHS
    jc NotSupport
    cmp bx,0xaa55   ;Last 2 bytes containing the first sector of the Boot disk or the MBR
    jne NotSupport

LoadLoader:
    mov si,ReadPacket  ; Holds the address of read packet
    mov word[si],0x10   ; Holds the size of packet, 16 bytes
    mov word[si+2],5    ; Number of sectors which is 5, enough space for loader
    mov word[si+4],0x7e00   ; Offset
    mov word[si+6],0        ; Physical Address/ segment is 0x7e00
    mov dword[si+8],1       ; 64 bit logical block address
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah, 0x42            ; reads the hard disk 
    int 0x13
    jc ReadError

    mov dl,[DriveId]
    jmp 0x7e00
ReadError:
NotSupport:
    mov ah, 0x13    ;Print String
    mov al,1        ;Curosr at the end of the String
    mov bx,0xa      ; Print in bright Green
    xor dx,dx       ; Sets the value to Zero
    mov bp,Message
    mov cx,MessageLen   ; Number of Character based on the end index and start character
    int 0x10


End:
    hlt             ;Blocking State
    jmp End        

DriveId: db 0
Message: db "We have an Error in Boot Process"
MessageLen: equ $-Message
ReadPacket: times 16 db 0; size of the Packet is 16 bytes

;Creates the Partition Table
times (0x1be-($-$$)) db 0   ;Starts at 0x1be and pads the table with 0s
    db 80h          ;Bootable Partition
    db 0,2,0        ;Starting CHS Cylinder Head Addressing
    db 0f0h         ;type
    db 0ffh,0ffh,0ffh   ;ending CHS
    dd 1            ;Starting Sector
    dd (20*16*63-1) ;Size

    times (16*3) db 0       ; Pads the remaining space within the partition table with 0s

    ;Form the Boot Sector Signature for the BIOS to identify
    db 0x55
    db 0xaa
