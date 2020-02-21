        org 100h
KEY_ESCAPE      = $01
KEY_LEFT        = 75
KEY_RIGHT       = 77
KEY_UP          = 72
KEY_DOWN        = 80

Start:
        mov     ah, $0F
        int     10h
        mov     [oMode], al
        mov     [oPage], bh


        mov     ax,$0003
        int     10h

        push     $B800
        pop      es
        call     _HelloScreen
        call     _ReadKey


        mov     ax, $0013
        int     10h

        push    $A000
        pop     es

        xor     di,di

Game:
        call    _DrawField
        call    _DrawMan
        call    _ReadKey
        cmp     ah,KEY_ESCAPE
        je      Finish
        cmp     ah,KEY_UP
        je      .MoveUp
        cmp     ah,KEY_DOWN
        je      .MoveDown
        cmp     ah,KEY_RIGHT
        je      .MoveRight
        cmp     ah,KEY_LEFT
        je      .MoveLeft
        jmp     .Continue

.MoveDown:
        add     di,320*5
        jmp     .Continue

.MoveUp:
        sub     di,320*5
        jmp     .Continue

.MoveRight:
        add     di,5
        jmp     .Continue
.MoveLeft:
        sub     di,5

.Continue:
        jmp     Game


Finish:
        mov     ax,$0003
        int     10h

        push     $B800
        pop      es

        call    _ScreenEnd
        call    _ReadKey
        call    _End
        ret

           ;PROCEDURES;
;===========================================;
_HelloScreen:
        xor     di,di
        mov     cx,80
        mov     ax,$0700 or "="
        rep     stosw

        mov     cx,80
        mov     ax,$0700 or "X"
        rep     stosw

        mov     dx,21
.Cycle:
        mov     cx,1
        mov     ax,$0700 or "X"
        rep     stosw

        mov     cx,78
        mov     ax,$0700 or " "
        rep     stosw

        mov     cx,1
        mov     ax,$0700 or "X"
        rep     stosw

        dec     dx
        jnz     .Cycle

        mov     cx,80
        mov     ax,$0700 or "X"
        rep     stosw

        mov     cx,80
        mov     ax,$0700 or "="
        rep     stosw
        ret
;================================================;

_ScreenEnd:
        mov     bx, 25
        xor     di, di
.DrawLoop:
        mov     ax, $0700 or 177
        mov     cx,80
        rep     stosw
        dec     bx
        jnz     .DrawLoop
        ret

;=================================================;
_DrawMan:
        push    di
        mov     si,Warrior
        mov     dx,20
.Cycle:
        mov     cx,20
        rep     movsb
        add     di,300
        cmp     dx,0
        je      .Stop
        dec     dx
        jmp     .Cycle
.Stop:
        pop     di
        ret
;=================================================;
_ReadKey:
        xor     dx, dx
        mov     ah,0
        int     16h
.Ret:
        ret
;=====================================================;
_End:
        movzx   ax, [oMode]
        int     10h
        mov     ah, $05
        mov     al, [oPage]
        int     10h
        ret
;======================================================;
_DrawField:
        push    di
        xor     di,di
        mov     cx,320*200
        mov     al,0
        rep     stosb
        pop     di
        ret

                       ;DATA;
;=====================================================;
Press           db      "Press any key...$"
oMode           db      ?
oPage           db      ?
Warrior         db      0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\
                        0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\
                        0,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\
                        0,7,0,0,0,0,0,0,6,6,6,6,6,6,0,0,0,0,0,0,\
                        0,7,0,0,0,6,6,6,6,6,6,6,6,6,6,6,0,0,0,0,\
                        0,7,0,0,6,6,6,6,6,6,6,6,6,6,6,6,6,6,0,0,\
                        0,7,0,0,6,2,0,2,2,6,6,2,2,0,2,2,2,6,0,0,\
                        0,7,0,0,6,2,2,2,2,2,2,2,2,2,2,2,2,6,0,0,\
                        0,7,0,0,6,2,2,15,15,15,15,15,15,15,2,2,2,6,0,0,\
                        14,14,14,0,0,2,2,2,15,15,15,15,2,2,2,2,2,0,0,0,\
                        0,7,0,0,0,2,2,2,2,2,2,2,2,14,14,14,14,14,0,0,\
                        0,2,2,2,3,3,3,3,3,3,3,14,14,14,14,14,14,14,14,14,\
                        0,7,0,0,3,3,3,3,3,3,3,14,14,14,14,14,14,14,14,14,\
                        0,0,0,0,0,3,3,3,3,3,3,14,14,14,14,14,14,14,14,14,\
                        0,0,0,0,0,3,3,3,3,3,3,3,14,14,14,14,14,14,14,0,\
                        0,0,0,0,0,3,3,3,3,3,3,3,3,3,14,14,14,0,0,0,\
                        0,0,0,0,0,4,4,4,4,4,4,4,4,4,4,14,4,0,0,0,\
                        0,0,0,0,0,4,0,0,0,0,0,0,0,0,0,0,4,0,0,0,\
                        0,0,0,0,6,6,0,0,0,0,0,0,0,0,0,6,6,0,0,0


