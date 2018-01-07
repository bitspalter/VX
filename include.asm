;///////////////////////////////////////////////////
;// [ INCLUDE ]
;///////////////////////////////////////////////////
   
SYS_READ        equ     0x00         ; file read
SYS_WRITE       equ     0x01         ; file write
SYS_OPEN        equ     0x02         ; file open
SYS_CLOSE       equ     0x03         ; file close
SYS_STAT        equ     0x04         ; file stat
SYS_MMAP        equ     0x09         ; Memory Mapping
SYS_UNMAP       equ     0x0B         ; UnMapping
SYS_MREMAP      equ     0x19         ; ReMapping
SYS_MSYNC       equ     0x1A         ; MapSync
SYS_EXIT        equ     0x3C         ; terminate
SYS_GETCWD      equ     0x4F         ; get current working directory
SYS_FTRUNCATE   equ     0x4D         ; Change File Size
SYS_TIME        equ     0xC9         ; get time in Seconds
SYS_DIR64       equ     0xD9         ; sys_getdents64

;///////////////////////////////////////////////////
      
O_RDONLY        equ     0x00         ; read only
O_WRONLY        equ     0x01         ; write only
O_RDWR          equ     0x02         ; read and write
O_CREAT         equ     0x40         ; create if not exist

;///////////////////////////////////////////////////

PROT_READ	    equ     0x01         ; Page can be read.
PROT_WRITE	    equ     0x02         ; Page can be written.
PROT_EXEC	    equ     0x04         ; Page can be executed.
PROT_NONE	    equ     0x00         ; Page can not be accessed.

PROT_RW         equ     PROT_READ | PROT_WRITE

;///////////////////////////////////////////////////
   
MAP_SHARED	    equ     0x01         ; Share changes.
MAP_PRIVATE	    equ     0x02         ; Changes are private.
   
;///////////////////////////////////////////////////
   
MREMAP_NOFLAG   equ     0x00
MREMAP_MAYMOVE  equ     0x01         ; kernel is permitted to relocate the mapping
MREMAP_FIXED    equ     0x02         ; accepts a fifth argument in r8 (new_address)

;///////////////////////////////////////////////////
   
SHF_WRITE       equ     0x01         ; ELF Section Write Permission
SHF_ALLOC       equ     0x02         ; ELF Section Alloc Permission 
SHF_EXECINSTR   equ     0x04         ; ELF Section Exec Permission
   
;///////////////////////////////////////////////////
   
MS_ASYNC        equ     0x01         ; Perform asynchronous writes.
MS_SYNC         equ     0x02         ; Perform synchronous writes.
MS_INVALIDATE   equ     0x04         ; Invalidate privately cached data

;///////////////////////////////////////////////////

MAGIC           equ     0x464C457F   ; ELF Header 

;///////////////////////////////////////////////////

DT_DIR          equ     0x04         ; folder
DT_REG          equ     0x08         ; file

;///////////////////////////////////////////////////
;// [ Dir ] Stack layout
;///////////////////////////////////////////////////
   
cSTACKVq        equ     0xF000
   
cInput          equ     0x08
pInput          equ     0x10
pFile           equ     0x18
cBuffer         equ     0x20
cFName          equ     0x28
pFName          equ     0x30
pInfect         equ     0x38    

;///////////////////////////////////
   
pSTRING         equ     0x1138

;///////////////////////////////////
   
pDIR64          equ     0xF000
cDIR64          equ     pDIR64 - pSTRING
   
;///////////////////////////////////////////////////
;// [ checkfile ] Stack layout
;///////////////////////////////////////////////////
   
cCHECKVq        equ     0x120
   
pNFile          equ     0x08     ; FileName
cNFile          equ     0x10     ; FileName Size
pHFile          equ     0x18     ; FileHandle
pSFile          equ     0x20     ; FileSize
;pInfect        equ     0x28     
pBuffer         equ     0x120    ; Temp Buffer

;///////////////////////////////////////////////////
;// [ mmapfile ] Stack layout
;///////////////////////////////////////////////////
   
cMMAPVq         equ     0x40
   
FHandle         equ     0x08
FSize           equ     0x10
pMFile          equ     0x18
pSection        equ     0x20
nSection        equ     0x28
pCall           equ     0x30
cCall           equ     0x38
pSegment        equ     0x40
