;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ INT_2_STR ]
;//////////////////////////////////////////////////////////////////////////////////////////////////
INT_2_STR:   push         rbp                         ; create the stack frame
              mov         rbp,        rsp 
            
              sub         rsp,        0xFF
            
            
             push         r12
             push         r11
             push         rax
             push         rbx
             push         rcx
             push         rdx
             push         rsi
             push         rdi

              ;/////////////////////////////////////////////////////////////////
              
              mov         r11,             rbp    ;STRBUFFER1
              ;add         r11,             0xFF
              xor         r12,             r12
              ;//////////////////////////////////////////////////////////////
INT_2_LOOP:   dec         r11
              mov         rdx,             0x00         ; reminder from division
              mov         rbx,             0x0A         ; base
              div         rbx                           ; rax = rax / 10
              add         rdx,             0x30         ; add 48
             ;push         rdx
              mov   byte [r11],            dl
              inc         r12                           ; go next
              cmp         rax,             0x00         ; check factor with 0
              jne         INT_2_LOOP                    ; loop again
              ;//////////////////////////////////////////////////////////////
              ;mov         rax,             1
              ;mul         r12
              ;mov         r12,             8
              ;mul         r12
              ;//////////////////////////////////////////////////////////////
              
              ;inc         r12
              
              mov         rdi,             STDOUT  
              ;mov         rax,             STRBUFFER1
              ;add         rax,             0xFF
              ;sub         rax,             r12
              mov         rsi,             r11          ; pString
              mov         rdx,             r12          ; cString
              mov         rax,             SYS_WRITE    
              syscall 
              ;/////////////////////////////////////////////////////////////////

             pop          rdi
             pop          rsi
             pop          rdx 
             pop          rcx
             pop          rbx
             pop          rax
             pop          r11
             pop          r12
            
              mov         rsp,             rbp          ; destroy the stack frame
             pop          rbp
            
              ret
