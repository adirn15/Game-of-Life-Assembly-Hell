
maxcors:        equ 60*60+2 ; maximum number of co-routines
stacksz:        equ 512     ; per-co-routine stack size


;********************************* MACROS ****************************************
;*********************************************************************************

%macro fd_seek 3
    pusha
    mov eax, 19
    mov ebx, %1    ;fd
    mov ecx, %2    ;num of bytes
    mov edx, %3    ;from where NEXXTseek=1,start=0,end=2
    int 0x80
    popa
%endmacro

%macro read_me 3

    pusha
    mov eax, 3
    mov ebx, %1    ;from
    mov ecx, %2    ;to
    mov edx, %3    ;num of bytes
    int 0x80
    popa
%endmacro

%macro calc_offset 2        ;1=i byte,2=j byte
        mov eax,0
        mov al, %1
        mov bl, [WorldWidth]
        mul bl              ;ax=al*bl (i*WorldWidth)
        mov ecx,0
        mov cl,%2
        add eax,ecx         ;eax=i*WorldWidth+j
%endmacro

%macro get_low 1
        shl %1,16
        shr %1,16
%endmacro

%macro printme 2
        pusha 
        push %1
        push %2
        call printf
        add esp,8
        popa
%endmacro

%macro get_values 2        ;i,j
        mov eax,%1
        mov bl, [WorldWidth]
        mul bl              ;ax=al*bl (i*WorldWidth)
        mov ecx,%2
        add eax,ecx         ;eax=i*WorldWidth+j
        mov dl,[state+eax]
        
%endmacro


%macro atoifunc 1
        mov edi, [edx+esi] ;edi=next argument 
        pushad
        push edi
        call my_atoi
        add esp,4
        mov [%1], eax
        popad 
        add esi,4
%endmacro

;*************************************** VARIABLES **************************************
;****************************************************************************************
section .rodata
ENTER: DB "\n",0
HEX_FORMAT: DB "%X",10,0
INT_FORMAT: DB "%d",10,0
STR_FORMAT: DB "%s",10,0
ARGS_ERR: DB "Error: insufficient args",10,0

section .bss

stacks: resb maxcors * stacksz  ; co-routine stacks
cors:   resd maxcors            ; simply an array with co-routine stack tops

curr:   resd 1                  ; current co-routine
origsp: resd 1                  ; original stack top
tmp:    resd 1                  ; temporary value
fd:     resb 4
row:                    resw 1
col:                    resw 1
cell:                   resw 1

global FILENAME,WorldWidth,WorldLength,Generations,Frequency,DEBUG,state,TotalCells

state: resb 3600                                ;the array of cells states
DEBUG: resb 4                                   ;debugger
WorldWidth: resb 4                                
WorldLength: resb 4   
TotalCells: resb 4                           
Generations: resb 4                             ;number of Generations
Frequency: resb 4                               ;
FILENAME: resb 20
BUF: resb 1
TEMP: resb 4
FIRST: resb 1

section .data
IP1: dd 0
IM1: dd 0
JP1: dd 0
JM1: dd 0
CURI: dd 0
CURJ: dd 0

;*********************************** THREAD FUNCTIONS ************************************
;*****************************************************************************************

section .text

    align 16
    global init_co
    global start_co
    global end_co
    global resume
    global init_life
    extern NEXXT
    extern printf
    extern my_atoi
    extern scheduler
    extern printer
    extern Freq

        ;; ebx = co-routine index to initialize
        ;; edx = co-routine start
        ;; other registers will be visible to co-routine after "start_co"

init_co:
        push eax                ; save eax (on callers stack)
        push edx
        mov edx,0
        mov eax,stacksz
        imul ebx                ; eax = co-routines stack offset in stacks
        pop edx
        add eax, stacks + stacksz ; eax = top of (empty) co-routines stack
        mov [cors + ebx*4], eax ; store co-routines stack top
        pop eax                 ; restore eax (from callers stack)

        mov [tmp], esp          ; save callers stack top
        mov esp, [cors + ebx*4] ; esp = co-routines stack top

        push edx                ; save return address to co-routine stack
        pushf                   ; save currs
        pusha                   ; save all registers
        mov [cors + ebx*4], esp ; update co-routines stack top

        mov esp, [tmp]          ; restore callers stack top
        ret                     ; return to caller

        ;; ebx = co-routine index to start
