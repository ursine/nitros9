********************************************************************
* SACIA - 6551 Driver
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
*        NitrOS-9 2.00 distribution                         ??/??/??

           nam   SACIA
           ttl   6551 Driver

           ifp1
           use   defsfile
           use   scfdefs
           endc

* conditional assembly switches
TC9        set   false          "true" for TC-9 version, "false" for Coco 3
MPIFlag    set   true           "true" MPI slot selection, "false" no slot

* miscellaneous definitions
DCDStBit   equ   %00100000      DCD status bit for SS.CDSta call
DSRStBit   equ   %01000000      DSR status bit for SS.CDSta call
Edtn       equ   10
SlpBreak   set   TkPerSec/2+1   line Break duration
SlpHngUp   set   TkPerSec/2+1   hang up (drop DTR) duration
Vrsn       equ   1

       ifeq  TC9-true
IRQBit     equ   %00000100      GIME IRQ bit to use for IRQ ($FF92)
       else
IRQBit     equ   %00000001      GIME IRQ bit to use for IRQ ($FF92)
       endc

           nam   SACIA
           ttl   6551           Single ACIA driver

* 6551 register definitions
           org   0
DataReg    rmb   1              receive/transmit Data (read Rx / write Tx)
StatReg    rmb   1              status (read only)
PRstReg    equ   StatReg        programmed reset (write only)
CmdReg     rmb   1              command (read/write)
CtlReg     rmb   1              control (read/write)

* Status bit definitions
Stat.IRQ   equ   %10000000      IRQ occurred
Stat.DSR   equ   %01000000      DSR level (clear = active)
Stat.DCD   equ   %00100000      DCD level (clear = active)
Stat.TxE   equ   %00010000      Tx data register Empty
Stat.RxF   equ   %00001000      Rx data register Full
Stat.Ovr   equ   %00000100      Rx data Overrun error
Stat.Frm   equ   %00000010      Rx data Framing error
Stat.Par   equ   %00000001      Rx data Parity error

Stat.Err   equ   Stat.Ovr!Stat.Frm!Stat.Par Status error bits
Stat.Flp   equ   $00            all Status bits active when set
Stat.Msk   equ   Stat.IRQ!Stat.RxF active IRQs

* Control bit definitions
Ctl.Stop   equ   %10000000      stop bits (set=two, clear=one)
Ctl.DBit   equ   %01100000      see data bit table below
Ctl.RxCS   equ   %00010000      Rx clock source (set=baud rate, clear=external)
Ctl.Baud   equ   %00001111      see baud rate table below

* data bit table
DB.8       equ   %00000000      eight data bits per character
DB.7       equ   %00100000      seven data bits per character
DB.6       equ   %01000000      six data bits per character
DB.5       equ   %01100000      five data bits per character

* baud rate table
           org   $00
BR.ExClk   rmb   1              16x external clock (not supported)
           org   $11
BR.00050   rmb   1              50 baud (not supported)
BR.00075   rmb   1              75 baud (not supported)
BR.00110   rmb   1              109.92 baud
BR.00135   rmb   1              134.58 baud (not supported)
BR.00150   rmb   1              150 baud (not supported)
BR.00300   rmb   1              300 baud
BR.00600   rmb   1              600 baud
BR.01200   rmb   1              1200 baud
BR.01800   rmb   1              1800 baud (not supported)
BR.02400   rmb   1              2400 baud
BR.03600   rmb   1              3600 baud (not supported)
BR.04800   rmb   1              4800 baud
BR.07200   rmb   1              7200 baud (not supported)
BR.09600   rmb   1              9600 baud
BR.19200   rmb   1              19200 baud

* Command bit definitions
Cmd.Par    equ   %11100000      see parity table below
Cmd.Echo   equ   %00010000      local echo (set=activated)
Cmd.TIRB   equ   %00001100      see Tx IRQ/RTS/Break table below
Cmd.RxI    equ   %00000010      Rx IRQ (set=disabled)
Cmd.DTR    equ   %00000001      DTR output (set=enabled)

* parity table
Par.None   equ   %00000000
Par.Odd    equ   %00100000
Par.Even   equ   %01100000
Par.Mark   equ   %10100000
Par.Spac   equ   %11100000

* Tx IRQ/RTS/Break table
TIRB.Off   equ   %00000000      RTS & Tx IRQs disabled
TIRB.On    equ   %00000100      RTS & Tx IRQs enabled
TIRB.RTS   equ   %00001000      RTS enabled, Tx IRQs disabled
TIRB.Brk   equ   %00001100      RTS enabled, Tx IRQs disabled, Tx line Break

* V.ERR bit definitions
DCDLstEr   equ   %00100000      DCD lost error
OvrFloEr   equ   %00000100      Rx data overrun or Rx buffer overflow error
FrmingEr   equ   %00000010      Rx data framing error
ParityEr   equ   %00000001      Rx data parity error

* FloCtlRx bit definitions
FCRxSend   equ   %10000000      send flow control character
FCRxSent   equ   %00010000      Rx disabled due to XOFF sent
FCRxDTR    equ   %00000010      Rx disabled due to DTR
FCRxRTS    equ   %00000001      Rx disabled due to RTS

* FloCtlTx bit definitions
FCTxXOff   equ   %10000000      due to XOFF received
FCTxBrk    equ   %00000010      due to currently transmitting Break

