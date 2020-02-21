include 'macroses.m'
include 'constants.inc'
;======================================================================================================================;
Start:

        SetInterrupt 20h, KERNEL, Terminate

        mov ax, cs
        mov ds, ax           ; выбираем сегмент данных

        mov ah, $0F
        int 10h
        mov [bOldMode], al
        mov [bOldPage], bh

        mov ax, $0013
        int 10h

        push $A000
        pop  es

        xor ax, ax
        int 33h

        mov ax, 0001h
        int 33h

LoadScreen:
        mov [panel], 0
        mov [cursor], 0
        call _GetFilesAmount
        mov [numFiles], ax

Update:
        push BROWN
        push BLUE
        call _DrawScreen

        push cursor
        push panel
        push WHITE
        call _DrawPanel

        mov ah, 2
        mov bh, 0
        mov dh, 24
        mov dl, 0
        int 10h
        output strStart

        jc ReadKey
        call _SetTime

ReadKey:
        mov ah, 10h              ; ввод с клавиатуры
        int 16h

        cmp ah, 31               ;31 = 's'
        je DrawPanel

        cmp ah, 46               ;46 = 'c'
        je CommandLine

        cmp ah, 72               ;72 = UP
        je panelUP

        cmp ah, 80               ;80 = DOWN
        je panelDOWN

        cmp ah, 28               ;28 = ENTER
        je choice

        cmp ah, 33               ;33 = 'f'
        je StartApp

        jmp Update

choice:

        cmp [panel], 0
        je Update

        cmp [cursor], 0
        je  TotalCommander

        cmp [cursor], 1
        je Reboot

        jmp Update

panelUP:
        cmp [panel], 0
        je .endUP
        dec [cursor]
        cmp [cursor], -1
        jne .endUP
        mov [cursor], 1
.endUP:
        jmp Update

panelDOWN:
        cmp [panel], 0
        je .endDOWN
        inc [cursor]
        cmp [cursor], 2
        jne .endDOWN
        mov [cursor], 0
.endDOWN:
        jmp Update


DrawPanel:
        cmp [panel], 1
        je .dec
        mov [panel], 1
        jmp .call
.dec:
        mov [panel], 0
.call:
        push cursor
        push panel
        push WHITE
        call _DrawPanel

        jmp Update

StartApp:
        pusha
        push ds fs gs es
        pushf

        push COM_START+16
        pop gs
        mov si, si
        int 85h

        push COM_START
        pop es
        mov byte[es:0], 0CDh            ;Кладём в первые 2 байта сегмента COM_START int 20h
        mov byte[es:1], 20h
        pop es


        push COM_START
        pop es

        mov word[es:2], sp
        mov word[es:4], ss


        mov ax, COM_START
        mov ds, ax
        mov fs, ax
        mov gs, ax
        mov es, ax
        mov ss, ax
        mov sp, 0xFFFE
        push 0
        jmp COM_START:100h

Return:
        popf
        pop es gs fs ds
        popa

        jmp Start


TotalCommander:
        call _CreateWindow
        jmp Update


CommandLine:
        mov ah,$0F
        int 10h
        mov [bbOldMode], al
        mov [bbOldPage], bh

        mov ax, $0003
        int 10h

        push $B800
        pop  es

        call _cmdClearScreen
        call _cmdWork
        jmp CommandLine


;=====================================================================================================================;
;  Обновить время
;=====================================================================================================================;
_UpdateTime:
        push ax
        mov ah,2h               ;получение времени
        int 1ah
        pop ax
        ret
;=====================================================================================================================;
;  Установить время
;=====================================================================================================================;
_SetTime:
        call _UpdateTime
        mov ah,2h               ;установка курсора
        mov bh,0
        mov dh,0
        mov dl,0
        int 10h

        outputreg cx
        ret
;=====================================================================================================================;
;  ПРЕРЫВАНИЕ 20h
;   завершение COM-программы
;=====================================================================================================================;
Terminate:
        mov ax, COM_START
        mov es, ax
        mov sp, word[es:2]
        mov ss, word[es:4]

        mov ax, KERNEL
        mov ds, ax
        mov fs, ax
        mov gs, ax
        mov es, ax

        jmp KERNEL:Return
        iret
;=====================================================================================================================;
;  Отрисовка панели
;    bp + 6 -  положение курсора
;    bp + 4 -  переменная состояния панели
;    bp + 2 -  цвет панели
;=====================================================================================================================;
_DrawPanel:
        push bp
        mov bp, sp
        push bx
        push di
        xor bx, bx
        mov bl, byte[bp + 5]
        mov cx, word[bp + 2]

        cmp [panel], 0
        je .finish
.call:
        push cx
        push 152
        push 100
        push 320*40
        call _DrawRect

        mov di,320*72
        mov dx,[cursor]
.cycle:
        cmp dx, 0
        je .continue
        dec dx
        add di,320*32
        jmp .cycle

