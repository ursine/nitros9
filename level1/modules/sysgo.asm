********************************************************************
* SysGo - OS-9 Level One 2 SysGo
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*  12    From Tandy OS-9 Level One VR 02.00.00
*  13    Incremented version number to reflect Y2K      BGP 99/05/11
*        fixes
*  14    Updated to reflect new release, changed /H0    BGP 02/07/19
*        to /DD

         nam   SysGo
         ttl   OS-9 Level One 2 SysGo

         ifp1
         use   defsfile
         use   scfdefs
         endc

tylg     set   Systm+Objct
atrv     set   ReEnt+rev
rev      set   $01
edition  set   14

         mod   eom,name,tylg,atrv,start,size

dataarea rmb   200
size     equ   .

name     fcs   /SysGo/
         fcb   edition

* default OS-9 priority
DefPrior set   128

BootMsg  fcc   "OS-9 LEVEL ONE VR. 0"
         fcb   48+OS9Vrsn
         fcc   ".0"
         fcb   48+OS9Major
         fcc   ".0"
         fcb   48+OS9Minor
         fdb   C$CR,C$LF
         fcc   "COPR. 2002 ACADIAN EMBEDDED"
         fdb   C$CR,C$LF
         fcc   "COPR. 1980 BY MOTOROLA INC. AND"
         fdb   C$CR,C$LF
         fcc   "MICROWARE SYSTEMS CORP."
         fdb   C$CR,C$LF
         fcc   "LICENSED TO TANDY CORP."
         fdb   C$CR,C$LF
         fcc   "ALL RIGHTS RESERVED."
         fdb   C$CR,C$LF
         fcb   C$LF
MsgEnd   equ   *

ChdDev   fcc   "/DD"
         fcb   C$CR
ChxDev   fcc   "/DD/"
ChxPath  fcc   "CMDS"
         fcb   C$CR
         fcc   ",,,,,,,,,,"

Shell    fcc   "Shell"
         fcb   C$CR

         fcc   "tsmon"
         fcb   C$CR
Startup  fcc   "startup -p"
         fcb   C$CR
         fcc   ",,,,,,,,,,"
StartupL equ   *-Startup

* Default time packet
*              YY MM DD HH MM SS
TimePckt fcb   102,08,01,00,00,00

* BASIC reset code
BasicRst fcb   $55
         neg   <$0074
         nop
         clr   >$FF03
         nop
         nop
         sta   >$FFDF		turn off ROM mode
         jmp   >$EF0E		jump to boot
BasicRL  equ   *-BasicRst

* SysGo entry point
start    leax  >IcptRtn,pcr
         os9   F$Icpt
         leax  >BasicRst,pcr
         ldu   #D.CBStrt
         ldb   #BasicRL
CopyLoop lda   ,x+
         sta   ,u+
         decb
         bne   CopyLoop

* Print boot message
         leax  >BootMsg,pcr
         ldy   #MsgEnd-BootMsg
         lda   #$01
         os9   I$Write
         leax  >TimePckt,pcr
         os9   F$STime
         leax  >ChxPath,pcr
         lda   #EXEC.
         os9   I$ChgDir
         leax  >ChdDev,pcr
         lda   #UPDAT.
         os9   I$ChgDir
         bcs   DoStrtup
         leax  >ChxDev,pcr
         lda   #EXEC.
         os9   I$ChgDir
         bcc   DoStrtup

* Set priority and do startup file
DoStrtup os9   F$ID
         ldb   #DefPrior
         os9   F$SPrior
         leax  >Shell,pcr
         leau  >Startup,pcr
         ldd   #256
         ldy   #StartupL
         os9   F$Fork
         bcs   DeadEnd
         os9   F$Wait

FrkShell leax  >Shell,pcr
         ldd   #256
         ldy   #$0000
         os9   F$Fork
         bcs   DeadEnd
         os9   F$Wait
         bcc   FrkShell
DeadEnd  bra   DeadEnd

* Intercept routine
IcptRtn  rti

         emod
eom      equ   *
         end
