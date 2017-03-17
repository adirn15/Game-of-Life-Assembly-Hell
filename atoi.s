global my_atoi

section .data
        ten: dd 10
        test: db 0,10,0

section .text

my_atoi:
        push    ebp
        mov     ebp, esp        ; Entry code - set up ebp and esp
        push ecx
        push edx
        push ebx

        mov ecx, dword [ebp+8]  ; Get argument (pointer to string)
        .h:
        xor eax,eax
        xor ebx,ebx
        jmp atoi_loop

print:
        mov byte[test],al
        mov eax,4   ;write
        mov ebx,1   ;stdout
        mov ecx,test ;from test
        mov edx,3 ;3 bytes
        int 80h
end1:
      mov eax,1
      xor ebx,ebx
      int 80h

atoi_loop:
        xor edx,edx
        cmp byte[ecx],0
        jz  atoi_end
        imul dword[ten]
        mov bl,byte[ecx]
        sub bl,'0'
        add eax,ebx
        inc ecx
        jmp atoi_loop

atoi_end:
        pop ebx                 ; Restore registers
        pop edx
        pop ecx
        mov     esp, ebp        ; Function exit code
        pop     ebp
        ret