start_co:
        pusha                   ; save all registers (restored in "end_co")
        mov [origsp], esp       ; save callers stack top
        mov dword [curr], ebx           ; store current co-routine index
        jmp resume.cont         ; perform state-restoring part of "resume"

        ;; can be called or jumped to
end_co:
        mov esp, [origsp]       ; restore stack top of whoever called "start_co"
        popa                    ; restore all registers
        ret                     ; return to caller of "start_co"

        ;; ebx = co-routine index to switch to
resume:                         ; "call resume" pushed return address
        pushf                   ; save flags to source co-routine stack
        pusha                   ; save all registers

        xchg ebx, [curr]        ; ebx = current co-routine index
        mov [cors + ebx*4], esp ; update current co-routine's stack top'
        mov ebx, [curr]         ; ebx = destination co-routine index
        .cont:
        mov esp, [cors + ebx*4] ; get destination co-routine's stack top'
        popa                    ; restore all registers
        popf                    ; restore flags

        ret                     ; jump to saved return address


;******************************** GAME FUNCTIONS ***************************************
;***************************************************************************************

init_life:

        push    ebp
        mov     ebp, esp        ; Entry code - set up ebp and esp
        pushad          ; Save registers

                mov byte [FIRST],0
                mov eax,5             ; sys open        
                mov ebx,[FILENAME]           ; fILE name
                mov ecx,2             ; read write
                mov edx,0777          ; all permissions
                int 0x80              ;eax=pointer to file 
                mov [fd], eax

                call init_board         ;fill in the array from the file given           
              
               
                xor ebx, ebx            ; scheduler is co-routine 0
                mov edx, scheduler
                call init_co            ; initialize scheduler state

                mov ebx,1                 ; printer i co-routine 1
                mov edx, printer
                call init_co            ; initialize printer state
                
                mov eax,0
                mov al, [WorldWidth]
                mov bl, [WorldLength]
                mul bl

                mov dword [TotalCells], eax   ;total number of cells
                mov ebx, eax
                inc ebx                     ;set id straight
                .init_next_cell:
                    mov edx,calc
                    call init_co
                    dec ebx
                    cmp ebx,1 
                    jne .init_next_cell

                mov ebx,0            ; starting co-routine = scheduler
                call start_co           ; start co-routines

        .ret:   popad           ; Restore registers
                mov esp, ebp    ; Function exit code
                pop ebp
                ret

        .quit:
                printme ARGS_ERR, STR_FORMAT
                ;; exit

                mov eax, 1      ; sys_exit
                xor ebx, ebx
                int 80h



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; init board ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

init_board:

        push ebp
        mov ebp,esp
        pushad
        
        mov ecx,0               ; ebx= length (i)
        
        .loop:  
                mov dx,0
                mov ax,cx
                mov bh,0 ;bx
                mov bl,[WorldWidth]
                div bx                 ;ah=remainder of ax/bl (NEXXT j) 
                                       ;al=mana (NEXXT i)

                mov edx,0
                mov dl,al
                cmp edx,[WorldLength]
                je .ret

                read_me [fd],BUF,1       
        .num?:
                cmp byte [BUF],48
                je .number
                cmp byte [BUF],49
                jne .loop

        .number:
                pushad 
                mov edx,0
                mov dl,[BUF]            ; dl=state value                                            
                mov byte [state+ecx],dl ; put in array
                popad 
                inc ecx
                jmp .loop           

        .ret:
                popad
                mov esp,ebp
                pop ebp
                ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; calc neighbors ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;right= x+1%NEXXTwidth ,y 
