********************************************************************
* Echo - Echo text
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
* 5      Original Tandy distribution version

         nam   Echo
         ttl   Echo text

* Disassembled 98/09/10 22:44:14 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $01
edition  set   5

         mod   eom,name,tylg,atrv,start,size

u0000    rmb   450
size     equ   .

name     fcs   /Echo/
         fcb   edition

start    tfr   d,y
         lda   #1
         os9   I$WritLn 
         bcs   Exit
         clrb  
Exit     os9   F$Exit   

         emod
eom      equ   *
         end
