********************************************************************
* RX - NitrOS-9 Level 2 RAM Disk Device Descriptor
*
* $Id$
*
* Edt/Rev  YYYY/MM/DD  Modified by
* Comment
* ------------------------------------------------------------------

         nam   RX        
         ttl   NitrOS-9 Level 2 RAM Disk Device Descriptor

         ifp1            
         use   defsfile  
         endc            

tylg     set   Devic+Objct
atrv     set   ReEnt+rev 
rev      set   $00       

Sectors  set   512       
SAS      set   4         

         mod   eom,name,tylg,atrv,mgrnam,drvnam

         fcb   DIR.+PREAD.+PWRIT.+PEXEC.+READ.+WRITE.+EXEC. mode byte
         fcb   $00        extended controller address
         fdb   $0000      physical controller address
         fcb   initsize-*-1 initilization table size
         fcb   $01        device type:0=scf,1=rbf,2=pipe,3=scf
         fcb   $00        drive number
         fcb   $00        step rate
         fcb   $00        drive device type
         fcb   $00        media density:0=single,1=double
         fdb   $0000      number of cylinders (tracks)
         fcb   $01        number of sides
         fcb   $00        verify disk writes:0=on
         fdb   Sectors    # of sectors per track
         fdb   $0000      # of sectors per track (track 0)
         fcb   $00        sector interleave factor
         fcb   SAS        minimum size of sector allocation

initsize equ   *         

         IFNE   DD
name     fcs   /DD/
         ELSE
name     fcs   /R0/      
         ENDC
mgrnam   fcs   /RBF/     
drvnam   fcs   /RAM/     

         emod            
eom      equ   *         
         end             