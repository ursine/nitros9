********************************************************************
* Free - Print disk free space
*
* $Id$
*
* Ed.    Comments                                       Who YY/MM/DD
* ------------------------------------------------------------------
* 6      Original Tandy/Microware version
* 7      Incorporated Glenside Y2K fixes                BGP 99/05/11

         nam   Free
         ttl   Print disk free space

* Disassembled 98/09/11 16:58:25 by Disasm v1.6 (C) 1988 by RML

         ifp1
         use   defsfile
         endc

tylg     set   Prgrm+Objct   
atrv     set   ReEnt+rev
rev      set   $00
edition  set   7

         mod   eom,name,tylg,atrv,start,size

u0000    rmb   1
u0001    rmb   1
u0002    rmb   1
u0003    rmb   1
u0004    rmb   1
u0005    rmb   2
u0007    rmb   1
u0008    rmb   1
u0009    rmb   1
u000A    rmb   1
u000B    rmb   1
u000C    rmb   1
u000D    rmb   26
u0027    rmb   54
u005D    rmb   4
u0061    rmb   2
u0063    rmb   1
u0064    rmb   19
u0077    rmb   5
u007C    rmb   26
u0096    rmb   6
u009C    rmb   2
u009E    rmb   2
u00A0    rmb   4544
size     equ   .

name     fcs   /Free/
         fcb   edition
L0012    fcb   C$LF
         fcc   "Use: free [/diskname]"
         fcb   C$LF
         fcc   "  tells how many disk sectors are unused"
         fcb   C$CR
L0052    fcs   /" created on:/
L005F    fcs   "Capacity:"
L0068    fcs   " sectors ("
L0072    fcs   "-sector clusters)"
L0083    fcs   " free sectors, largest block"
L009F    fcs   " sectors"

start    leay  u000D,u
         sty   <u0001
         cmpd  #$0000
         beq   L00E0
         lda   ,x+
         cmpa  #C$CR
         beq   L00E0
         cmpa  #PDELIM
         beq   L00CC
L00BC    leax  >L0012,pcr
         ldy   #$0040
         lda   #$02
         os9   I$WritLn 
         lbra  L01CC
L00CC    leax  -$01,x
         pshs  x
         os9   F$PrsNam 
         puls  x
         bcs   L00BC
L00D7    lda   ,x+
         lbsr  L0218
         subb  #$01
         bcc   L00D7
L00E0    lda   #$40
         lbsr  L0218
         lbsr  L0216
         leax  u000D,u
         stx   <u0001
         lda   #READ.
         os9   I$Open   
         sta   <u0003
         bcs   L00FF
         leax  <u005D,u
         ldy   #$003F
         os9   I$Read   
L00FF    lbcs  L01CD
         lbsr  L0222
         lda   #$22
         lbsr  L0218
         leay  <u007C,u
         lbsr  L020C
         dec   <u0002
         leay  >L0052,pcr
         lbsr  L020C
         lbsr  L0293
         lbsr  L0222
         leay  >L005F,pcr
         lbsr  L020C
         leax  <u005D,u
         lbsr  L024F
         leay  >L0068,pcr
         lbsr  L020C
         dec   <u0002
         ldd   <u0063
         pshs  b,a
         clr   ,-s
         leax  ,s
         lbsr  L024F
         leas  $03,s
         leay  >L0072,pcr
         lbsr  L020C
         lbsr  L0222
         clra  
         clrb  
         sta   <u0004
         std   <u0005
         sta   <u000A
         std   <u000B
         sta   <u0007
         std   <u0008
         lda   <u0003
         ldx   #$0000
         pshs  u
         ldu   #$0100
         os9   I$Seek   
         puls  u
L016A    leax  >u009E,u
         ldd   #$1000
         cmpd  <u0061
         bls   L0178
         ldd   <u0061
L0178    leay  d,x
         sty   <u009C
         tfr   d,y
         lda   <u0003
         os9   I$Read   
         bcs   L01CD
L0186    lda   ,x+
         bsr   L01D0
         stb   ,-s
         beq   L019C
