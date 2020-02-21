;===========================================================================;
regprint:
        push bp
        mov  bp,sp
        push di
        xor  di,di
        mov  cx,1
.Cycle:
        mov  dl,[bp + 5 + di]
        cmp  cx,1
        je   .continue
.second:
        ror  dl,4
        xor  cx,cx
        dec  di

.continue:
        shr  dl,4
        inc  cx
        cmp  dl,10
        jb  .digit

.letter: 
        add  dl,37h
        jmp  .loop

.digit:
        add  dl,30h

.loop:
        mov  ah,0x0E    ; номер функции BIOS
        mov  bh,0x00    ; страница видеопамяти
        mov  bl,0Fh
        mov  al,dl
        int  10h
        cmp  di,-2
        jne .Cycle
        pop  di
        pop  bp
        ret  2

;===========================================================================;
outputString:
        pusha
        push si
        mov ah, 0Eh
        mov bh, 0h
        mov bl, 0Fh
        mov si, dx
@@:
        mov al, byte[ds:si]
        cmp al, 0
        je @f
        int 10h
        inc si
        jmp @b
@@:
        pop si
        popa
        ret
;===========================================================================;