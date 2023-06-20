[BITS 16]
[ORG 0x7e00]

start:
    mov [DriveId],dl


    mov eax,0x80000000     ; Passes parameter for cpuid
    cpuid                  ; Get the information of the processor                   
    cmp eax,0x80000001     ; Checks if it supports the parameter value for the Cpu
    jb NotSupport
    
    mov eax,0x80000001     ; Parameter for cpuid to return long mode and 1 gb support flag
    cpuid                  ; this stores values into eax,ebx,ecx,and edx registers
    
    
    test edx,(1<<29)       ; edx contains information about long mode and 1gb support, 1 shifted by 29 checks the long mode support flag 
    jz NotSupport
    test edx,(1<<26)       ; edx contains information about 1gb supports, 1 shifted by 26 checks the 1 gb support flag
    jz NotSupport
    
   

LoadKernel:
    mov si,ReadPacket  ; Holds the address of read packet
    mov word[si],0x10   ; Holds the size of packet, 16 bytes
    mov word[si+2],100    ; Number of sectors which is 100, enough space for kernel 50KB
    mov word[si+4],0   ; Offset
    mov word[si+6],0x1000      ; Physical Address/ segment is 0x10000
    mov dword[si+8],6       ; 64 bit logical block address
    mov dword[si+0xc],0
    mov dl,[DriveId]
    mov ah, 0x42            ; reads the hard disk 
    int 0x13
    jc ReadError
GetMemInfoStart:

    mov eax,0xe820         ;BIOS command to detect memory
    mov edx,0x534d4150     ; magic number 
    mov ecx,20             ; ask for 20 bytes of entry for 2 unsigned 64 and 32 
    mov edi,0x9000
    xor ebx,ebx            ; checks if the ebx is 0
    int 0x15               ;BIOS function to check for memory        
    jc NotSupport

GetMemInfo:
    add edi,20
    mov eax,0xe820         ;BIOS command for memory 
    mov edx,0x534d4150     ; Magic number
    mov ecx,20             ; ask for 20 bytes for memory entries
    int 0x15               ;BIOS function in conjunction with 0xe820
    jc GetMemDone   

    test ebx,ebx           ; if the zero flag is not set, jump to mem info
    jnz GetMemInfo

    
GetMemDone:

TestA20:
    mov ax,0xffff                   ; 1MB higher than the boot sector address at 0x7c00
    mov es,ax                       ;Copy ax value into es register
    mov word[ds:0x7c00],0xa200      ;Write random number to address 0x7c00 in the data segment register
    cmp word[es:0x7c10],0xa200      ;Compare the same random number to address 1MB higher than the boot address
    jne SetA20LineDone              ;if the 20th bit is not equal in both random numbers, then the A20 line is enabled
    mov word[ds:0x7c00],0xb200
    cmp word[es:0x7c10],0xb200
    je End
SetA20LineDone:
    xor ax,ax
    mov es,ax
SetVideoMode:
    mov ax,3
    int 0x10

    cli                             ; Clears the interupts before proceeding into protected mode, this always has to be checked
    lgdt [Gdt32pointer]             ; Loads a Linear Address with a 16 bit limit and 32 bit address
    lidt [idt32ptr]                 ; loads a linear Address with a 16 bit limit and 32 bit address
    mov eax, cr0                    ; Protected Mode Enable, Read from Control Register
    or eax,1                        ; Write a 1 to the eax
    mov cr0,eax                     ; write the 1 into the Control register

    jmp 8:PMEntry                   ; jump 8 bytes because the GDT starts 8 bytes away                   


ReadError:
NotSupport:
End:
    hlt
    jmp End


; Protected Mode has to run in 32 bit mode
; Load the Segement registers 16 bytes away from th GDT staring address
[BITS 32]
PMEntry:
    mov ax,0x10                     ; Load in the Kernal Mode Data Segement
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,0x7c00                  ; Set the stack pointer to boot address

    ;Page table creation
    cld                             ; Clear the direction flag
    mov edi,0x80000                 ;
    xor eax,eax
    mov ecx,0x10000/4
    rep stosd

    mov dword[0x80000],0x81007
    mov dword[0x81000],10000111b

    lgdt [Gdt64ptr]                 ; Load the gdt pointer
    
    mov eax, cr4                    ; Set up the PAE bit
    or eax,(1<<5)                   ; Flip the PAE bit which is the fifth bit
    mov cr4,eax                     ; Enabled PAE

    mov eax,0x80000                 ; Copy the Page table into the control register
    mov cr3,eax

    mov ecx,0xc0000080              ; Set this to the EFER MSR
    rdmsr                           ;Read from model specfic Register
    or eax,(1<<8)                   ; Set the long mong bit 
    wrmsr                           ; write to model specific Register

    mov eax,cr0                     ; Set up Paging
    or eax,(1<<31)                  ; Check the 31st bit to enable paging
    mov cr0,eax                     ; flip the paging bit in the control register

    jmp 8:LMEntry

PEnd:
    hlt
    jmp PEnd

[BITS 64]
LMEntry:
    mov rsp,0x7c00

    cld                             ; Changes the Direction Flag of the Data, Goes Fowards
    mov rdi,0x200000                ; moves kernel into the Destination 0x200000
    mov rsi,0x10000                 ; The kernel is loaded from 0x10000
    
    
    mov rcx,51200/8                 ; Determines the Size of the Kernel and is used as a counter
    rep movsq                       ; Copy the Size of the kernel which is 100 sectors


    jmp 0x200000                    ; Jump to the Kernel's new address


LEnd:
    hlt
    jmp LEnd


Gdt32:
    dq 0


; Kernel Mode Code Segment
Code32:
    dw 0xffff   ;Limit which is 4gb
    dw 0
    db 0
    db 0x9a     ; Access Byte 
    db 0xcf     ; Flag for 32 bits
    db 0
Data32:
    dw 0xffff   ; limit which is 4gb
    dw 0
    db 0
    db 0x92     ; Access Byte 
    db 0xcf     ; Flag for 32 bits
    db 0
Gdt32Len: equ $-Gdt32
Gdt32pointer: dw Gdt32Len-1     ; 24 bits
              dd Gdt32          ; 32 bits
idt32ptr: dw 0
          dd 0
Gdt64:
    dq 0
    dq 0x0020980000000000            ; Code Segement for the second entry of the Descriptor
                                     ; (Flags)0010 (Limit)0000 (Access Bytes)10011 for the hex entry in binary

Gdt64ptr:
    dw Gdt64len-1
    dd Gdt64
Gdt64len: equ $-Gdt64
DriveId: db 0
Message: db "Text Mode is set"
MessageLen: equ $-Message
ReadPacket: times 16 db 0