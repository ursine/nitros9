********************************************************************
* Display  - display control codes
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*  2     Original Tandy version                         BGP 02/04/05

         nam   Display
         ttl   display control codes

* Disassembled 02/04/05 15:13:55 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $01

         mod   eom,name,tylg,atrv,start,size

u0000    rmb   450
size     equ   .

name     fcs   /Display/
         fcb   $02 

start    cmpd  #$0001
         bls   L0036
         pshs  x
         leay  ,x
L001F    bsr   L003A
         bcs   L0027
         stb   ,x+
         bra   L001F
L0027    tfr   x,d
         subd  ,s
         tfr   d,y
         puls  x
         lda   #$01
         os9   I$Write  
         bcs   L0037
L0036    clrb  
L0037    os9   F$Exit   
L003A    ldb   ,y+
         cmpb  #C$COMA
         bne   L0042
L0040    ldb   ,y+
L0042    cmpb  #C$SPAC
         beq   L0040
         leay  -$01,y
         bsr   L0062
         bcs   L0061
         pshs  b
         bsr   L0062
         bcs   L005E
         lsl   ,s
         lsl   ,s
         lsl   ,s
         lsl   ,s
         addb  ,s
         stb   ,s
L005E    clrb  
         puls  b
L0061    rts   

L0062    ldb   ,y
         subb  #$30
         cmpb  #$09
         bls   L007A
         cmpb  #$31
         bcs   L0070
         subb  #$20
L0070    subb  #$07
         cmpb  #$0F
         bhi   L007F
         cmpb  #$0A
         bcs   L007F
L007A    andcc #$FE
         leay  $01,y
         rts   
L007F    comb  
         rts   

         emod
eom      equ   *
         end

