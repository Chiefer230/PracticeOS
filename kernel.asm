[BITS 64]
[ORG 0x200000]

start:

    mov rdi,idt                     ; Loads the Idt address
    mov rax,handler0                ; loads the Offset in the IDT address
    call SetHandler


    
    mov rax,timer                   ; Handler for timer
    add rdi, idt+32*16
    call SetHandler

    mov rdi, idt+32*16+7*16
    mov rax,SIRQ
    call SetHandler


    lgdt[Gdt64ptr]                 ; Load the GDT pointer 
    lidt [idtprt]
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

    


    push 8                          ; Stack Starting point, 8 bytes traversal
    push KernelEntry                ; Kernel starts 8 bytes after the Starting point
    db 0x48                         ; Override prefix size because return function is 32 bits and we need 64
    retf

KernelEntry:
    mov byte[0xb8000],'K'
    mov byte [0xb8001],0xa

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

    ;sti                             ; set the interrupt flag because interrupts were disabled when switching from real mode

    push 0x18|3                     ; Stack Segement Selector
    push 0x7c00                     ; Register Stack Pointer 
    push 0x202                      ; Bit 9, Return Flags,Interrupt is enabled
    push 0x10|3                     ; Code Segment Selector
    push UserEntry                  ;
    iretq
end:
    hlt
    jmp end
SetHandler:
    mov [rdi],ax                    ; Moves the value of ax(Lower 16 bits) into the rdi address value
    shr rax,16                      ; Shift 16 to get the Second offset location
    mov[rdi+6],ax                   ; Store second offset
    shr rax,16                      ; Shift 16 to get the third offset location
    mov [rdi+8],eax                 ; Store third offset
    ret
UserEntry:
    ;mov ax,cs                       ; Retrives the Binary Code Segment Descriptor
    ;and al,11b                      ; Checks the lower 3 bits
    ;cmp al,3                        ; Looking for Ring 3 access
    ;jne UEnd                        ; Not in Ring 3
    inc byte[0xb8010]           
    mov byte[0xb8011],0xF                     
UEnd:
    jmp UserEntry

handler0:

    ; The Push and pop operations allow the CPU to save the state of its general puprose registers when handling an interupt
    ; Copies all general puprose registers to the stack and pops them when exeception is handled
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15


    mov byte[0xb8000],'D'
    mov byte [0xb8001],0xc

    jmp end

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    iretq

timer:
 
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15


    inc byte[0xb8020]               ; Increment each time the handler is called
    mov byte [0xb8021],0xe

    mov al,0x20                     ; Acknowledges the interrupt and writes to the command register of the PIC
    out 0x20,al                 

    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax

    iretq
SIRQ:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15

    mov al,11
    out 0x20,al
    in al,0x20

    test al,(1<<7)
    jz .end
.end:
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
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

idt:
    %rep 256
        dw 0
        dw 0x8                       ; 
        db 0
        db 0x8e                      ; (Present)1 (DPL)00 (Type)01110 Interupt Gate Descriptor
        dw 0
        dd 0
        dd 0
    %endrep
idtlen: equ $-idt
idtprt:
    dw idtlen-1
    dq idt

Tss:
    dd 0                            ; First 4 bits are reserved
    dq 0x150000                     ; Interrupt Handler is called
    times 88 db 0                   ; Everything Else is 0
    dd TssLen                       
TssLen: equ $-Tss