* Wrk.Type bit definitions
Parity     equ   %11100000      parity bits
MdmKill    equ   %00010000      modem kill option
RxSwFlow   equ   %00001000      Rx data software (XON/XOFF) flow control
TxSwFlow   equ   %00000100      Tx data software (XON/XOFF) flow control
RTSFlow    equ   %00000010      CTS/RTS hardware flow control
DSRFlow    equ   %00000001      DSR/DTR hardware flow control

* Wrk.Baud bit definitions
StopBits   equ   %10000000      number of stop bits code
WordLen    equ   %01100000      word length code
BaudRate   equ   %00001111      baud rate code

* Wrk.XTyp bit definitions
SwpDCDSR   equ   %10000000      swap DCD+DSR bits (valid for 6551 only)
ForceDTR   equ   %01000000      don't drop DTR in term routine
RxBufPag   equ   %00001111      input buffer page count

* static data area definitions
           org   V.SCF          allow for SCF manager data area
Cpy.Stat   rmb   1              Status register copy
CpyDCDSR   rmb   1              DSR+DCD status copy
Mask.DCD   rmb   1              DCD status bit mask (MUST immediately precede Mask.DSR)
Mask.DSR   rmb   1              DSR status bit mask (MUST immediately follow Mask.DCD)
CDSigPID   rmb   1              process ID for CD signal
CDSigSig   rmb   1              CD signal code
FloCtlRx   rmb   1              Rx flow control flags
FloCtlTx   rmb   1              Tx flow control flags
RxBufEnd   rmb   2              end of Rx buffer
RxBufGet   rmb   2              Rx buffer output pointer
RxBufMax   rmb   2              Send XOFF (if enabled) at this point
RxBufMin   rmb   2              Send XON (if XOFF sent) at this point
RxBufPtr   rmb   2              pointer to Rx buffer
RxBufPut   rmb   2              Rx buffer input pointer
RxBufSiz   rmb   2              Rx buffer size
RxDatLen   rmb   2              current length of data in Rx buffer
SigSent    rmb   1              keyboard abort/interrupt signal already sent
SSigPID    rmb   1              SS.SSig process ID
SSigSig    rmb   1              SS.SSig signal code
WritFlag   rmb   1              initial write attempt flag
Wrk.Type   rmb   1              type work byte (MUST immediately precede Wrk.Baud)
Wrk.Baud   rmb   1              baud work byte (MUST immediately follow Wrk.Type)
Wrk.XTyp   rmb   1              extended type work byte
regWbuf    rmb   2              substitute for regW
RxBufDSz   equ   256-.          default Rx buffer gets remainder of page...
RxBuff     rmb   RxBufDSz       default Rx buffer
MemSize    equ   .

           mod   ModSize,ModName,Drivr+Objct,ReEnt+Vrsn,ModEntry,MemSize

           fcb   UPDAT.         access mode(s)

ModName    fcs   "SACIA"
           fcb   Edtn

       ifeq  MPIFlag-true
SlotSlct   fcb   MPI.Slot       selected MPI slot
       else
SlotSlct   fcb   $FF            disable MPI slot selection
       endc

IRQPckt    equ   *
Pkt.Flip   fcb   Stat.Flp       flip byte
Pkt.Mask   fcb   Stat.Msk       mask byte
           fcb   $0A            priority

BaudTabl   equ   *
           fcb   BR.00110,BR.00300,BR.00600
           fcb   BR.01200,BR.02400,BR.04800
           fcb   BR.09600,BR.19200

* NOTE:  SCFMan has already cleared all device memory except for V.PAGE and
*        V.PORT.  Zero-default variables are:  CDSigPID, CDSigSig, Wrk.XTyp.
Init       clrb                 default to no error...
           pshs  cc,b,dp        save IRQ/Carry status, dummy B, system DP
           IFNE  H6309
           tfr   u,w
           tfr   e,dp
           tfr   y,w            save descriptor pointer
           ELSE
           clrb
           tfr   b,dp
           ENDC
           ldd   <V.PORT        base hardware address
           IFNE  H6309
           incd                 point to 6551 status address
           ELSE
           addd  #$0001
           pshs  y
           ENDC
           leax  IRQPckt,pc
           leay  IRQSvc,pc
           os9   F$IRQ
           IFNE  H6309
           tfr   w,y            recover descriptor pointer
           ELSE
           puls  y
           ENDC
           lbcs  ErrExit        go report error...
           ldb   M$Opt,y        get option size
           cmpb  #IT.XTYP-IT.DTP room for extended type byte?
           bls   DfltInfo       no, go use defaults...
           ldd   #Stat.DCD*256+Stat.DSR default (unswapped) DCD+DSR masks
           tst   IT.XTYP,y      check extended type byte for swapped DCD & DSR bits
           bpl   NoSwap         no, go skip swapping them...
           exg   a,b            swap to DSR+DCD masks
NoSwap     std   <Mask.DCD      save DCD+DSR (or DSR+DCD) masks
           lda   IT.XTYP,y      get extended type byte
           sta   <Wrk.XTyp      save it
           anda  #RxBufPag      clear all but Rx buffer page count bits
           beq   DfltInfo       none, go use defaults...
           clrb                 make data size an even number of pages
           IFNE  H6309
           tfr   u,w            save data pointer
           ELSE
           pshs  u
           ENDC
           os9   F$SRqMem       get extended buffer
           tfr   u,x            copy address
           IFNE  H6309
           tfr   w,u            recover data pointer
           ELSE
           puls  u
           ENDC
           lbcs  TermExit       error, go remove IRQ entry and exit...
           bra   SetRxBuf
