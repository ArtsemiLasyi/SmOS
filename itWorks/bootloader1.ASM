use16
org 7C00h
include 'macroses.m'
KERNEL = 90h              ;�����, �� �������� ����� ��������� ����
BUFFER = 200h             ;������, ������� ���� ����� ������������ �������

Start:
;================================================================================================================================;
                                                     ;FAT12. BPB STRUCTURE;
;================================================================================================================================;
jmp bootloader
db 0
BS_OEMName     db      "MSWIN4.1"         ;����� ��� �� ������ ����, �� ��� ���������� ������� � �������������� ����� ���
BPB_BytsPerSec dw      512                 ;���������� ������ � �������
BPB_SecPerClus db      1                   ;���������� �������� � ��������. ���������: 1,2,4,8,16,32,64 � 128(��. ���������� �.1)
BPB_RsvdSecCnt dw      1                   ;���������� ����������������� �������� � ����������������� ������� ���� (��� FAT12 - 1)
BPB_NumFATs    db      2                   ;����������� �������� ������ FAT �� ���� (����� ����� 2)
BPB_RootEntCnt dw      224                 ;��� ���� FAT12 ��� ���� �������� ���������� 32-�������� ������� �������� � �������� ��������.
BPB_TotSec16   dw      2880                ;��� ���� FAT12 ��� ���� �������� ���������� ��������  (1440*1024/512)
BPB_Media      db      0xF0                ;��� ������� ��������� ����� ������������ 0xF0
BPB_FATSz16    dw      9                   ;������ ���� ��� FAT12 - 16-������ ������� ��������, ������� ����� �����.
BPB_SecPerTrk  dw      18                  ;�������� �� ������� (����) ��� ���������� 0x13
BPB_NumHeads   dw      2                   ;���������� ������� ��� ����������  0x13. ��� 3,5''-��������� ������ ������ �� 1,44 �� - 2
BPB_HiddSec    dd      0                   ;���������� ������� ��������, �������������� �������, ������� �������� ���� ��� FAT
BPB_TotSec32   dd      0                   ;��� ���� - ����� 32-��������� ����� ����������� �������� � ����
BS_DrvNum      db      0                   ;Int 0x13 ����� �������. ��� ���� ���������� ������� �� ������������ �������
BS_Reserved1   db      0                   ;���������������. ���,������������� ���� FAT, ������ ������ ������������� ���� ���� � 0.
BS_BootSig     db      0x29                ;����������� ����������� �������. ��������� �� ������� ��������� ���� ����� � ����������� �������
BS_VolID       dd      ?                   ;�������� ����� ����
BS_VolLab      db      'COOLLABEL  '       ;����� ���� (11 ����)
BS_FilSysType  db      'FAT12   '          ;���� �� ����� ���� �� �������� ������ BPB. ����� ����� �������������� ��������
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
                                     ;���������;
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
;  ���������� 85h
;    int 85h - ��������� ����
;    GS:BX - ����� ������
;    SI - ��� �����
;================================================================================================================================;
LoadFileFromDisk:

        mov bx, FATData
        push 0
        pop es
        mov ax, 19            ; ������ ������� � �������� �����������
        mov cx, 14            ; ������ �������� ����������
        int 86h

SearchFileInRoot:
        push 0
        pop es
        mov di, FATData

        mov cx, [BPB_RootEntCnt]   ; �������� �� ���� �������� ����������
        mov dx, 0
        mov bx, si

NextFilename:
        xchg cx, ax
        mov si, bx
        ;mov si, kernName
        mov cx, 11              ; ����� �����
        rep cmpsb              ; ��������� (ES:DI) � (DS:SI)
        je FoundFile

        add dx, 32
        mov di, FATData        ; ��������� � ���������� �����
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

        mov ax, 1         ; FAT ��������� � ������� 1 (������ 0 - ���������)
        mov cx, 9         ; ������ ������� FAT
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
;  ���������� 80h
;    int 86h - �������-�
;================================================================================================================================;
Debug:
        output fileNotFound
        jmp $
;================================================================================================================================;
;  ���������� 86h
;    int 86h - ������� � �������
;    ES:BX - ����� ������
;    AX - ����� �������
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
        mov cl, dl               ;cl = ����� �������


        pop ax
        xor dx, dx
        div word[BPB_SecPerTrk] ;Cylinder = (LBA / SectorsPerTrack) / NumHeads

        xor dx, dx
        div word[BPB_NumHeads]

        mov dh, dl               ;dh = ����� �������
        mov ch, al               ;ch = ����� ��������

        mov dl,byte[diskNum]     ;��� �������
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

         db 0xEA            ;�������� ��� jump FFFF:0000
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
                                                 ;����� ������������ �������;
;================================================================================================================================;
Mydata:
        kernName db 'MYKERNELBIN',0
        fileNotFound db 'File not found:(',0
        diskNum  db ?                 ;�� ���� ����� 0
        cluster    dw 0
        pointer    dw 0

Finish:
        if $<510+7C00h
                times 0x1FE-Finish+Start db 0
        else
                display 'This bootloader is too big!!!'  ;��������� (������� ��������� � ���� ����������� ����������)
        end if
        db   0x55, 0xAA                                  ;��������� ������������ �������
FATData:
;================================================================================================================================;
                                               ;����������;
;================================================================================================================================;
;�.1 �� ������������ BPB_BytsPerSec * BPB_SecPerClus < 32�� �����������!!!
;�.2