L018E    ldd   <u0005
         addd  <u0063
         std   <u0005
         bcc   L0198
         inc   <u0004
L0198    dec   ,s
         bne   L018E
L019C    leas  $01,s
         cmpx  <u009C
         bcs   L0186
         ldd   <u0061
         subd  #$1000
         std   <u0061
         bhi   L016A
         bsr   L01ED
         leax  u0004,u
         lbsr  L024F
         leay  >L0083,pcr
         bsr   L020C
         leax  u0007,u
         lbsr  L024F
         leay  >L009F,pcr
         bsr   L020C
         bsr   L0222
         lda   <u0003
         os9   I$Close  
         bcs   L01CD
L01CC    clrb  
L01CD    os9   F$Exit   
L01D0    clrb  
         cmpa  #$FF
         beq   L01ED
         bsr   L01D7
L01D7    bsr   L01D9
L01D9    bsr   L01DB
L01DB    lsla  
         bcs   L01ED
         incb  
         pshs  b,a
         ldd   <u000B
         addd  <u0063
         std   <u000B
         bcc   L01EB
         inc   <u000A
L01EB    puls  pc,b,a
L01ED    pshs  b,a
         ldd   <u000A
         cmpd  <u0007
         bhi   L01FE
         bne   L0204
         ldb   <u000C
         cmpb  <u0009
         bls   L0204
L01FE    sta   <u0007
         ldd   <u000B
         std   <u0008
L0204    clr   <u000A
         clr   <u000B
         clr   <u000C
         puls  pc,b,a
L020C    lda   ,y
         anda  #$7F
         bsr   L0218
         lda   ,y+
         bpl   L020C
L0216    lda   #$20
L0218    pshs  x
         ldx   <u0001
         sta   ,x+
         stx   <u0001
         puls  pc,x
L0222    pshs  y,x,a
         lda   #$0D
         bsr   L0218
         leax  u000D,u
         stx   <u0001
         ldy   #$0050
         lda   #$01
         os9   I$WritLn 
         puls  pc,y,x,a
L0237    fcb   $98
         fdb   $9680,$0f42,$4001,$86a0,$0027,$1000,$03e8,$0000
         fdb   $6400,$000a,$0000
         fcb   $01
L024F    lda   #$0A
         pshs  y,x,b,a
         leay  <L0237,pcr
         clr   <u0000
         ldb   ,x
         ldx   $01,x
L025C    lda   #$FF
L025E    inca  
         exg   d,x
         subd  $01,y
         exg   d,x
         sbcb  ,y
         bcc   L025E
         bsr   L02B9
         exg   d,x
         addd  $01,y
         exg   d,x
         adcb  ,y
         leay  $03,y
         dec   ,s
         beq   L0291
         lda   ,s
         cmpa  #$01
         bne   L0281
         sta   <u0000
L0281    bita  #$03
         bne   L025C
         dec   ,s
         tst   <u0000
         beq   L025C
         lda   #$2C
         bsr   L0218
         bra   L025C
L0291    puls  pc,y,x,b,a
L0293    leax  <u0077,u
         bsr   L02C3
         bsr   L029A
L029A    lda   #$2F
         lbsr  L0218
         clr   <u0000
         ldb   ,x+
         lda   #$FF
L02A5    inca  
         subb  #$64
         bcc   L02A5
         bsr   L02B9
L02AC    lda   #$0A
         sta   <u0000
L02B0    deca  
         addb  #$0A
         bcc   L02B0
         bsr   L02B9
         tfr   b,a
L02B9    tsta  
         beq   L02BE
         sta   <u0000
L02BE    tst   <u0000
         bne   L02D6
         rts   
L02C3    ldb   ,x+
         lda   #$AE
L02C7    inca
         subb  #$64
         bcc   L02C7
         pshs  b
         tfr   a,b
         bsr   L02AC
         puls  b
         bra   L02AC
L02D6    adda  #$30
         lbra  L0218 

         emod
eom      equ   *
         end