DfltInfo   ldd   #RxBufDSz      default Rx buffer size
           leax  RxBuff,u       default Rx buffer address
SetRxBuf   std   <RxBufSiz      save Rx buffer size
           stx   <RxBufPtr      save Rx buffer address
           stx   <RxBufGet      set initial Rx buffer input address
           stx   <RxBufPut      set initial Rx buffer output address
           IFNE  H6309
           addr  d,x            point to end of Rx buffer
           ELSE
           leax  d,x
           ENDC
           stx   <RxBufEnd      save Rx buffer end address
           subd  #80            characters available in Rx buffer
           std   <RxBufMax      set auto-XOFF threshold
           ldd   #10            characters remaining in Rx buffer
           std   <RxBufMin      set auto-XON threshold after auto-XOFF
           ldb   #TIRB.RTS      default command register
           IFNE  H6309
           tim   #ForceDTR,<Wrk.XTyp
           ELSE
* lines seemed to be missing here. RG
           lda   #ForceDTR
           bita  <Wrk.XTyp
           ENDC
           beq   NoDTR          no, don't enable DTR yet
           orb   #Cmd.DTR       set (enable) DTR bit
NoDTR      ldx   <V.PORT        get port address
           stb   CmdReg,x       set new command register
           ldd   IT.PAR,y       [A] = IT.PAR, [B] = IT.BAU from descriptor
           lbsr  SetPort        go save it and set up control/format registers
           orcc  #IntMasks      disable IRQs while setting up hardware
           IFEQ  TC9-true
           ELSE
           IFNE  H6309
           aim   #$FC,>PIA1Base+3
           ELSE
           lda   >PIA1Base+3
           anda  #$FC
           sta   >PIA1Base+3
           ENDC
           lda   >PIA1Base+2    clear possible pending PIA CART* FIRQ
           ENDC
           lda   #IRQBit        get GIME IRQ bit to use
           ora   >D.IRQER       mask in current GIME IRQ enables
           sta   >D.IRQER       save GIME CART* IRQ enable shadow register
           sta   >IrqEnR        enable GIME CART* IRQs
           lda   StatReg,x      ensure old IRQ flags are clear
           lda   DataReg,x      ensure old error and Rx data IRQ flags are clear
           lda   StatReg,x      ... again
           lda   DataReg,x      ... and again
           lda   StatReg,x      get new Status register contents
           sta   <Cpy.Stat      save Status copy
           tfr   a,b            copy it...
           eora  Pkt.Flip,pc    flip bits per D.Poll
           anda  Pkt.Mask,pc    any IRQ(s) still pending?
           lbne  NRdyErr        yes, go report error... (device not plugged in?)
           andb  #Stat.DSR!Stat.DCD clear all but DSR+DCD status
           stb   <CpyDCDSR      save new DCD+DSR status copy
           IFEQ  MPIFlag-true
           lda   SlotSlct,pc    get MPI slot select value
           bmi   NoSelect       no MPI slot select, go on...
           sta   >MPI.Slct      set MPI slot select register
           ENDC
NoSelect   puls  cc,b,dp,pc     recover IRQ/Carry status, dummy B, system DP, return

Term       clrb                 default to no error...
           pshs  cc,dp          save IRQ/Carry status, dummy B, system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           ELSE
* missing lines
           stu   <regWbuf
           lda   <regWbuf
           tfr   a,dp
           ENDC
           ldx   <V.PORT
           lda   CmdReg,x       get current Command register contents
           anda  #^(Cmd.TIRB!Cmd.DTR) disable Tx IRQs, RTS, and DTR
           ora   #Cmd.RxI       disable Rx IRQs
           ldb   <Wrk.XTyp      get extended type byte
           andb  #ForceDTR      forced DTR?
           beq   KeepDTR        no, go leave DTR disabled...
           ora   #Cmd.DTR       set (enable) DTR bit
KeepDTR    sta   CmdReg,x       set DTR and RTS enable/disable
           ldd   <RxBufSiz      get Rx buffer size
           tsta                 less than 256 bytes?
           beq   TermExit       yes, no system memory to return...
           pshs  u              save data pointer
           ldu   <RxBufPtr      get address of system memory
           os9   F$SRtMem
           puls  u              recover data pointer
TermExit   ldd   <V.PORT        base hardware address is status register
           IFNE  H6309
           incd                 point to 6551 status register
           ELSE
           addd  #$0001
           ENDC
           ldx   #$0000         remove IRQ table entry
           leay  IRQSvc,pc
           puls  cc             recover IRQ/Carry status
           os9   F$IRQ
           puls  dp,pc          restore dummy A, system DP, return

ReadSlp    ldd   >D.Proc        process descriptor address
           sta   <V.WAKE        save MSB for IRQ service routine
           tfr   d,x            copy process descriptor address
           IFNE  H6309
           oim   #Suspend,P$State,x
           ELSE
           ldb   P$State,x
           orb   #Suspend
           stb   P$State,x
           ENDC
           lbsr  Sleep1         go suspend process...
           ldx   >D.Proc        process descriptor address
           ldb   P$Signal,x     pending signal for this process?
           beq   ChkState       no, go check process state...
           cmpb  #S$Intrpt      do we honor signal?
           lbls  ErrExit        yes, go do it...