.continue:
        push BLACK
        push 8
        push 100
        push di
        call _DrawRect

        ;mov ah, 2
        ;mov bh, 0
        ;mov dh, 9
        ;mov dl, 0
        ;int 10h
        ;output strCommandLine

        mov ah, 2
        mov bh, 0
        mov dh, 9
        mov dl, 0
        int 10h
        output strFiles

        mov ah, 2
        mov bh, 0
        mov dh, 13
        mov dl, 0
        int 10h
        output strExit

.finish:
        pop di
        pop bx
        pop bp
        ret 4

;=====================================================================================================================;
;  Отрисовка экрана
;    bp + 4 - цвет основного поля
;    bp + 2 - цвет нижнего поля
;=====================================================================================================================;
_DrawScreen:
        push bp
        mov bp, sp

        xor di, di
        push word[bp + 4]
        push 192
        push 320
        push 0
        call _DrawRect

        push word[bp + 2]
        push 8
        push 320
        push 320*192
        call _DrawRect
        pop bp
        ret 4

;=====================================================================================================================;
;  Отрисовка прямоугольника
;    bp + 4 - координаты верхнего левого угла прямоугольника
;    bp + 6  - ширина прямоугольника
;    bp + 8  - высота прямоугольника
;    bp + 10  - цвет прямоугольника
;=====================================================================================================================;
_DrawRect:
        push bp
        mov bp,sp
        push di
        push bx

        mov dx,[bp+8]
        mov di,[bp+4]
.Cycle:
        mov al,byte[bp+10]
        mov cx,[bp+6]
        rep stosb

        mov bx,[bp+6]
        neg bx
        add bx,320
        add di,bx
        dec dx
        jnz .Cycle

        pop bx
        pop di
        pop bp
        ret 8
;=====================================================================================================================;
; Сравнение двух строк
;   bp + 4 - адрес первой строки
;   bp + 2 - адрес второй строки
;=====================================================================================================================;
_StringCompare:
        push bp
        mov bp, sp
        push di
        push si

        mov di, [bp + 4]
        mov si, [bp + 2]

.cycle:
        mov ch,byte[si]
        cmp byte[di],ch
        jne .notequal
.end:
        cmp byte[di],0
        je .equal

.continue:
        inc di
        inc si
        jmp .cycle


.equal:
        mov ax, 1
        jmp .finish

.notequal:
        mov ax, 0
        jmp .finish

.finish:
        pop si
        pop di
        pop bp
        ret


;=====================================================================================================================;
;  Очистка экрана коммандной строки
;=====================================================================================================================;
_cmdClearScreen:
        push di
        pusha

        mov bx, 25
        xor di, di
.DrawLoop:
        mov ax, $0700 or ' '
        mov cx, 80
        rep stosw
        dec bx
        jnz .DrawLoop
        popa
        pop di
        ret

Reboot:
        db 0xEA            ;машинный код jump FFFF:0000
        dw 0x0000,0xFFFF
;=====================================================================================================================;
;  Работа с коммандной строкой
;=====================================================================================================================;
_cmdWork:
        pusha

        mov ax, 0002h   ;очищаем экран
        int 10h
         
        mov dx,0h
        call SetCursorPos

        mov bp, cmdMessage
        mov cx, 20
        mov bl, 04h
        xor bh, bh
        mov ax, 1301h
        int 10h             ;вывод приглашения к вводу команды
         
        add dh,2            ;переводим курсор на один пункт вниз для ввода команды
        call SetCursorPos
        mov si,0
         
.Command:
        mov ah,10h
        int 16h

        cmp ah, 0Eh     ;Если нажата клавиша BackSpase - удалить символ
        jz .Delete_symbol

        cmp al, 0Dh
        jz .Input_Command

        cmp ah, 1
        popa
        je Start

        mov [cmdString+si],al
        inc si
        mov ah,09h
        mov bx,0004h
        mov cx,1
        int 10h
        add dl,1
        call SetCursorPos
        jmp .Command
         
.Input_Command:      ;Если нажат Enter, то переходим в третий сектор
        mov di,cmdString
        push si
        mov si,cmdExit
        mov cx,5
        rep cmpsb ;сравниваем строки - если команда exit, то переходим
        je .exit
        pop si
        jmp .Command
         
.Delete_symbol:
        cmp dl,0
        jz .Command
        sub dl,1        ;сдвигаем курсор влево
        call SetCursorPos
        mov al,20h      ;вместо уже напечатанного символа выводим пробел
        mov [cmdString + si],al ;стираем символ в строке
        mov ah,09h
        mov bx,0004h
        mov cx,1
        int 10h
        dec si          ;уменьшаем кол-во напечатанных символов
        jmp .Command
         
.exit:
        popa
        jmp Start
 
SetCursorPos:        ;установка курсора
        mov ah,2h
        xor bh,bh
        int 10h 
        ret
;=====================================================================================================================;
;  Отрисовка окна и обрабатывание его сообщений
;=====================================================================================================================;
_CreateWindow:
        pusha
        mov [windowCursor], 0

.Update:
        call _SetTime

        push BROWN
        push 16
        push 200
        push 320*16+50
        call _DrawRect

        push BLACK
        push 100
        push 200
        push 320*32+50
        call _DrawRect


