section .data
Gdt64:
    dq 0
    dq 0x0020980000000000            ; Code Segement for the second entry of the Descriptor
    dq 0x0020f80000000000            ; Ring 3 DPL value hence the f value
    dq 0x0000f20000000000            ;  Data Segment (Ring 3) and is writable 
                                     ; (Flags)0010 (Limit)0000 (Access Bytes)10011 for the hex entry in binary

TssDesc:
    dw TssLen-1                      ; Lower bits of the TSS limit 
    dw 0                             ; Base address is 0
    db 0                             ; Base address is 0
    db 0x89                          ; 1(Present bit) 00(DPL) 01001(Type) in Hex
    db 0                             ; The Rest of the fields are set to Zero
    db 0
    dq 0

Gdt64ptr:
    dw Gdt64len-1
    dq Gdt64                         ; Loaded as a quad word instead of double word in 64 bit 
Gdt64len: equ $-Gdt64



Tss:
    dd 0                            ; First 4 bits are reserved
    dq 0x150000                     ; Interrupt Handler is called
    times 88 db 0                   ; Everything Else is 0
    dd TssLen                       
TssLen: equ $-Tss

section .text

extern Kmain
global start
start:

  
    lgdt[Gdt64ptr]                 ; Load the GDT pointer 
SetTss:
    mov rax,Tss                     ; Copy the address into the rax
    mov[TssDesc+2],ax               ; The lower 16 bits of the address is in the 3rd bytes of the descriptor
    shr rax,16                      ; shift by 16 and the bits 16-23 are in al now
    mov [TssDesc+4],al
    shr rax,8                       ; shift by 8 and the bits of 24-31 are in al
    mov[TssDesc+7],al               ; store into the 
    shr rax,8                       ; shift to get the remaining 32 bits                      
    mov[TssDesc+8],eax              ; store the remaining 63-32 bits into the 8th byte

    mov ax,0x20                     ; Descriptor of the TSS in the GDT
    ltr ax                          ; the acutal load

    


    

InitPIT:
    mov al,0x34                     ; Sets the Command port to 0x36 where it is put in repeating mode
    out 0x43,al                     ; 0x43 is the command byte where 

    mov ax,11931                    ; Divides the Input Clock by the frequency for the PIT
    out 0x40,al                     ; Send the lower bytes to IRQ0
    mov al,ah                       ; Set the higher Bytes to the Lower Bytes
    out 0x40,al                     ; Send teh higher Bytes to the IRQ0
InitPIC:
    mov al,0x11                     ; Initalization Command to set up the PIC
    out 0x20,al                     ; 0x20 is the master PIC IO base address
    out 0xa0,al                     ; 0xa0 is the slave PIC IO base address

    ; PIC Offset Master and Slave Offsets
    mov al,32                       ; Starting Vector for the Master
    out 0x21,al                     ; 0x21 is the Master Data register
    mov al,40                       ; Starting Vector for the Slave after the Master's Vector
    out 0xa1,al                     ; 0xa1 is the Slave Data register

    ; This is the First Command indicating Which IRQ is used for connecting the PIC chips
    mov al,4                        ; Master IRQ2 being used by the Slave PIC
    out 0x21,al
    mov al,2                        ; Slave PIC its identity
    out 0xa1,al

    mov al,1                        ; Indicating that the 8086 mode is being used 
    out 0x21,al
    out 0xa1,al


    mov al,11111110b                ; Enables the masking of the IRQ where only IRQ0 will be used
    out 0x21,al                     ; Sends this to the Master
    mov al,11111111b                ; Mask all the Slave IRQs
    out 0xa1,al

    push 8                          ; Stack Starting point, 8 bytes traversal
    push KernelEntry                ; Kernel starts 8 bytes after the Starting point
    db 0x48                         ; Override prefix size because return function is 32 bits and we need 64
    retf

KernelEntry:
    xor ax,ax
    mov ss,ax
    
    
    mov rsp, 0x200000
    
    
    
    call Kmain
    sti
   
end:
    hlt
    jmp end
                   