ChkState   equ   *
           IFNE  H6309
           tim   #Condem,P$State,x
           ELSE
           ldb   P$State,x
           bitb  #Condem
           ENDC
           bne   PrAbtErr       yes, go do it...
           ldb   <V.WAKE        true interrupt?
           beq   ReadChk        yes, go read the char.
           bra   ReadSlp        no, go suspend the process

Read       clrb                 default to no errors...
           pshs  cc,dp          save IRQ/Carry status, system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           ELSE
*missing lines
           stu   <regWbuf
           lda   <regWbuf
           tfr   a,dp
           ENDC
ReadLoop   orcc  #IntMasks      disable IRQs while checking Rx flow control
ReadChk    lda   <FloCtlRx      get Rx flow control flags
           beq   ReadChar       none, go get Rx character...
           ldx   <RxDatLen      get Rx data count again
           cmpx  <RxBufMin      at or below XON level?
           bhi   ReadChar       no, go get Rx character...
           ldx   <V.PORT
           bita  #FCRxSent      Rx disabled due to XOFF sent?
           beq   ChkHWHS        no, go check hardware handshake(s)...
           ldb   <FloCtlTx      get Tx flow control flags
           bitb  #FCTxBrk       currently transmitting line Break?
           beq   NotTxBrk       yes, go skip XON this time...
ReadLp2    andcc #^IntMasks     turn interupts back on
           bra   ReadLoop
NotTxBrk   equ   *
           IFNE  H6309
           tim   #Stat.TxE,StatReg,x
           ELSE
           pshs  a
           lda   StatReg,x
           bita  #Stat.TxE
           puls  a
           ENDC
           beq   ReadLp2        no, go skip XON this time...
           ldb   <V.XON
           stb   DataReg,x      write XON character
ChkHWHS    bita  #FCRxDTR!FCRxRTS Rx disabled due to DTR or RTS?
           beq   RxFloClr       no, go clear Rx flow control flag(s)...
           ldb   CmdReg,x       get current Command register contents
           andb  #^Cmd.TIRB     clear Tx IRQ/RTS/Break control bits
           orb   #TIRB.RTS!Cmd.DTR enable RTS and DTR, disable Tx IRQs
           stb   CmdReg,x       set Command register
RxFloClr   clr   <FloCtlRx      clear Rx flow control flags
ReadChar   ldb   <V.ERR         get accumulated errors, if any
           stb   PD.ERR,y       set/clear error(s) in path descriptor
           bne   ReprtErr       error(s), go report it/them...
           ldd   <RxDatLen      get Rx buffer count
           beq   ReadSlp        none, go sleep while waiting for new Rx data...
           IFNE  H6309
           decd                 less character we're about to grab
           ELSE
           subd  #$0001
           ENDC
           std   <RxDatLen      save new Rx data count
           orcc  #IntMasks  see if this fixes the problem
           ldx   <RxBufGet      current Rx buffer pickup position
           lda   ,x+            get Rx character, set up next pickup position
           cmpx  <RxBufEnd      end of Rx buffer?
           blo   SetPckUp       no, go keep pickup pointer
           ldx   <RxBufPtr      get Rx buffer start address
SetPckUp   stx   <RxBufGet      set new Rx data pickup pointer
           puls  cc,dp,pc       recover IRQ/Carry status, dummy B, system DP, return

ModEntry   lbra  Init
           bra   Read
           nop
           bra   Writ
           nop
           IFNE  H6309
           bra   GStt
           nop
           ELSE
           lbra  GStt
           ENDC
           lbra  SStt
           lbra  Term

PrAbtErr   ldb   #E$PrcAbt
           bra   ErrExit

ReprtErr   clr   <V.ERR         clear error status
           bitb  #DCDLstEr      DCD lost error?
           bne   HngUpErr       yes, go report it...
           ldb   #E$Read
ErrExit    equ  *
           IFNE  H6309
           oim   #Carry,,s      set carry
           ELSE
           lda   ,s
           ora   #Carry
           sta   ,s
           ENDC
           puls  cc,dp,pc       restore dummy A (or Tx character), system DP, return

HngUpErr   ldb   #E$HangUp
           lda   #PST.DCD       DCD lost flag
           sta   PD.PST,y       set path status flag
           bra   ErrExit

NRdyErr    ldb   #E$NotRdy
           bra   ErrExit

UnSvcErr   ldb   #E$UnkSvc
           bra   ErrExit

Writ       clrb                 default to no error...
           pshs  cc,dp          save IRQ/Carry status, Tx character, system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           tfr   a,e
           ELSE
*missing lines
           stu   <regWbuf
           ldb   <regWbuf
           tfr   b,dp
           sta   <regWbuf
           ENDC
           orcc  #IntMasks      disable IRQs during error and Tx disable checks
           bra   WritChr
WritLoop   lda   <WritFlag
           beq   WritFast
           lbsr  Sleep1
WritFast   inc   <WritFlag
WritChr    ldx   <V.PORT
           ldb   <V.ERR         get accumulated errors, if any
           andb  #DCDLstEr      DCD lost error? (ignore other errors, if any)
           stb   PD.ERR,y       set/clear error(s) in path descriptor
           bne   ReprtErr       DCD lost error, go report it...
