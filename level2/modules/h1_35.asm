********************************************************************
* H1 - CCHDisk device descriptor
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------

         nam   H1
         ttl   CCHDisk device descriptor

* Disassembled 98/08/23 18:21:46 by Disasm v1.6 (C) 1988 by RML

         ifp1  
         use   defsfile
         use   rbfdefs
         endc  

dnum     equ   1

tylg     set   Devic+Objct
atrv     set   ReEnt+rev
rev      set   $00

         mod   eom,name,tylg,atrv,mgrnam,drvnam

         fcb   DIR.!ISIZ.!SHARE.!PEXEC.!PWRIT.!PREAD.!EXEC.!UPDAT. mode byte
         fcb   $07        extended controller address
         fdb   $FF51      physical controller address
         fcb   initsize-*-1 initilization table size
         fcb   DT.RBF     device type:0=scf,1=rbf,2=pipe,3=scf
         fcb   dnum       drive number
         fcb   $00        step rate
         fcb   TYP.HARD   drive device type
         fcb   DNS.FM     media density:0=single,1=double
         fdb   512        number of cylinders (tracks)
         fcb   8          number of sides
         fcb   0          verify disk writes:0=on
         fdb   32         # of sectors per track
         fdb   32         # of sectors per track (track 0)
         fcb   26         sector interleave factor
         fcb   32         minimum size of sector allocation
         fcb   $00
         fcb   $00
         fcb   $00
         fcb   $00
initsize equ   *
         fcb   $40
         fcb   $0A
         fcb   $02
         fcb   $00
         fcb   $03
         fcb   $02
         fcb   $0D

name     fcc   /H/
         fcb   176+dnum
mgrnam   fcs   /RBF/
drvnam   fcs   /CC3HDisk/

         emod  
eom      equ   *
         end   

