********************************************************************
* Dump - Show file contents in hex
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*   5    From Tandy OS-9 Level One VR 02.00.00
*   6    Incorporated R. Telkman's additions from 1987, BGP 02/12/23
*        added -d option, added defs to conditionally
*        assemble without help or screen size check
*
* Dump follows the function of the original Microware version but now
* supports large files over 64K, and is free from the problems of garbage
* in wide listings.
*
* In addition it now allows dumping of memory modules and command modules
* in the execution directory.

         nam   Dump
         ttl   Show file contents in hex

         ifp1
         use   defsfile  
         endc

* Tweakable options
DOSCSIZ  set   1	1 = include SS.ScSiz code, 0 = leave out
DOHELP   set   0	1 = include help message, 0 = leave out

Edition  set   6         
Revs     set   1         
BufSz    set   80        

         org   0         
nonopts  rmb   1
D.Prm    rmb   2         
D.Hdr    rmb   1         
D.Mem    rmb   1         
         IFNE  DOSCSIZ
DoWide   rmb   1         
         ENDC
Mode     rmb   1         
D.Opn    rmb   1         
D.Beg    rmb   2         
D.End    rmb   2         
D.Adr    rmb   4         
D.Len    rmb   2         
D.Ptr    rmb   2         
D.Txt    rmb   2         
Datbuf   rmb   16        
Txtbuf   rmb   BUFSZ     
         rmb   128
datsz    equ   .         

typ      equ   Prgrm+Objct
att      equ   ReEnt+Revs

         mod   length,name,typ,att,entry,datsz

name     fcs   /Dump/    
         fcb   Edition   

title    fcc   /Address   0 1  2 3  4 5  6 7  8 9  A B  C D  E F  0 2 4 6 8 A C E/
caret    fcb   C$CR      
flund    fcc   /-------- ---- ---- ---- ---- ---- ---- ---- ----  ----------------/
         fcb   C$CR      
         IFNE  DOSCSIZ
short    fcc   /         0 1 2 3 4 5 6 7  0 2 4 6/
         fcb   C$LF      
         fcc   /Address  8 9 a b c d e f  8 a c e/
         fcb   C$CR      
shund    fcc   /======== +-+-+-+-+-+-+-+- + + + + /
         fcb   C$CR      
         ENDC

entry    stx   <D.Prm    
         clra            
         sta   <D.Hdr    
         sta   <D.Mem    
         sta   <nonopts		assume no non-opts
         inca
         sta   <Mode            READ.

         IFNE  DOSCSIZ
         sta   <DoWide          assume wide

* Check screen size
         ldb   #SS.ScSiz
         os9   I$GetStt
         bcs   Pass1

         cmpx  #64
         bge   PrePass

         clr   <DoWide

PrePass  ldx   <D.Prm
         ENDC

* Pass1 - process any options
* Entry: X = ptr to cmd line
Pass1
* Skip over spaces
         lda   ,x+
         cmpa  #C$SPAC
         beq   Pass1

* Check for EOL
         cmpa  #C$CR
         beq   Pass2

* Check for option
         cmpa  #'-
         bne   Pass1

* Here, X points to an option char
OptPass  lda   ,x+
         cmpa  #C$SPAC
         beq   Pass1
         cmpa  #C$CR
         beq   Pass2

         anda  #$DF

         cmpa  #'D
         bne   IsItH

* Process D here
         lda   <Mode
         ora   #DIR.
         sta   <Mode
         bra   OptPass
 
IsItH    cmpa  #'H
         bne  IsItM

* Process H here
         sta  <D.Hdr
         bra  OptPass

IsItM    cmpa  #'M
         bne   IsItX

* Process M here 
         sta   <D.Mem
         bra   OptPass

IsItX    cmpa  #'X
         bne  ShowHelp

* Process X here
         lda   <Mode
         ora   #EXEC.
         sta   <Mode
         bra   OptPass
 
         IFNE  DOHELP
ShowHelp leax  HelpMsg,pcr
         lda   #2
         ldy   #HelpLen
         os9   I$Write
         bra   ExitOk
         ENDC

* Pass2 - process any non-options
* Entry: X = ptr to cmd line
Pass2
         ldx   <D.Prm
Pass21
* Skip over spaces
         lda   ,x+
         cmpa  #C$SPAC
         beq   Pass21
         cmpa  #'-
         bne   Pass22

EatOpts  lda   ,x+
         cmpa  #C$SPAC
         beq   Pass21
         cmpa  #C$CR
         bne   EatOpts

* Check for EOL
Pass22   cmpa  #C$CR
         beq   EndOfL

Call     leax  -1,x
         sta   nonopts,u
         bsr   DumpFile
         bra   Pass21

EndOfL   tst   <nonopts		any non-options on cmd line?
         bne   ExitOk
         tst   <D.Mem           memory option specified?
         bne   ShowHelp		yes, no module specified, show help
         clra                   stdin
         bsr   DumpIn
         IFEQ  DOHELP