ChkTxFlo   ldb   <FloCtlTx      get Tx flow control flags
           bitb  #FCTxBrk       currently transmitting line Break?
           bne   WritLoop       yes, go sleep a while...
           lda   <Wrk.Type      get software/hardware handshake enables
           bita  #DSRFlow       DSR/DTR handshake enabled?
* Changed below - BGP
*           beq   ChkTxFlo       no, go check Tx flow control
           beq   ChkRxFlo       no, go check Rx flow control
           ldb   <Cpy.Stat      get copy of status register
           bitb  <Mask.DSR      Tx disabled due to DSR?
           bne   WritLoop       yes, go sleep a while...
           bita  #TxSwFlow      Tx software flow control enabled?
           beq   ChkRxFlo       no, go check pending Rx flow control
           bitb  #FCTxXOff      Tx disabled due to received XOFF?
           bne   WritLoop       yes, go sleep a while...
ChkRxFlo   bita  #RxSwFlow      Rx software flow control enabled?
           beq   ChkTxE         no, go check Tx register empty
           ldb   <FloCtlRx      get Rx flow control flags
           bitb  #FCRxSend      XON/XOFF Rx flow control pending?
           bne   WritLoop       yes, go sleep a while...
ChkTxE     equ   *
           IFNE  H6309
           tim   #Stat.TxE,StatReg,x
           ELSE
           pshs  a
           lda   StatReg,x
           bita  #Stat.TxE
           puls  a 
           ENDC
           beq   WritLoop       no, go sleep a while...
           IFNE  H6309
           ste   DataReg,x      write Tx character
           ELSE
*missing lines
           ldb   <regWbuf
           stb   DataReg,x
           ENDC
           clr   <WritFlag      clear "initial write attempt" flag
           puls  cc,dp,pc       recover IRQ/Carry status, Tx character, system DP, return

GStt       clrb                 default to no error...
           pshs  cc,dp          save IRQ/Carry status, dummy B, system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           ELSE
*missing lines
           stu   <regWbuf
           ldb   <regWbuf
           tfr   b,dp
           ENDC
           ldx   PD.RGS,y       caller's register stack pointer
           cmpa  #SS.EOF
           beq   GSExitOK       yes, SCF devices never return EOF
           cmpa  #SS.Ready
           bne   GetScSiz
           ldd   <RxDatLen      get Rx data length
           beq   NRdyErr        none, go report error
           tsta                 more than 255 bytes?
           beq   SaveLen        no, keep Rx data available
           ldb   #255           yes, just use 255
SaveLen    stb   R$B,x          set Rx data available in caller's [B]
GSExitOK   puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

GetScSiz   cmpa  #SS.ScSiz
           bne   GetComSt
           ldu   PD.DEV,y
           ldu   V$DESC,u
           clra
           ldb   IT.COL,u
           std   R$X,x
           ldb   IT.ROW,u
           std   R$Y,x
           puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

GetComSt   cmpa  #SS.ComSt
           lbne  UnSvcErr       no, go report error
           ldd   <Wrk.Type
           std   R$Y,x
           clra                 default to DCD and DSR enabled
           ldb   <CpyDCDSR
           bitb  #Mask.DCD
           beq   CheckDSR       no, go check DSR status
           ora   #DCDStBit
CheckDSR   bitb  <Mask.DSR      DSR bit set (disabled)?
           beq   SaveCDSt       no, go set DCD/DSR status
           ora   #DSRStBit
SaveCDSt   sta   R$B,x          set 6551 ACIA style DCD/DSR status in caller's [B]
           puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

BreakSlp   ldx   #SlpBreak      SS.Break duration
           bra   TimedSlp

HngUpSlp   ldx   #SlpHngUp      SS.HngUp duration
           bra   TimedSlp

Sleep1     ldx   #1             give up balance of tick
TimedSlp   pshs  cc             save IRQ enable status
           andcc #^Intmasks     enable IRQs
           os9   F$Sleep
           puls  cc,pc          restore IRQ enable status, return

SStt       clrb                 default to no error...
           pshs  cc,dp          save IRQ/Carry status, dummy B, system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           ELSE
*missing lines
           stu   <regWbuf
           ldb   <regWbuf
           tfr   b,dp
           ENDC
           ldx   PD.RGS,y
           cmpa  #SS.HngUp
           bne   SetBreak
           lda   #^Cmd.DTR      cleared (disabled) DTR bit
           ldx   <V.PORT
           orcc  #IntMasks      disable IRQs while setting Command register
           anda  CmdReg,x       mask in current Command register contents
           sta   CmdReg,x       set new Command register
           bsr   HngUpSlp       go sleep for a while...
BreakClr   lda   #^(Cmd.TIRB!Cmd.DTR) clear (disable) DTR and RTS control bits
FRegClr    ldx   <V.PORT
           anda  CmdReg,x       mask in current Command register
           ldb   <FloCtlRx      get Rx flow control flags
           bitb  #FCRxDTR       Rx disabled due to DTR?
           bne   LeaveDTR       yes, go leave DTR disabled
           ora   #Cmd.DTR       set (enable) DTR bit
LeaveDTR   bitb  #FCRxRTS       Rx disabled due to RTS?
           bne   LeaveRTS       yes, go leave RTS disabled
           ora   #TIRB.RTS      enable RTS output
LeaveRTS   ldb   <FloCtlTx      get Tx flow control flags
           bitb  #FCTxBrk       currently transmitting line Break?
           beq   NoTxBrk        no, go leave RTS alone...
           ora   #TIRB.Brk      set Tx Break bits