.CursorCount:
        push di
        mov di, 320*32+50
        mov dx, [windowCursor]

.cycle:
        cmp dx, 0
        je .DrawCursor
        dec dx
        add di, 320*8
        jmp .cycle


.DrawCursor:
        push RED
        push 8
        push 200
        push di
        call _DrawRect
        pop di

.ShowFiles:
        call _ShowFiles


.ReadKey:
        mov ah, 10h              ; ввод с клавиатуры
        int 16h

        cmp ah, 72               ;72 = UP
        je .CursorWindowUP

        cmp ah, 80               ;80 = DOWN
        je .CursorWindowDOWN

        cmp ah, 28               ;28 = ENTER
        je .CursorWindowChoice

        cmp ah, 1                ;1  = ESCAPE
        je .finish

        jmp .Update

.CursorWindowUP:
        dec [windowCursor]
        cmp [windowCursor], -1
        jne .endCursorWindowUP
        mov ax,[numFiles]
        dec ax
        mov [windowCursor], ax
.endCursorWindowUP:
        jmp .Update

.CursorWindowDOWN:
        mov ax, [numFiles]
        inc [windowCursor]
        cmp [windowCursor], ax
        jne .endCursorWindowDOWN
        mov [windowCursor], 0
.endCursorWindowDOWN:
        jmp .Update

.CursorWindowChoice:
        push windowCursor
        call _GetAppName
        mov si, ax
        jmp StartApp
        jmp .Update

.finish:
        popa
        ret
;=====================================================================================================================;
_GetFilesAmount:
        push bp
        mov bp, sp

        push di
        push es
        push bx

        mov bx, Finish
        push KERNEL
        pop es
        mov ax, 19            ; Начало сектора с корневой директорией
        mov cx, 14            ; Размер корневой директории
        int 86h

        mov di, Finish

        mov cx, 224           ; Проходим по всей корневой директории
        xor dx, dx
        xor ax, ax

.NextFilename:
        cmp byte[di], 0
        je .NextAttempt

        cmp byte[di], 65
        je .NextAttempt
        inc ax

.NextAttempt:
        add dx, 32
        mov di, Finish        ; Переходим к следующему имени
        add di, dx

        loop .NextFilename
.End:
        pop bx
        pop es
        pop di
        pop bp
        ret

;=====================================================================================================================;
_ShowFiles:
        push bp
        mov bp, sp

        push di
        push es
        push bx

        mov bx, Finish
        push KERNEL
        pop es
        mov ax, 19            ; Начало сектора с корневой директорией
        mov cx, 14            ; Размер корневой директории
        int 86h

        push KERNEL
        pop es
        mov di, Finish

        mov cx, 224           ; Проходим по всей корневой директории
        xor ax, ax
        mov dh, 3
.NextFilename:
        push ax

        cmp byte[di], 0
        je .NextAttempt

        cmp byte[di], 65
        je .NextAttempt

        mov ah, 2
        mov bh, 0
        add dh, 1
        mov dl, 7
        int 10h

        push cx
        mov cx, 11
.cycle:
        mov ah, 0eh
        mov al, byte[di]
        inc di
        mov bl, RED
        int 10h
        loop .cycle

        pop cx

.NextAttempt:
        pop ax
        add ax, 32
        mov di, Finish        ; Переходим к следующему имени
        add di, ax

        loop .NextFilename
.End:
        pop bx
        pop es
        pop di

        pop bp
        ret
;=====================================================================================================================;
_GetAppName:
        push bp
        mov bp, sp
        push di
        push bx
        push es

        mov bx, [bp + 4]
        push bx

        mov bx, Finish
        push KERNEL
        pop es
        mov ax, 19            ; Начало сектора с корневой директорией
        mov cx, 14            ; Размер корневой директории
        int 86h

        pop bx

        mov di, Finish

        mov cx, word[bx]
        xor dx, dx

.NextFilename:
        cmp byte[di], 0
        je .NextAttempt

        cmp byte[di], 65
        je .NextAttempt

        cmp cx, 0
        je .FileFound
        dec cx
        jmp .NextAttempt

.FileFound:
        mov ax, di

        jmp .End

.NextAttempt:
        add dx, 32
        mov di, Finish        ; Переходим к следующему имени
        add di, dx

        jmp .NextFilename


.End:
        pop es
        pop bx
        pop di
        pop bp
        ret
;=====================================================================================================================;
include 'procedures.c'
Mydata:
        bOldPage db ?
        bOldMode db ?
        bbOldPage db ?
        bbOldMode db ?
        strStart db "START",0
        strFiles db "Files",0
        strCommandLine db "CMD",0
        cmdMessage db 'Input the command...',0
        cmdExit db 'exit',0
        cmdString db 5 dup(?)     ;буфер для ввода команды
        strExit db "Reboot",0
        ERROR db "ERROR!",0
        testGame db 12 dup (0)
        pcman db "PCMAN   COM",0
        FARJMP_temp dd ?
        panel dw 0
        cursor dw 0
        windowCursor dw 0
        numFiles dw 0
        diskNum db 0
        fileName dw 0
        Buffer rb 100
Finish: