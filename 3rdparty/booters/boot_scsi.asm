********************************************************************
* Boot - SCSI Boot Module
*
* $Id$
*
* This module allows booting from a hard drive that uses HDB-DOS
* and is controlled by a TC^3, Ken-Ton or Disto SCSI controller.
*
* It was later modified to handle hard drives with sector sizes
* larger than 256 bytes, and works on both 256 byte and larger drives,
* so it should totally replace the old SCSI boot module.
*
* Instructions followed by +++ in the comment field were added for this fix.
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
* 1      Original Roger Krupski distribution version
* 1b     Added code to allow booting from any sector    BGP 96/??/??
*        size hard drive
*        Merged Ken-Ton and TC^3 module source          BGP 02/05/01


         nam   Boot
         ttl   SCSI Boot Module

         IFP1
         use   defsfile
         ENDC

tylg     set   Systm+Objct
atrv     set   ReEnt+rev
rev      set   2
edition  set   1

* Disto Hard Disk II Interface registers
         IFNE  HDII
dataport equ   $FF58
status   equ   dataport-2
select   equ   dataport-1
reset    equ   dataport-2
         ENDC

* Disto 4-N-1 Hard Disk Interface registers
         IFNE  D4N1
dataport equ   $FF5B
status   equ   dataport-2
select   equ   dataport-1
reset    equ   dataport-2
         ENDC

* Hard Disk Interface registers for the Ken-Ton and RGB HDI
         IFNE  KTLR
dataport equ   $FF74
status   equ   dataport+1
select   equ   dataport+2
reset    equ   dataport+3
         ENDC

         IFNE  TC3
dataport equ   $FF74
status   equ   dataport+1
select   equ   dataport+1
         ENDC

* Status register equates
         IFNE  DISTO
req      equ   $80
busy     equ   $01
msg      equ   $04
cmd      equ   $40
inout    equ   $20
ack      equ   $02
sel      equ   $00
         ELSE
req      equ   $01
busy     equ   $02
msg      equ   $04
cmd      equ   $08
inout    equ   $10
ack      equ   $20
sel      equ   $40
rst      equ   $80
         ENDC

*SCSI common command set
c$rstr   equ   1
c$rdet   equ   3
c$rblk   equ   8
c$wblk   equ   10

* Optional command
c$ststop equ   $1b                     park head

* misc
errsta   equ   2
bsybit   equ   8

****************************************************
bootdrv  equ   0
****************************************************

         mod   eom,name,tylg,atrv,start,size

* Data equates; subroutines must keep data in stack
v$cmd    rmb   1
v$addr0  rmb   1
v$addr1  rmb   2
v$blks   rmb   1
v$opts   rmb   1
v$error  rmb   4

blockloc rmb   2                       pointer to memory requested
blockimg rmb   2                       duplicate of the above
bootloc  rmb   3                       sector pointer; not byte pointer
bootsize rmb   2                       size in bytes
size     equ   .

name     fcs   /Boot/
         fcb   edition

start    clra
         ldb   #size
clean    pshs  a
         decb
         bne   clean
         tfr   s,u                     get pointer to data area
         pshs  u                       save pointer to data area

         lda   #$d0                    forced interrupt; kill floppy activity
         sta   $FF48                   command register
         clrb
pause    decb
         bne   pause
         lda   $FF48                   clear controller
         clr   $FF40                   make sure motors are turned off
         IFGT  Level-1
         sta   $FFD9                   fast clock
         ENDC

* Recalibrate hard drive
         lbsr  restore

* Request memory for LSN0
         ldd   #1
         os9   F$SRqMem                request one page of RAM
         bcs   error
         bsr   getpntr

* Get LSN0 into memory
         clrb                          MSB sector
         ldx   #0                      LSW sector
         bsr   mread
         bcs   error
         ldd   bootsize,u
         beq   error
         pshs  d

* Return memory
         ldd   #$100
         ldu   blockloc,u
         os9   F$SRtMem
         puls  d
         IFGT  Level-1
         os9   F$BtMem
         else
         os9   F$SRqMem
         ENDC
         bcs   error
         bsr   getpntr
         std   blockimg,u

* Get os9boot into memory
         ldd   bootsize,u
         leas  -2,s                    same as a PSHS D
getboot  std   ,s
         ldb   bootloc,u               MSB sector location
         ldx   bootloc+1,u             LSW sector location
         bsr   mread
         ldd   bootloc+1,u             update sector location by one to 24bit word
         addd  #1
         std   bootloc+1,u
         ldb   bootloc,u
         adcb  #0
         stb   bootloc,u
         inc   blockloc,u              update memory pointer for upload
         ldd   ,s                      update size of file left to read
         subd  #$100                   file read one sector at a time
         bhi   getboot

         leas  4+size,s                reset the stack    same as PULS U,D
         ldd   bootsize,u
         ldx   blockimg,u              pointer to start of os9boot in memory
         andcc #^Carry                 clear carry
         rts                           back to os9p1

error    leas  2+size,s
         ldb   #E$NotRdy               drive not ready
         rts

getpntr  tfr   u,d                     save pointer to requested memory
         ldu   2,s                     recover pointer to data stack
         std   blockloc,u
         rts

mread    tstb
         bne   read10
         cmpx  #0
         bne   read10
         bsr   read10
         bcc   readlsn0
         rts

readlsn0 pshs  a,x,y
         ldy   blockloc,u
         lda   DD.Bt,y                 os9boot pointer
         ldx   DD.Bt+1,y               LSW of 24 bit address
         sta   bootloc,u
         stx   bootloc+1,u
         ldx   DD.BSZ,y                os9boot size in bytes
         stx   bootsize,u
         clrb
         puls  a,x,y,pc

* Generic read
read10   lda   #c$rblk
         bsr   setup
         bra   command

setup    pshs  b
         sta   v$cmd,u
         stb   v$addr0,u
         stx   v$addr1,u
         ldb   #1
         stb   v$blks,u
         clr   v$opts,u
         puls  b,pc

wakeup   ldx   #0
wake     lda   status
         bita  #busy+sel
         beq   wake1
         leax  -1,x
         bne   wake
         bra   wake4
wake1    bsr   wake3
         lda   defid,pcr
         sta   dataport
         bsr   wake3
         sta   select
         ldx   #0
wake2    lda   status
         bita  #busy
         bne   wake3
         leax  -1,x
         bne   wake2
wake4    leas  2,s
         comb
         ldb   #E$NotRdy
wake3    rts

command  bsr   wakeup
         leax  v$cmd,u
         bsr   send
         bsr   waitrq
         bita  #cmd
         bne   getsta
         ldx   blockloc,u
         bsr   read
getsta   bsr   instat
         bita  #bsybit
         bne   command
         bita  #errsta
         beq   done
         comb
done     rts

send     bsr   waitrq
         bita  #cmd
         beq   done
         bita  #inout
         bne   done
         lda   ,x+
         sta   dataport
         bra   send

waitrq   pshs  b,x
wait10   lda   status
         bita  #req
         beq   wait10
         puls  b,x,pc

* Patch to allow booting from sector sizes > 256 bytes - BGP 08/16/97
* We ignore any bytes beyond byte 256, but continue to read them from
* the dataport until the CMD bit is set.
read
* next 2 lines added
         clrb                          +++ use B as counter
read2
         bsr   waitrq
         bita  #cmd
         bne   done
         lda   dataport
         sta   ,x+
* next line commented out and next 8 lines added
* bra read
         incb                          +++
         bne   read2                   +++
read3
         bsr   waitrq                  +++
         bita  #cmd                    +++
         bne   done                    +++
         lda   dataport                +++
         bra   read3                   +++

instat   bsr   waitrq
         lda   dataport
         anda  #%00001111
         pshs  a
         bsr   waitrq
         clra
         sta   dataport
         puls  a,pc

restore  lda   #c$rstr
         clrb
         ldx   #0
         lbsr  setup
         clr   v$blks,u
         bra   command

         IFGT  Level-1
* Fillers to get to $1D0
Pad      fill  $39,$1D0-4-*
         ENDC

* The default SCSI ID is here
defid    fcb   scsiid

         emod
eom      equ   *
         end

