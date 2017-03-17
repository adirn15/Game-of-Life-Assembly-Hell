 
 global scheduler,NEXXT,Freq
 extern resume, end_co, WorldWidth,WorldLength,DEBUG,Frequency,Generations

%macro write 2
        pusha
        mov eax, 4 ;write 
        mov ebx, 1 ;stdout
        mov ecx, %1 ;msg
        mov edx, %2 ;length
        int 0x80
        popa
%endmacro

section .data
cur: dd 1

section .bss
Freq: resb 4
TotalCells: resb 4

section .text

scheduler:
        cmp dword [DEBUG],0
        je .nodebug
        dec dword [cur]
    .nodebug:
        mov eax,0
        mov al,[WorldLength]
        mov bl,[WorldWidth]
        mul bl
        mov [TotalCells],eax
        mov eax,[Frequency] 
        mov [Freq],eax
        mov eax,[Frequency]
.next:
        cmp dword [Freq],0
        jne .calc1
        mov dword [Freq],eax
        mov ebx,1
        call resume
        jmp .next
    .calc1:
        cmp dword [Generations],0
        jne .calc2
        mov ebx,1 
        call resume
        jmp .next
    .calc2:
        mov ebx, [cur]
        inc ebx
        mov ecx,[TotalCells]
        add ecx,2
        cmp ecx,ebx
        jne .cont
        mov dword [cur],2
        mov ebx,2
        jmp .cont2
     .cont:
        mov [cur],ebx
     .cont2:
        call resume             
        loop .next

        call end_co             ; stop co-routines