;//////////////////////////////////////////////////////////////////////////////////////////////////
;// [ MACRO ] 
;//////////////////////////////////////////////////////////////////////////////////////////////////

   %macro write 2 
     push      rdi
     push      rsi
     push      rdx
     push      rcx
     push      rbx
     push      rax
     
      mov      rdi,        STDOUT      
      mov      rsi,        %1           ; pString
      mov      rdx,        %2           ; cString
      mov      rax,        SYS_WRITE    
      syscall 
      
     pop       rax
     pop       rbx
     pop       rcx
     pop       rdx
     pop       rsi
     pop       rdi
   %endmacro
   
;//////////////////////////////////////////////////////////

   %macro pusha 0
     push      rbp
     push      rsp
     push      rdi
     push      rsi
     push      rdx
     push      rcx
     push      rbx
     push      rax       
     push      r15
     push      r14        
     push      r13        
     push      r12        
     push      r11         
     push      r10
     push      r9
     push      r8 
     PUSHFQ
   %endmacro
   
;//////////////////////////////////////////////////////////

   %macro popa 0
     POPFQ
     pop       r8
     pop       r9
     pop       r10
     pop       r11 
     pop       r12 
     pop       r13
     pop       r14
     pop       r15
     pop       rax
     pop       rbx
     pop       rcx
     pop       rdx
     pop       rsi
     pop       rdi
     pop       rsp
     pop       rbp
   %endmacro
   
