use16
org 7C00h
include 'macroses.m'
KERNEL = 90h              ;адрес, по которому будет загружено ядро
BUFFER = 200h             ;память, которая идет после загрузочного сектора

Start:
;================================================================================================================================;
                                                     ;FAT12. BPB STRUCTURE;
;================================================================================================================================;
jmp bootloader
db 0
BS_OEMName     db      "MSWIN4.1"         ;вроде как не играет роли, но для отсутствия проблем с совместимостью лучше так
BPB_BytsPerSec dw      512                 ;количество байтов в секторе
BPB_SecPerClus db      1                   ;количество секторов в кластере. Допустимы: 1,2,4,8,16,32,64 и 128(см. Примечания п.1)
BPB_RsvdSecCnt dw      1                   ;количество зарезервированных секторов в зарезервированной области тома (для FAT12 - 1)
BPB_NumFATs    db      2                   ;количетство структур данных FAT на томе (лучше всего 2)
BPB_RootEntCnt dw      224                 ;для тома FAT12 это поле содержит количество 32-байтовых записей каталога в корневом каталоге.
BPB_TotSec16   dw      2880                ;для тома FAT12 это поле содержит количество секторов  (1440*1024/512)
BPB_Media      db      0xF0                ;для съемных носителей часто используется 0xF0
BPB_FATSz16    dw      9                   ;данное поле для FAT12 - 16-битный счетчик секторов, занятых одним томом.
BPB_SecPerTrk  dw      18                  ;секторов на дорожку (трек) для прерывания 0x13
BPB_NumHeads   dw      2                   ;количество головок для прерывания  0x13. для 3,5''-дисковода гибких дисков на 1,44 МБ - 2
BPB_HiddSec    dd      0                   ;количество скрытых секторов, предшествующих разделу, который содержит этот том FAT
BPB_TotSec32   dd      0                   ;это поле - новое 32-разрядное общее количеством секторов в томе
BS_DrvNum      db      0                   ;Int 0x13 номер привода. Это поле фактически зависит от операционной системы
BS_Reserved1   db      0                   ;зарезервировано. Код,форматирующий тома FAT, должен всегда устанавливать этот байт в 0.
BS_BootSig     db      0x29                ;расщиренная загрузочная подпись. Указывает на наличие следующих трех полей в загрузочном секторе
BS_VolID       dd      ?                   ;серийный номер тома
BS_VolLab      db      'COOLLABEL  '       ;метка тома (11 байт)
BS_FilSysType  db      'FAT12   '          ;поле на самом деле не является частью BPB. Носит чисто иныормационный характер
;================================================================================================================================;

bootloader:
        mov ax,cs
        mov ds,ax
        mov es,ax
        mov ss,ax
        mov sp,7C00h

        mov byte [diskNum], dl


        SetInterrupt 86h, 0, ReadSectorsFromDisk
        SetInterrupt 85h, 0, LoadFileFromDisk
        SetInterrupt 80h, 0, Debug

        push KERNEL
        pop gs
        mov si, kernName
        int 85h

        mov dl, byte[diskNum]

        mov ax, KERNEL
        mov ds, ax
        mov es, ax
        mov fs, ax
        mov gs, ax
        mov ax, 6C0h
        mov ss, ax
        mov sp, 0xFFFE
        jmp KERNEL:0000h


;================================================================================================================================;
                                     ;ПРОЦЕДУРЫ;
;================================================================================================================================;
Reboot:
        xor ax, ax
        int 16h
        xor ax, ax
        int 19h

ResetFloppy:
        push ax
        push dx
        xor ax,ax
        mov dl, byte [diskNum]
        int 13h
        pop dx
        pop ax
        ret

;================================================================================================================================;
;  ПРЕРЫВАНИЕ 85h
;    int 85h - загрузить файл
;    GS:BX - адрес буфера
;    SI - имя файла
;================================================================================================================================;
LoadFileFromDisk:

        mov bx, FATData
        push 0
        pop es
        mov ax, 19            ; Начало сектора с корневой директорией
        mov cx, 14            ; Размер корневой директории
        int 86h

SearchFileInRoot:
        push 0
        pop es
        mov di, FATData

        mov cx, [BPB_RootEntCnt]   ; Проходим по всей корневой директории
        mov dx, 0
        mov bx, si

NextFilename:
        xchg cx, ax
        mov si, bx
        ;mov si, kernName
        mov cx, 11              ; Длина имени
        rep cmpsb              ; Сраниваем (ES:DI) с (DS:SI)
        je FoundFile

        add dx, 32
        mov di, FATData        ; Переходим к следующему имени
        add di, dx

        xchg ax, cx
        loop NextFilename

        output fileNotFound
        jmp Reboot

FoundFile:
        push 0
        pop ds
        mov ax, word [es:di + $0F]    ; Get first kernel cluster from root directory
        mov word [cluster], ax        ; Save first kernel cluster

        mov ax, 1         ; FAT назодится в секторе 1 (сектор 0 - загрузчик)
        mov cx, 9         ; Размер таблицы FAT
        mov bx, FATData

        int 86h

LoadFileSector:  ; Actually is a cycle
        mov ax, gs
        mov es, ax
        mov bx, word [pointer]     ; Track the address we are writing to
        mov ax, word [cluster]     ; Track the cluster we are reading from
        add ax, 31
        mov cx, 1                  ; Read one cluster per time

        int 86h

CalculateNextCluster:
        mov ax, [cluster]
        mov dx, 0
        mov bx, 3
        mul bx
        mov bx, 2
        div bx
        mov si, FATData
        add si, ax
        mov ax, word [ds:si]
        or dx, dx
        jz Even

Odd:                            ; FAT12 is comlicated to parse :(
    shr ax, 4
    jmp short NextClusterCont

Even:
    and ax, 0FFFh

NextClusterCont:
    mov word [cluster], ax

    cmp ax, 0FF8h               ; End of the file?
    jae BootEnd                 ; If it is then execute kernel

    add word [pointer], 512
    jmp LoadFileSector

BootEnd:
    mov [pointer], 0
    iret
;================================================================================================================================;
;  ПРЕРЫВАНИЕ 80h
;    int 86h - дебажим-с
;================================================================================================================================;
Debug:
        output fileNotFound
        jmp $
;================================================================================================================================;
;  ПРЕРЫВАНИЕ 86h
;    int 86h - считать с дискеты
;    ES:BX - адрес буфера
;    AX - номер сектора
;================================================================================================================================;
ReadSectorsFromDisk:
        push si
        mov si, 5

        push ds
        push 0
        pop ds
        push cx

        push bx
        push ax
        xor dx, dx

        div word[BPB_SecPerTrk]  ;Sector = (LBA mod SectorPerTrack) + 1
        add dl, 01h
        mov cl, dl               ;cl = номер сектора


        pop ax
        xor dx, dx
        div word[BPB_SecPerTrk] ;Cylinder = (LBA / SectorsPerTrack) / NumHeads

        xor dx, dx
        div word[BPB_NumHeads]

        mov dh, dl               ;dh = номер головки
        mov ch, al               ;ch = номер цилиндра

        mov dl,byte[diskNum]     ;это дискета
        pop bx
        pop ax
        mov ah, 2

.Retry:
        dec si
        jz .Reboot
        int 13h
        jnc .Ok
        jc  .Retry
.Reboot:
        jmp Reboot

.Ok:
        pop ds
        pop si
        iret

bootFailure:
         xor ax, ax
         int 16h

         db 0xEA            ;машинный код jump FFFF:0000
         dw 0x0000,0xFFFF

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
;================================================================================================================================;
                                                 ;КОНЕЦ ЗАГРУЗОЧНОГО СЕКТОРА;
;================================================================================================================================;
Mydata:
        kernName db 'MYKERNELBIN',0
        fileNotFound db 'File not found:(',0
        diskNum  db ?                 ;по идее будет 0
        cluster    dw 0
        pointer    dw 0

Finish:
        if $<510+7C00h
                times 0x1FE-Finish+Start db 0
        else
                display 'This bootloader is too big!!!'  ;директива (выводят сообщение в окно результатов компиляции)
        end if
        db   0x55, 0xAA                                  ;сигнатура загрузочного сектора
FATData:
;================================================================================================================================;
                                               ;ПРИМЕЧАНИЯ;
;================================================================================================================================;
;п.1 По документации BPB_BytsPerSec * BPB_SecPerClus < 32Кб обязательно!!!
;п.2

