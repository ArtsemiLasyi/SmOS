macro outputreg reg
{
        push reg
        call regprint
}
macro output [arg]
{
        mov dx, arg
        call outputString
}

macro SetInterrupt addr, cs, ip
{
        push es
        push 0
        pop es
        mov word[es:4*addr], ip
        mov word[es:4*addr+2], cs
        pop es
}