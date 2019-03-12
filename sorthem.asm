%include "asm_io.inc"

SECTION .data

initial_conf: db "initial configuration",10,0
final_conf: db "final configuration",10,0
err1: db "incorrect number of command line arguments",10,0
err2: db "incorrect command line argument",10,0
base_X: db "XXXXXXXXXXXXXXXXXXXXXXX",10,0
arr: dd 0,0,0,0,0,0,0,0,0,0


SECTION .bss

num: resd 2


SECTION .text
     global  asm_main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
asm_main:
     enter 0,0                               ; setup routine
        pusha                                   ; save all registers

        mov eax, dword [ebp+8]                  ; argc
        cmp eax, dword 2                        ; argc should be 2
    jne ERR1

    ; so we have the right number of arguments
    mov ebx, dword [ebp+12]                 ; address of argv[]
    mov eax, dword [ebx+4]                  ; argv[1]


    ; check the first byte of the string, should be between "2" or "9" 
    ; check the second byte, should be 0, NULL char

    mov bl, byte [eax]                      ; 1st byte of argv[1]
    
    fist_byte: 
         cmp bl, '2'
         jb ERR2                             ; incorrect command line argument, below '2'
         ; so the first byte >= '2'
         cmp bl, '9'
         ja ERR2                             ; incorrect command line argument, above '9'
         ; so the first byte is between "2" or "9"
         sub bl, '0'
         mov ecx,0
         mov cl, bl                          ; so ecx holds either 1 or 2
    second_byte:
         mov bl, byte [eax+1]                ; 2nd byte of argv[1]
         cmp bl, byte 0
         jne ERR2                            ; incorrect command line argument, second byte is not NULL

    ; hence the argument is correct and its numeric value is stored in ecx

    mov [num], ecx

    push ecx 
    mov eax, arr
    push eax  
    call rconf
    pop eax
    pop ecx
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Display initial configuration ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    mov eax, initial_conf
    call print_string

    push ecx
    mov eax, arr
    push eax
    call showp
    add esp, 8 
   
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Call sorthem    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov eax, arr
    push eax
    push ecx
    call sorthem
    add esp, 8

    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Display final configuration    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    mov eax, final_conf
    call print_string

    push ecx
    mov eax, arr
    push eax
    call showp
    add esp, 8 

    jmp asm_main_end
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

sorthem: 
    ; takes 2 parameters: 
    ; 1, ecx, length of array
    ; 2, ebx, is the base address of a sorted descending array

    enter 0,0                           ; setup routine
    pusha                               ; save all registers
    mov ecx, [ebp+8]                    ; ecx : number of disks
    mov ebx, [ebp+12]                   ; ebx : base address

    ; if ecx == 1, return singleton list itself
    cmp ecx, dword 1                    
    je base_case                        ; where ebx is the base address for our base case

    ; recursive case
    mov eax, ebx
    add eax, 4                          ; increment ebx by offset 4, pointing to next element in arr
    push eax                            ; push ebx onto the stack
    mov edx, ecx
    dec edx                             ; decrement number of disks
    push edx                            ; push length of array arr[1:]
    call sorthem
    add esp, 8

    mov edx, dword 0                          
    ; edx = i, i = 0
    ; ebx = base address
    Loop:
        cmp edx, ecx
        ja loop_end
     
        shl     edx, 2                  ; multiply by 4 to get offset of array
        mov     esi, [ebx+edx]          ; esi contains arr[x]
        mov     eax, edx                ; eax contains the offset
        add     eax, 4
        mov     edi, [ebx+eax]          ; edi contains arr[x+1]
        cmp     esi, edi
        ja      no_swap
        mov     [ebx+edx], edi
        mov     [ebx+eax], esi
        shr     edx, 2                  ; divide by 4 to get original edx back

    no_swap:
        inc edx
        jmp Loop

    loop_end:    
        push dword [num]
        push arr
        call showp
        add esp, 8

    base_case:        
        popa
        leave
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

showp:
    ; takes 2 arguments, 
    ; ebx : base address of the array
    ; ecx : the number of disks

    enter 0,0                           ; setup routine
    pusha                               ; save all registers
    mov ebx, [ebp+8]                    ; store arr in ebx
    mov ecx, [ebp+12]                   ; store number of disks in ecx


    ; set the pointer to the last element of the array, and display line
    dec ecx
    imul ecx, ecx, 4                    ; now ecx = (ecx-1)*4
    add ebx, ecx                        ; ebx += ecx, now [eax] points to the last element of array

    Loop_element:
        cmp ecx, dword 0                ; compare ecx against 0
        jbe display_base
        mov eax, [ebx]                  ; stores the arr[i]
        push eax
        call display_line
        add esp, 4
        sub ecx, 4
        sub ebx, 4
        jmp Loop_element
    display_base:
        ; display the first element of the array and the base Xs
        mov ebx, [ebp+8]
        mov eax, [ebx]                  ; stores the arr[i]
        push eax
        call display_line
        add esp, 4
        mov eax, base_X
        call print_string
        call print_nl
    call read_char
    popa
    leave
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
display_line:
    ; takes 1 inputs: number of 'o's to print

    enter 0,0                           ; setup routine
    pusha                               ; save all registers
    mov ebx, [ebp+8]                    ; ebx stores the number of 'o's to print
    ; mov edx, dword '11'
    mov edx , 11
    sub edx, ebx                        ; edx stores the number of spaces to print 
    ; ex. ebx = 4, edx = 7

    LOOP_space:
        cmp edx, dword 0
        jbe LOOP_ol
        mov eax, ' '
        call print_char
        dec edx
        jmp LOOP_space
    LOOP_ol:
        cmp ebx, dword 0
        jbe display_bar
        mov eax, 'o'
        call print_char
        dec ebx
        jmp LOOP_ol
    display_bar:
        mov eax, '|'
        call print_char
        mov ebx, [ebp+8]               ; reset ebx to be number of 'o's to print after previous iteration
    LOOP_or:
        cmp ebx, dword 0
        jbe Next_line
        mov eax, 'o'
        call print_char
        dec ebx
        jmp LOOP_or
    Next_line:
        call print_nl
        popa
        leave
        ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

temp_display:
    ; takes 1 parameters: 
    ; 1, ebx, is the base address the array to be displayed

    enter 0,0                           ; setup routine
    pusha                               ; save all registers


    mov ebx, [ebp+8]                    
    ; ebx points to the beginning of the array
    ; we will use ecx to control the counting loop of 9
    mov eax, '['
    call print_char
    mov ecx, dword 1
    LOOP:
        mov eax, dword [ebx]
        call print_int
        mov eax, ','
        call print_char
        inc ecx
        add ebx, 4
        cmp ecx, dword 9
        jb LOOP
    ; so the loop is over, print the last entry
    mov eax, dword [ebx]
    call print_int
    mov eax, ']'
    call print_char
    call print_nl 

    popa
    leave
    ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

ERR1:
        mov eax, err1
        call print_string
        jmp asm_main_end
     
ERR2:
     mov eax, err2
     call print_string
     jmp asm_main_end

asm_main_end:
    popa                                      ; restore all registers
    leave                     
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   END    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