ShowHelp
         ENDC
ExitOk   clrb
DoExit   os9   F$Exit

mlink    clra            
         pshs  u         
         os9   F$Link    
         stu   <D.Beg    
         puls  u         
         bcc   DumpIn     
         bra   DoExit

DumpFile
* ldx   <D.Prm    
         tst   <D.Mem    
         bne   mlink     
         lda   <Mode
opath    os9   I$Open    
         bcs   DoExit
DumpIn   stx   <D.Prm    
         sta   <D.Opn    
         ldx   <D.Beg    
         ldd   M$Size,x  
         leax  d,x       
         stx   <D.End    
         clra            
         clrb            
         tfr   d,x       
onpas    std   <D.Adr+2  
         bcc   notbg     
         leax  1,x       
notbg    stx   <D.Adr    
         tst   <D.Hdr    
         bne   nohed     
         IFNE  DOSCSIZ
         tst   <DoWide
         bne   flpag     
         aslb            
         ENDC
flpag    tstb            
         bne   nohed     
         leax  caret,pcr
         lbsr  print     
         ldb   #16       
         leax  title,pcr 
         leay  flund,pcr 
         IFNE  DOSCSIZ
         tst   <DoWide
         bne   doprt     
         ldb   #8        
         leax  short,pcr
         leay  shund,pcr
         ENDC
doprt    pshs  y         
         clra            
         std   <D.Len    
         bsr   print     
         puls  x         
         bsr   print     
nohed    leax  Txtbuf,u  
         stx   <D.Ptr    
         ldb   <D.Len+1  
         lda   #3        
         mul             
         addd  #2        
         leay  d,x       
         sty   <D.Txt    
         lda   #C$SPAC   
         ldb   #BUFSZ-1  
clbuf    sta   b,x       
         decb            
         bpl   clbuf     
         ldb   #D.Adr    
adlop    lda   b,u       
         lbsr  onbyt     
         incb            
         cmpb  #D.Adr+4  
         bne   adlop     
         ldx   <D.Ptr    
         leax  1,x       
         stx   <D.Ptr    
         bsr   readi     
         bcs   eofck     
onlin    lbsr  onchr     
         decb
         ble   enlin
         lbsr  onchr     
         decb
*         bitb  #1
         ble   enlin     
         lda   #C$SPAC   
         bsr   savec     
         bra   onlin     
enlin    lda   #C$CR     
         ldx   <D.Txt    
         sta   ,x        
         leax  Txtbuf,u  
         bsr   print     
         ldd   <D.Adr+2  
         ldx   <D.Adr    
         addd  <D.Len    
         lbra  onpas     
print    ldy   #BUFSZ    
         lda   #1
         os9   I$WritLn  
         lbcs  DoExit
         rts             
readi    ldy   <D.Len    
         clrb            
         tst   <D.Mem    
         bne   redad     
         leax  Datbuf,u  
         lda   <D.Opn    
         os9   I$Read    
         bcs   reded     
         tfr   y,d       
reded    rts             
redad    ldd   <D.End    
         ldx   <D.Beg    
         subd  <D.Beg    
         bne   setct     
         coma            
         ldb   #E$EOF    
         rts             
setct    subd  <D.Len    
         bcs   redof     
         clra            
         clrb            
redof    addd  <D.Len    
         clr   -1,s      
         leay  d,x       
         sty   <D.Beg    
         rts             
eofck    cmpb  #E$EOF    
         orcc  #Carry    
         lbne  DoExit     
         clrb            
         ldx   <D.Prm    
         rts

onibl    anda  #15       
         cmpa  #9        
         bls   nocom     
         adda  #7        
nocom    adda  #'0       
savec    pshs  x         
         ldx   <D.Ptr    
         sta   ,x+       
         stx   <D.Ptr    
         puls  x,pc      
onchr    lda   ,x+       
         bsr   onbyt     
         pshs  x,a       
         anda  #127      
         cmpa  #C$SPAC   
         bcc   savet     
         lda   #'.       
savet    ldx   <D.Txt    
         sta   ,x+       
         stx   <D.Txt    
         puls  a,x,pc    
onbyt    pshs  a         
         lsra            
         lsra            
         lsra            
         lsra            
         bsr   onibl     
         lda   ,s        
         bsr   onibl     
         puls  a,pc      

         IFNE  DOHELP
HelpMsg  fcc   "Use: Dump [opts] [<path>] [opts]"
         fcb   C$CR,C$LF
         fcc   "  -d = dump directory"
         fcb   C$CR,C$LF
         fcc   "  -h = no header"
         fcb   C$CR,C$LF
         fcc   "  -m = module in memory"
         fcb   C$CR,C$LF
         fcc   "  -x = file in exec dir"
         fcb   C$CR,C$LF
HelpLen  equ   *-HelpMsg
         ENDC

         emod            
length   equ   *         
         end             