NoTxBrk    sta   CmdReg,x       set new Command register
           puls  cc,dp,pc       restore IRQ/Carry status, dummy B, system DP, return

SetBreak   cmpa  #SS.Break      Tx line break?
           bne   SetSSig
           ldy   <V.PORT
           ldd   #FCTxBrk*256+TIRB.Brk [A]=flow control flag, [B]=Tx break enable
           orcc  #Intmasks      disable IRQs while messing with flow control flags
           ora   <FloCtlTx      set Tx break flag bit
           sta   <FloCtlTx      save Tx flow control flags
           orb   CmdReg,y       set Tx line break bits
           stb   CmdReg,y       start Tx line break
           bsr   BreakSlp       go sleep for a while...
           anda  #^FCTxBrk      clear Tx break flag bit
           sta   <FloCtlTx      save Tx flow control flags
           clr   CmdReg,y       clear Tx line break
           bra   BreakClr       go restore RTS output to previous...

SetSSig    cmpa  #SS.SSig
           bne   SetRelea
           lda   PD.CPR,y       current process ID
           ldb   R$X+1,x        LSB of [X] is signal code
           orcc  #IntMasks      disable IRQs while checking Rx data length
           ldx   <RxDatLen
           bne   RSendSig
           std   <SSigPID
           puls  cc,dp,pc       restore IRQ/Carry status, dummy B, system DP, return
RSendSig   puls  cc             restore IRQ/Carry status
           os9   F$Send
           puls  dp,pc          restore system DP, return

SetRelea   cmpa  #SS.Relea
           bne   SetCDSig
           leax  SSigPID,u      point to Rx data signal process ID
           bsr   ReleaSig       go release signal...
           puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

SetCDSig   cmpa  #SS.CDSig      set DCD signal?
           bne   SetCDRel
           lda   PD.CPR,y       current process ID
           ldb   R$X+1,x        LSB of [X] is signal code
           std   <CDSigPID
           puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

SetCDRel   cmpa  #SS.CDRel      release DCD signal?
           bne   SetComSt
CDRelSig   leax  CDSigPID,u     point to DCD signal process ID
           bsr   ReleaSig       go release signal...
           puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

SetComSt   cmpa  #SS.ComSt
           bne   SetOpen
           ldd   R$Y,x          caller's [Y] contains ACIAPAK format type/baud info
           bsr   SetPort        go save it and set up control/format registers
ReturnOK   puls  cc,dp,pc       restore Carry status, dummy B, system DP, return

SetOpen    cmpa  #SS.Open
           bne   SetClose
           lda   R$Y+1,x        get LSB of caller's [Y]
           deca                 real SS.Open from SCF? (SCF sets LSB of [Y] = 1)
           bne   ReturnOK       no, go do nothing but return OK...
           lda   #TIRB.RTS      enabled DTR and RTS outputs
           orcc  #IntMasks      disable IRQs while setting Format register
           lbra  FRegClr        go enable DTR and RTS (if not disabled due to Rx flow control)

SetClose   cmpa  #SS.Close
           lbne  UnSvcErr       no, go report error...
           lda   R$Y+1,x        real SS.Close from SCF? (SCF sets LSB of [Y] = 0)
           bne   ReturnOK       no, go do nothing but return OK...
           leax  SSigPID,u      point to Rx data signal process ID
           bsr   ReleaSig       go release signal...
           bra   CDRelSig       go release DCD signal, return from there...

ReleaSig   pshs  cc             save IRQ enable status
           orcc  #IntMasks      disable IRQs while releasing signal
           lda   PD.CPR,y       get current process ID
           suba  ,x             same as signal process ID?
           bne   NoReleas       no, go return...
           sta   ,x             clear this signal's process ID
NoReleas   puls  cc,pc          restore IRQ enable status, return

SetPort    pshs  cc             save IRQ enable and Carry status
           orcc  #IntMasks      disable IRQs while setting up ACIA registers
           std   <Wrk.Type      save type/baud in data area
           leax  BaudTabl,pc
           andb  #BaudRate      clear all but baud rate bits
           ldb   b,x            get baud rate setting
           IFNE  H6309
           tfr   b,e            save it temporarily
           ELSE
*missing line
           stb   <regWbuf
           ENDC
           ldb   <Wrk.Baud      get baud info again
           andb  #^(Ctl.RxCS!Ctl.Baud) clear clock source + baud rate code bits
           IFNE  H6309
           orr   e,b            mask in clock source + baud rate and clean up stack
           ELSE
*missing lines
           pshs  b
           orb   <regWbuf
           stb   <regWbuf
           puls  b
           ENDC
           ldx   <V.PORT        get port address
           anda  #Cmd.Par       clear all except parity bits
           IFNE  H6309
           tfr   a,e            save new command register contents temporarily
           ELSE
*missing line
           sta   <regWbuf
           ENDC
           lda   CmdReg,x       get current command register contents
           anda  #^Cmd.Par      clear parity control bits
           IFNE  H6309
           orr   e,a            mask in new parity
           ELSE
*missing lines
           pshs  a
           ora   <regWbuf
           sta   <regWbuf
           puls  a
           ENDC
           std   CmdReg,x       set command+control registers
           puls  cc,pc          recover IRQ enable and Carry status, return...

IRQSvc     pshs  dp             save system DP
           IFNE  H6309
           tfr   u,w            setup our DP
           tfr   e,dp
           ELSE
*missing lines
           stu   <regWbuf
           ldb   <regWbuf
           tfr   b,dp
           ENDC
           ldx   <V.PORT
           ldb   StatReg,x      get current Status register contents
           stb   <Cpy.Stat      save Status register copy
           bitb  #Stat.Err      error(s)?
           beq   ChkRDRF        no, go check Rx data
           tst   DataReg,x      read Rx data register to clear ACIA error flags
           bitb  #Stat.Frm      framing error (assume Rx line Break)?
           beq   ChkParty       no, go check if parity error...
           lda   <V.QUIT        default to keyboard quit ("Break") code
           bra   RxBreak        go pretend we've received V.QUIT character...

ChkParty   bitb  #Stat.Par      parity error?
           beq   ChkOvRun       no, go check overrun error...
           lda   #ParityEr      mark parity error
ChkOvRun   bita  #Stat.Ovr      overrun error?
           beq   SaveErrs       no, go save errors...
           ora   #OvrFloEr      mark overrun error
SaveErrs   ora   <V.ERR
           sta   <V.ERR
           lbra  ChkTrDCD       go check if DCD transition...

ChkRDRF    bitb  #Stat.RxF      Rx data?
           lbeq  ChkTrDCD       no, go check DCD transition
           lda   DataReg,x      get Rx data
RxBreak    beq   SavRxDat       its a null, go save it...
           IFNE  H6309
           stf   <SigSent       clear signal sent flag
           ELSE
*missing lines
           ldb   <regWbuf+1
           stb   <SigSent
           ENDC
           cmpa  <V.INTR        interrupt?
           bne   Chk.Quit       no, go on...
           ldb   #S$Intrpt
           bra   SendSig

Chk.Quit   cmpa  <V.QUIT        abort?
           bne   Chk.PChr       no, go on...
           ldb   #S$Abort
SendSig    pshs  a              save Rx data
           lda   <V.LPRC        get last process' ID
           os9   F$Send
           puls  a              recover Rx data
           stb   <SigSent       set signal sent flag
           bra   SavRxDat       go save Rx data...

Chk.PChr   cmpa  <V.PCHR        pause?
           bne   Chk.Flow       no, go on...
           ldx   <V.DEV2        attached device defined?
           beq   SavRxDat       no, go save Rx data...
           sta   V.PAUS,x       yes, pause attached device
           bra   SavRxDat       go save Rx data...

Chk.Flow   equ   *
           IFNE  H6309
           tim   #TxSwFlow,<Wrk.Type Tx data software flow control enabled?
           ELSE
           pshs  a
           lda   #TxSwFlow
           bita  <Wrk.Type
           puls  a
           ENDC
           beq   SavRxDat       no, go save Rx data...
           cmpa  <V.XON         XON?
           bne   Chk.XOff       no, go on...
           IFNE  H6309
           aim   #^FCTxXOff,<FloCtlTx clear XOFF received bit
           ELSE
*missing lines
           pshs  a
           lda   #^FCTxXOff
           anda  <FloCtlTx
           sta   <FloCtlTx
           puls  a
           ENDC
           bra   SetTxFlo       go save new Tx flow control flags...

Chk.XOff   cmpa  <V.XOFF        XOFF?
           bne   SavRxDat       no, go save Rx data...
           ldb   #FCTxXOff      set XOFF received bit
           orb   <FloCtlTx      set software Tx flow control flag
SetTxFlo   stb   <FloCtlTx      save new Tx flow control flags
           lbra  ChkTrDCD       go check DCD transition...
SavRxDat   equ   *
           IFNE  H6309
           aim   #^FCRxSend,<FloCtlRx clear possible pending XOFF flag
           ELSE
*missing lines
           pshs  a
           lda   #^FCRxSend
           anda  <FloCtlRx
           sta   <FloCtlRx
           puls  a 
           ENDC
           ldx   <RxBufPut      get Rx buffer input pointer
           IFNE  H6309
           ldw   <RxDatLen      Rx get Rx buffer data length
           cmpw  <RxBufSiz      Rx buffer already full?
           ELSE
*missing lines
           pshs  d
           ldd   <RxDatLen
           std   <regWbuf
           cmpd  <RxBufSiz
           puls  d
           ENDC
           blo   NotOvFlo       no, go skip overflow error...
           IFNE  H6309
           oim   #OvrFloEr,<V.ERR mark RX buffer overflow error
           ELSE
*missing lines
           ldb   #OvrFloEr
           orb   <V.ERR
           stb   <V.ERR
           ENDC
           bra   DisRxFlo       go ensure Rx is disabled (if possible)

NotOvFlo   sta   ,x+            save Rx data
           cmpx  <RxBufEnd      end of Rx buffer?
           blo   SetLayDn       no, go keep laydown pointer
           ldx   <RxBufPtr      get Rx buffer start address
SetLayDn   stx   <RxBufPut      set new Rx data laydown pointer
           IFNE  H6309
           incw                 one more byte in Rx buffer
           stw   <RxDatLen      save new Rx data length
           cmpw  <RxBufMax      at or past maximum fill point?
           ELSE
*missing lines
           pshs  d
           ldd   <regWbuf
           addd  #1
           std   <regWbuf
           std   <RxDatLen
           cmpd  <RxBufMax
           puls  d
           ENDC
           blo   SgnlRxD        no, go check Rx data signal...