;left = x-1%NEXXTwidth ,y
;upper1 = x,y+1%NEXXTlength
;upper2 = x+1%NEXXTwidth,y+1%NEXXTlength
;down1 = x,y-1%NEXXTlength
;down2= x+1%NEXXTwidth,y-1%NEXXTlength
%macro write 2
        pusha
        mov eax, 4 ;write 
        mov ebx, 1 ;stdout
        mov ecx, %1 ;msg
        mov edx, %2 ;length
        int 0x80
        popa
%endmacro

calc:
                pushad
                mov dx,0
                mov ax,0
            .b:
                mov ax,bx           ;in bl we have the id
                sub ax,2            ;al is the right id
                push eax            
                mov bh,0
                mov bl,[WorldWidth] 
                div bx  ;ax=i,dx=j    ;al= i ah= j

            .continue:
    
                mov esi,0   
                push eax                 ;esi=counter
                get_low eax
                mov [CURI],eax ;cl=i
                pop eax

                get_low edx
                mov [CURJ],edx ;ch=j

                mov eax,[CURJ]
                get_low eax
                mov edx,0
                mov dx,ax
                dec dx    ;dh=j-1
                cmp dx,-1                   
                jne .jm1
                mov dx,0
                mov dl,[WorldWidth]
                dec dx
            .jm1:
                get_low edx
                mov [JM1],edx

                mov eax,[CURJ]
                mov edx,0
                mov dx,ax
                inc dx
                cmp dx,[WorldWidth]
                jne .jp1
                mov dx,0
            .jp1:
                get_low edx
                mov [JP1],edx

                mov edx,[CURI]
                dec edx    ;dh=I-1
                cmp dx,-1                   
                jne .im1
                mov dx,[WorldLength]
                dec dx
            .im1:
                get_low edx
                mov [IM1],edx

                mov edx,[CURI]
                inc edx
                cmp dx,[WorldLength]
                jne .ip1
                mov dx,0
            .ip1:
                get_low edx
                mov [IP1],edx

            .calc_offsets:
                mov esi,0
                get_values [CURI],[JM1]
                cmp dl,48
                je .next1
                inc esi
            .next1:
                get_values [CURI],[JP1]
                cmp dl,48
                je .next2
                inc esi
            .next2:
                get_values [IM1],[CURJ]
                cmp dl,48
                je .next3
                inc esi
            .next3:
                get_values [IP1],[CURJ]
                cmp dl,48
                je .next4
                inc esi
            .next4:
                mov eax,[CURI]
                and al,1
                cmp al,0
                jne .optioneven

            .optionodd:
                get_values [IM1],[JM1]
                cmp dl,48
                je .next5l
                inc esi
            .next5l:
                get_values [IP1],[JM1]
                cmp dl,48
                je .checkesi
                inc esi
                jmp .checkesi

            .optioneven:
                get_values [IM1],[JP1]
                cmp dl,48
                je .next5r
                inc esi
            .next5r:
                get_values [IP1],[JP1]
                cmp dl,48
                je .checkesi
                inc esi

            .checkesi:
                get_values [CURI],[CURJ]
                mov ecx,0
                mov cl,48 ;=new value to put
                cmp dl,48
                je .currentisdead
            .currentislive:   
                cmp esi,3
                je .live
                cmp esi,4
                je .live
                jmp .change_state
            .currentisdead:
            .g:
                cmp esi,2
                je .live
                jmp .change_state
            .live:
                inc cl
            .change_state:
                push ecx
                mov ebx,0   ;back to scheduler
                dec dword [Freq]
                call resume 
                pop ecx
                pop eax
                mov byte [state+eax],cl

            .resume:
                mov ebx,0   ;back to scheduler
                dec dword [Freq]

                inc eax
                cmp eax,[TotalCells]
                jne .nodec
            .h:
                dec dword [Generations]
            .nodec:
                mov ebx,0
                call resume

                popad
                jmp calc
    

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;; CELL ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

               