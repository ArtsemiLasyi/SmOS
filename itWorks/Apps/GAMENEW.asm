KEY_ESCAPE      = 1
KEY_LEFT        = 75
KEY_RIGHT       = 77

org 100h

EntryPoint:
        mov     ax, $0003
        int     10h

        push    $B800
        pop     es

        mov     [wBorder], 40
.GameLoop:
        call    DrawDesk

        xor     ax, ax
        int     16h


        cmp     ah, KEY_ESCAPE
        je      Finish

        cmp     ah, KEY_LEFT
        je      .Decrease

        cmp     ah, KEY_RIGHT
        je      .Increase

        jmp     .GameLoop

.Decrease:
        sub     [wBorder],1
        jmp     .End_cycle

.Increase:
        add     [wBorder],1

.End_cycle:
        cmp     [wBorder],0
        je      Finish
        cmp     [wBorder],80
        je      Finish
        jmp     .GameLoop




Finish:
        mov     ax, ax
        int     16h

        call    PrintHex
        mov     [wBorder],40
        xor     ax, ax
        int     16h
        call    DrawDesk
        ret


;==============================;
PrintHex:
        mov     cx, 4
.PrintLoop:
        rol     dx, 4
        mov     ax, dx
        and     ax, $000F

        cmp     al, 10
        sbb     al, $69
        das

        mov     bl, $07
        mov     ah, $0E
        int     10h
        loop    .PrintLoop
        ret

DrawDesk:
        mov     bx, 25
        xor     di, di
.DrawLoop:
        mov     ax, $0700 or 176
        mov     cx, [wBorder]
        rep stosw

        mov     ax, $0700 or 178
        mov     cx, 80
        sub     cx, [wBorder]
        rep stosw

        dec     bx
        jnz     .DrawLoop
        ret

wBorder         dw      ?
game            db      "Game is over",0