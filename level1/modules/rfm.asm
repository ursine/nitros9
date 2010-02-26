********************************************************************
* RFM - Remote File Manager
*
*
*  1       2010/02/20  AAW
*          first version - just send ops

         nam   RFM
         ttl   Remote File Manager

         IFP1
         use   defsfile
         use   rfmdefs
         use   dwdefs.d
         ENDC

tylg     set   FlMgr+Objct
atrv     set   ReEnt+rev
rev      set   0
edition  equ   1

         mod   eom,RFMName,tylg,atrv,RFMEnt,size

      
size     equ   .


RFMName  fcs   /RFM/
         fcb   edition



******************************
*
* file manager entry point
*
* Entry: Y = Path descriptor pointer
*        U = Callers register stack pointer
*

RFMEnt   lbra  create         Create path
         lbra  open         Open path
         lbra  makdir        Makdir
         lbra  chgdir        Chgdir
         lbra  delete        Delete 
         lbra  seek        Seek
         lbra  read         Read character 
         lbra  write        Write character
         lbra  readln       ReadLn
         lbra  writln       WriteLn
         lbra  getstt       Get Status
         lbra  setstt       Set Status
         lbra  close        Close path

create	ldb		#DW.create
		bra		create1

		
open	ldb		#DW.open
create1	pshs	u,y         ; RD Regs

		ldx		PD.DEV,y	; to our static storage
		pshs	x			; PD.DEV PD Regs
		
		* put path # on stack
		lda		,y
		sta		V.PATHNUM,x
		pshs	a			; p# PD.DEV PD Regs
		
		* put rfm op and DW op on stack
		
		lda		#OP_VFM
		pshs	d			; DWOP RFMOP p# PD.DEV PD Regs
		
		* TODO lets not create multiple buffers when multiple open/create on same path
     	* get system mem
     	ldd		#256
       	os9		F$SRqMem	; ask for D bytes (# bytes server said is coming)
       	ldx		3,s			; PD.DEV
       	stu		V.BUF,x		
       	
		leax      ,s                  ; point X to stack 
        ldy       #3                  ; 3 bytes to send
        
        ifgt      Level-1
        ldu       <D.DWSubAddr
        else      
        ldu       >D.DWSubAddr
        endc      
         
        jsr		6,u
        leas	3,s		;clean stack   PD.DEV PD Regs
       
        * now send path string
        
        * copy path string 

        leas	-1,s		; use stack for counter    0 PD.DEV PD Regs
        clr		,s		; set size ctr to 0
        
		
       	ldx   <D.Proc   	get curr proc desc
        ldb   P$Task,x  	get task #
       
        ldx		5,s		; original U - Regs
        ldx		R$X,x	; should be X from caller
        
        ldy		1,s		; pd.dev
       	ldy		V.BUF,y	
       	
open1  	os9		f$ldabx
		sta		,y+
        leax	1,x
        inc		,s
        cmpa	#$0D
        bne		open1
        
        * store advanced X in calling process (SCF does this.. ?)
        leax	-1,x
        ldy		5,s	; original U
        stx		R$X,y
                
        * send to server
        clra 
        ldb		,s		; counter	
        tfr		d,y		; set Y to pathlen
        ldx		1,s		; pd.dev
        ldx		V.BUF,x
        jsr		6,u
        
		* read response from server -> B
		leax	,s
        ldy		#1
        jsr		3,u
        
		* pull server's response into B
        puls 	b		; PD.DEV PD Regs
        tstb
        beq		open2
        
        orcc	#1			;set error
open2	leas	4,s		; Regs
		puls	u		; clean stack
		rts

makdir	lda		#DW.makdir
		lbra	sendit
chgdir	lda		#DW.chgdir
		lbra	sendit
delete	lda		#DW.delete
		lbra	sendit
seek	lda		#DW.seek
		lbra	sendit
		
read	ldb		#DW.read
		bra		read1		; join readln routine
		
		
		
write	lda		#DW.write
		lbra	sendit
		
		
	
readln	ldb		#DW.readln
read1	pshs	y,u
		
		ldx		PD.DEV,y	; to our static storage
		pshs	x			; PD.DEV PD Regs
		
		* put path # on stack
		lda		,y
		sta		V.PATHNUM,x
		pshs	a			; p# PD.DEV PD Regs
		
		* put rfm op and DW op on stack
		
		lda		#OP_VFM
		pshs	d			; DWOP RFMOP p# PD.DEV PD Regs
		
		leax      ,s                  ; point X to stack 
        ldy       #3                  ; 3 bytes to send
        
        * set U to dwsub
        ifgt      Level-1
        ldu       <D.DWSubAddr
        else      
        ldu       >D.DWSubAddr
        endc      
         
        * send dw op, rfm op, path #
        jsr		6,u
        leas	3,s		;clean stack - PD.DEV PD Regs
       
        * put caller's Y on stack (maximum allowed bytes)
        ldx		4,s
        ldx		R$Y,x
        pshs	x
        
        * send 2 bytes from stack
        leax	,s
        ldy		#2
        jsr		6,u
        
        leas 1,s    ; leave 1 byte for server response in next section
        
        * read # bytes coming (0 = eof) from server
        leax	,s
        ldy		#1
        jsr		3,u
        
        * store size
        clra
        puls	b		;PD.DEV PD Regs
       
        
        * check for 0
        tstb
        beq		readln1		; 0 bytes = EOF
        
       	* read the data from server if > 0
        pshs	d		;xfersz PD.DEV PD Regs
              	
       	* load data from server into mem block
       	ldx		2,s		; pd.dev
       	ldx		V.BUF,x	
       	ldy		,s		;xfersz
       	jsr		3,u
       	
       	* F$Move
       	* a = my task #
       	* b = caller's task #
       	* X = source ptr
       	* Y = byte count
       	* U = dest ptr
       	
       	* move from our mem to caller
       	
       	puls	y		;Y = byte count (already set?)    -  PD.DEV PD Regs
       	
       	ldx		4,s
       	ldu		R$X,x	; U = caller's X = dest ptr
       
	   	lda		<D.SysTsk ; A = system task # 
       
       	ldx   <D.Proc   	get calling proc desc
        ldb   P$Task,x  	; B = callers task #
       	       	
       	puls	x			; pd.dev     - PD Regs
       	ldx		V.BUF,x
       	
       *  F$Move the bytes (seems to work)
       os9	F$Move
       	
		* assume everything worked (not good)
		clrb
		*ldy		xfersz,pc	; Y is supposed to be set to bytes read.. do we need to set this in the caller's regs?
		bra		readln2
       	
readln1	ldb		#E$EOF
		ldy		#0			; Y should be 0 if we didnt read any?  in callers regs?
		orcc	#1			; set error bit
		leas	2,s			; clean stack down 
		
readln2	puls	y,u
		rts

*ldu		origu,pc	; put U back to the entry value.. needed?
*		rts

        
writln	lda		#DW.writln
		lbra	sendit
getstt	lda		#DW.getstt
		lbra	sendit
setstt	lda		#DW.setstt
		lbra	sendit
		
close	pshs u,y
				
		* put path # on stack
		lda		,y
		pshs	a
		
		* put rfm op and DW op on stack
		ldb		#DW.close
		lda		#OP_VFM
		pshs	d
		
		leax      ,s                  ; point X to stack 
        ldy       #3                  ; 3 bytes to send
        ifgt      Level-1
        ldu       <D.DWSubAddr
        else      
        ldu       >D.DWSubAddr
        endc      
         
        jsr		6,u
        leas	2,s		;clean stack (leave 1 byte)
		
        * read server response
        leax	,s
        ldy		#1
        jsr		3,u
        
        * free system mem
        ldd		#256
        ldx		1,s		; orig Y
        ldx		PD.DEV,x
        ldu		V.BUF,x
        os9		F$SRtMem
        
        ldb		,s ; server sends result code
        beq		close1
        orcc	#1	; set error flag if != 0
close1	leas	1,s
		puls	u,y
		rts
		
		
* just send OP_VMF + vfmop
sendit	 pshs	a
		
        lda       #OP_VFM          ; load command
        pshs      a                ; command store on stack
        leax      ,s                  ; point X to stack 
        ldy       #2                  ; 2 byte to send
         ifgt      Level-1
         ldu       <D.DWSubAddr
         else      
         ldu       >D.DWSubAddr
         endc      
         
         jsr	6,u
         leas	2,s		;clean stack
         
		clrb
		rts

		
         emod
eom      equ   *
         end

