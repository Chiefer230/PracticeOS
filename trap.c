#include "trap.h"

static struct IdtPointer idt_pointer;
static struct IdtDescriptor  vectors[256];

static void init_idt_entry(struct IdtDescriptor *entry, uint64_t IdtAddress, uint8_t attribute)
{
    entry->Offset1 = (uint16_t)IdtAddress;
    entry->selector = 8;
    entry->attributes = attribute;
    entry->Offset2 = (uint16_t) (IdtAddress>>16);
    entry->Offset3 = (uint32_t) (IdtAddress>>32);
}
// IDT Known Vectors with their Descriptor , Address, and the 8 bit attribute
// In this case the Atttrribute is set to 0x8e which is the 32 bit Interrupt Gate
void init_idt(void)
{
    init_idt_entry(&vectors[0],(uint64_t)vector0,0x8e);
    init_idt_entry(&vectors[1],(uint64_t)vector1,0x8e);
    init_idt_entry(&vectors[2],(uint64_t)vector2,0x8e);
    init_idt_entry(&vectors[3],(uint64_t)vector3,0x8e);
    init_idt_entry(&vectors[4],(uint64_t)vector4,0x8e);
    init_idt_entry(&vectors[5],(uint64_t)vector5,0x8e);
    init_idt_entry(&vectors[6],(uint64_t)vector6,0x8e);
    init_idt_entry(&vectors[7],(uint64_t)vector7,0x8e);
    init_idt_entry(&vectors[8],(uint64_t)vector8,0x8e);
    init_idt_entry(&vectors[10],(uint64_t)vector10,0x8e);
    init_idt_entry(&vectors[11],(uint64_t)vector11,0x8e);
    init_idt_entry(&vectors[12],(uint64_t)vector12,0x8e);
    init_idt_entry(&vectors[13],(uint64_t)vector13,0x8e);
    init_idt_entry(&vectors[14],(uint64_t)vector14,0x8e);
    init_idt_entry(&vectors[16],(uint64_t)vector16,0x8e);
    init_idt_entry(&vectors[17],(uint64_t)vector17,0x8e);
    init_idt_entry(&vectors[18],(uint64_t)vector18,0x8e);
    init_idt_entry(&vectors[19],(uint64_t)vector19,0x8e);
    init_idt_entry(&vectors[32],(uint64_t)vector32,0x8e);
    init_idt_entry(&vectors[39],(uint64_t)vector39,0x8e);
  
    // The pointer is set using 16 bits of the limit and 64 bits of the Base address to traverse the IDT 
    idt_pointer.limit = sizeof(vectors) -1;
    idt_pointer.IDTAddress = (uint64_t)vectors;
    load_idt(&idt_pointer);
}
void handler(struct TrapFrame *tf)
{
    unsigned char isr_value;

    switch (tf->trapno) {
        case 32:
            eoi();
            break;
            
        case 39:
            isr_value = read_isr();
            if ((isr_value&(1<<7)) != 0) {
                eoi();
            }
            break;

        default:
            while (1) { }
    }
}
