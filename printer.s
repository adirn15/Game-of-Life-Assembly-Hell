        global printer
        extern resume,state,WorldWidth,WorldLength,printf,Generations,NEXXT,Frequency,Freq

        ;; /usr/include/asm/unistd_32.h
sys_write:      equ   4
stdout:         equ   1

;************************************ MACROS ****************************************
;************************************************************************************

%macro write 2
        pusha
        mov eax, 4 ;write 
        mov ebx, 1 ;stdout
        mov ecx, %1 ;msg
        mov edx, %2 ;length
        int 0x80
        popa
%endmacro


;********************************** VARIABLES ***************************************
;************************************************************************************

section .bss
BUF: resb 1

;********************************** FUNCTIONS ***************************************
;************************************************************************************

section .text


printer: 

        pushad

        mov ecx,0        ;cl=j
        mov dl,0        ;dl=i
        jmp .printnext
    
    .loop:
        cmp cl,0
        jne .printnext
        mov byte [BUF],10
        write BUF,1         ; print enter

    .no_enter:
        mov bl,dl           ; parity check
        and bl,1
        cmp bl,0
        je .printnext
        mov byte [BUF],32
        write BUF,1         ; print space

    .printnext: 
        mov eax,0
        mov al,dl
        mov bl,[WorldWidth]
        mul bl              ;ax=al*bl = i*WorldWidth
    .here:
        add ax,cx           ;ax=i*WorldWidth+j
        mov bl,[state+eax] 
        mov byte [BUF],bl   ;BUF=NEXT NUM IN state 
        write BUF,1         ;print number
        mov byte [BUF],32
        write BUF,1         ;print space
        
        inc cl
        cmp cl,[WorldWidth]
        jne .loop
        inc dl      ;i++
        mov cl,0    ;j=0
        cmp dl,[WorldLength]
        jne .loop
        mov byte [BUF],10
        write BUF,1         ; print enter
        cmp dword [Generations],0
        jne .resume
        
        mov eax,[Freq]
        cmp eax,[Frequency]
        jne .exit 
        mov dword [Freq],-1

        jmp printer
    .exit:
        mov eax, 1      ; sys_exit
        xor ebx, ebx
        int 0x80

        .resume:    
             mov ebx,0 ; resume scheduler
             call resume
             popad             

        jmp printer