DisRxFlo   ldx   <V.PORT
           ldb   CmdReg,x       get current Command register contents
           IFNE  H6309
           tim   #ForceDTR,<Wrk.XTyp forced DTR?
           ELSE
*missing lines
           lda   #ForceDTR
           bita  <Wrk.XTyp
           ENDC
           bne   DisRxRTS       yes, go check RTS disable...
           IFNE  H6309
           tim   #DSRFlow,<Wrk.Type DSR/DTR Flow control?
           ELSE
*missing lines
           lda   #DSRFlow
           bita  <Wrk.Type
           ENDC
           beq   DisRxRTS       no, go check RTS disable
           IFNE  H6309
           oim   #FCRxDTR,<Wrk.Type mark RX disabled due to DTR
           ELSE
*missing lines
           lda   #FCRxDTR
           ora   <Wrk.Type
           sta   <Wrk.Type
           ENDC
           andb  #^Cmd.DTR      clear (disable) DTR bit
DisRxRTS   equ   *
           IFNE  H6309
           tim   #RTSFlow,<Wrk.Type
           ELSE
*missing lines
           lda   #RTSFlow
           bita  <Wrk.Type
           ENDC
           beq   NewRxFlo       no, go set new Rx flow control...
           IFNE  H6309
           tim   #DSRFlow,<Wrk.Type line break?
           ELSE
*missing lines
           lda   #DSRFlow
           bita  <Wrk.Type
           ENDC
           bne   NewRxFlo       yes, go set new Rx flow control...
           IFNE  H6309
           oim   #FCRxRTS,<FloCtlRx
           ELSE
*missing lines
           lda   #FCRxRTS
           ora   <FloCtlRx
           sta   <FloCtlRx
           ENDC
           andb  #^Cmd.TIRB     clear Tx IRQ/RTS/Break control bits (disable RTS)
NewRxFlo   stb   CmdReg,x       set/clear DTR and RTS in Command register
           IFNE  H6309
           tim   #RxSwFlow,<Wrk.Type Rx software flow control?
           ELSE
           ldb   <Wrk.Type
           bitb  #RxSwFlow
           ENDC
           beq   SgnlRxD        no, go check Rx data signal...
           lda   <V.XOFF        XOFF character defined?
           beq   SgnlRxD        no, go check Rx data signal...
           ldb   <FloCtlRx      get Rx flow control flags
           bitb  #FCRxSent      XOFF already sent?
           bne   SgnlRxD        yes, go check Rx data signal...
           orb   #FCRxSend      set send XOFF flag
           stb   <FloCtlRx      set new Rx flow control flags
           IFNE  H6309
           tim   #Stat.TxE,StatReg,x
           ELSE
           ldb   StatReg,x
           bitb  #Stat.TxE
           ENDC
           beq   SgnlRxD        no, go skip XOFF this time...
           sta   DataReg,x      write XOFF character
           ldb   #FCRxSent      set XOFF sent flag
           orb   <FloCtlRx      mask in current Rx flow control flags
           andb  #^FCRxSend     clear send XOFF flag
           stb   <FloCtlRx      save new flow control flags
SgnlRxD    ldb   <SigSent       already sent abort/interrupt signal?
           bne   ChkTrDCD       yes, go check DCD transition...
           lda   <SSigPID       Rx data signal process ID?
           beq   ChkTrDCD       none, go check DCD transition...
           stb   <SSigPID       clear Rx data signal
           ldb   <SSigSig       Rx data signal code
           os9   F$Send
ChkTrDCD   ldx   <V.PORT
           lda   <Cpy.Stat      get Status register copy
           tfr   a,b            copy it...
           eora  <CpyDCDSR      mark changes from old DSR+DCD status copy
           andb  #Stat.DSR!Stat.DCD clear all but DSR+DCD status
           stb   <CpyDCDSR      save new DSR+DCD status copy
           bita  <Mask.DCD      DCD transition?
           beq   CkSuspnd       no, go check for suspended process...
           bitb  <Mask.DCD      DCD disabled now?
           beq   SgnlDCD        no, go check DCD signal...
           lda   <Wrk.Type
           bita  #MdmKill       modem kill enabled?
           beq   SgnlDCD        no, go on...
           ldx   <V.PDLHd       path descriptor list header
           beq   StCDLost       no list, go set DCD lost error...
           lda   #PST.DCD       DCD lost flag
PDListLp   sta   PD.PST,x       set path status flag
           ldx   PD.PLP,x       get next path descriptor in list
           bne   PDListLp       not end of list, go do another...
StCDLost   lda   #DCDLstEr      DCD lost error flag
           ora   <V.ERR
           sta   <V.ERR
SgnlDCD    lda   <CDSigPID      get process ID, send a DCD signal?
           beq   CkSuspnd       no, go check for suspended process...
           ldb   <CDSigSig      get DCD signal code
           clr   <CDSigPID      clear DCD signal
           os9   F$Send

CkSuspnd   clrb                 clear Carry (for exit) and LSB of process descriptor address
           lda   <V.WAKE        anybody waiting? ([D]=process descriptor address)
           beq   IRQExit        no, go return...
           stb   <V.WAKE        mark I/O done
           tfr   d,x            copy process descriptor pointer
           lda   P$State,x      get state flags
           anda  #^Suspend      clear suspend state
           sta   P$State,x      save state flags
IRQExit    puls  dp,pc          recover system DP, return...

           emod
ModSize    equ   *
           end

