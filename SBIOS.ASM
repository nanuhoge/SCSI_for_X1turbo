;------------------------------------------------------------------
;
; X1turbo SCSI BIOS
;
;  CPU/DMA 4MHz(6MHz)
;  SPC     8MHz(min.5MHz max.8MHz)
;

;------------------------------------------------------------------
; FDC �X�e�b�v���[�g�̕ύX
;------------------------------------------------------------------
FDCSTEP	EQU	1		;0=�W��(20ms) 1=�ō���(6ms)

;------------------------------------------------------------------
; EMM/ROMDISK�֘A
;------------------------------------------------------------------
EMMX	EQU	1		;EMM�e�ʊg�� 0=���� 1=�L��
NUMROMD	EQU	9		;ROM Disk �ɗp����EMM�h���C�u�ԍ�

;------------------------------------------------------------------
; NMI�֘A
;------------------------------------------------------------------
UXNMI	EQU	1		;NMI�ė��p 0=���Ȃ� 1=����

;------------------------------------------------------------------
; �@��ŗL�l
;------------------------------------------------------------------
SCSI_ID	EQU	7		;�{�@�� SCSI ID �����l
SENSLEN	EQU	18		;���N�G�X�g�Z���X�̎�M�f�[�^�T�C�Y
MAXTRY	EQU	5		;���s��

;------------------------------------------------------------------
; I/O
;------------------------------------------------------------------
SPCBASE	EQU	0F70H		;MB89352(A) Base address
BDID	EQU	SPCBASE+00H	;Bus Device ID
SCTL	EQU	SPCBASE+01H	;SPC Control
SCMD	EQU	SPCBASE+02H	;Command
;TMOD	EQU	SPCBASE+03H	;(Transfer Mode)
INTS	EQU	SPCBASE+04H	;Interrupt Sense
PSNS	EQU	SPCBASE+05H	;Phase Sense
SDGC	EQU	SPCBASE+05H	;SPC Diagnostic Control
SSTS	EQU	SPCBASE+06H	;SPC Status
SERR	EQU	SPCBASE+07H	;SPC Error Status
PCTL	EQU	SPCBASE+08H	;Phase Control
MBC	EQU	SPCBASE+09H	;Modified Byte Register
DREG	EQU	SPCBASE+0AH	;Data Register
TEMP	EQU	SPCBASE+0BH	;Temporary Register
TCH	EQU	SPCBASE+0CH	;Transfer Counter High
TCM	EQU	SPCBASE+0DH	;Transfer Counter Mid
TCL	EQU	SPCBASE+0EH	;Transfer Counter Low
;EXBF	EQU	SPCBASE+0FH	;(External Buffer)

DMAIO	EQU	1F80H		;1F8XH DMA I/O address

;------------------------------------------------------------------
; SPC Phase data
;------------------------------------------------------------------
P_DOUT	EQU	000B		;Data Out
P_DINP	EQU	001B		;Data In
P_CMD	EQU	010B		;Command
P_STAT	EQU	011B		;Status
;	EQU	100B		;
;	EQU	101B		;
P_MSGO	EQU	110B		;Message Out
P_MSGI	EQU	111B		;Message In

;------------------------------------------------------------------
; BIOS ROM
;------------------------------------------------------------------
IPLPAT	EQU	0FA7H		;IPL�������p�b�`�p����
MONST	EQU	33C5H		;�}�V���ꃂ�j�^�̋N��

DEVIOE	EQU	1000H		;Device I/O ERROR
DEVWPE	EQU	1003H		;Write protected
DEVOFE	EQU	1006H		;Device offline

W500MS	EQU	77A7H		;500ms �҂�(����:�Ȃ� �o��:A=0,BC=0)
W1MS	EQU	77C6H		;1ms �҂�(����:�Ȃ� �o��:A=0)
;------------------------------------------------------------------
HDINIT	EQU	78D9H		;HDD������BIOS�G���g��
HDOFFS	EQU	78E2H		;HDOFF�R�}���hBIOS�G���g��

HFDCRED	EQU	7906H		;HD�p FCDRED�̔���J�G���g��
HFDCWRT	EQU	7928H		;HD�p FCDWRT�̔���J�G���g��

;------------------------------------------------------------------
; BIOS WORK
;------------------------------------------------------------------
DMAIOF	EQU	0FAB9H		;�]���Ώ� 00H=���C�������� 08H=I/O������(VRAM)
UNITNO	EQU	0FADEH		;�h���C�u�ԍ� 0�`F (HD4�`9�̎g�p��BASIC�v�����BA�`F��BASIC��Ή�)

LUNMOD	EQU	0FDAFH		;����LUN���[�h 0:SASI���ۂ����(�W�� ID0=HD0,HD1 ID1=HD2,HD3) 2:4in1(ID0=HD0�`3) 3:ID?=HD?(ID0=HD0 ID1=HD1 ...)
DMAXMD	EQU	0FDB0H		;DMA�]�����[�h 00H:Byte(�W��) 20H:Continuous(�댯) 40H:Burst(�댯)

CMDTBL	EQU	0FDB1H		;CDB Operation code
HDDRV	EQU	0FDB2H		;LUN(3) | LBA High(5)
HDREC	EQU	0FDB3H		;LBA Mid(8) / Low(8)
HDLEN	EQU	0FDB5H		;Transfer length(16)
CTLBYT	EQU	0FDB6H		;Control(8)

HDSPCB	EQU	0FDB7H		;��r�I���R�Ɏg���Ă������炵�����[�N�̐擪(�ŏ�10�o�C�g�A�ő�26�o�C�g�H)

;------------------------------------------------------------------
	.Z80
	ASEG

;------------------------------------------------------------------
; SPC�������̃t�b�N
;------------------------------------------------------------------
	ORG	0018H
	JP	IPLSPC

if UXNMI
;------------------------------------------------------------------
; NMI�̍ė��p
;------------------------------------------------------------------
	ORG	0066H+1
	DW	0F800H			;SIO Ch.B ���荞�݃x�N�^�̃A�h���X

	ORG	7D9CH			;F800H�` �ɓ]�������
	JP	0006H			;�I���W�i��������
endif ;UXNMI

if FDCSTEP
;------------------------------------------------------------------
; FDC �ւ̃X�e�b�v���[�g�p�����[�^���ő��ݒ�
;------------------------------------------------------------------
	ORG	030DH			;IPL 5" 2D
	DB	00H			;Restore 20ms �� 6ms

	ORG	031FH			;IPL 5" 2D
	DB	1CH			;Seek 20ms �� 6ms

	ORG	762BH			;BIOS 5" FM 2D 160KB
	DB	1CH			;Seek 20ms �� 6ms

	ORG	7631H			;BIOS 5" MFM 2D 320KB
	DB	1CH			;Seek 20ms �� 6ms

	ORG	7857H			;BIOS 5" 8"���p
	DB	00H			;Restore 20ms �� 6ms
endif ;FDCSTEP

;------------------------------------------------------------------
; IPL���j���[�� '5"HD' �� 'SCSI' �ɕύX
;------------------------------------------------------------------
	ORG	0E50H
	DB	'SCSI'			;'5"HD' �� 'SCSI'
	ORG	0E56H
	DB	'6'			;'10M' �� '16M'

;------------------------------------------------------------------
; IPL���j���[ "M" �̏����ւ̑Ή�
;------------------------------------------------------------------
;;;	ORG	0FD3H
;;;	DW	MONST			;�}�V���ꃂ�j�^��

;------------------------------------------------------------------
; IPL���j���[ "M" �̃������N���A������ׂ������
;------------------------------------------------------------------
	ORG	72D5H
	JP	MONST			;�}�V���ꃂ�j�^��

if EMMX
;------------------------------------------------------------------
; EMM���݊m�F�����Ƀp�b�`���s���A
; ROM DISK �h���C�u�w�莞�ɏ������݉ۂ��X�L�b�v����p�b�`
;------------------------------------------------------------------
P_EMM:
	RLCA
	RLCA
	LD	C,A
	CP	NUMROMD SHL 2		;ROM Disk �̔ԍ����H
	RET	NZ			;ROM Disk �łȂ���Βʏ폈�����p��
	POP	AF
	JP	74A8H			;���݊m�F�������X�L�b�v
endif ;EMMX

hoge	set	72F5H-$


if EMMX
;------------------------------------------------------------------
; EMM �̍ő僌�R�[�h�ԍ��`�F�b�N�������Ԃ��p�b�`
;------------------------------------------------------------------
	ORG	74ADH
	JP	74B7H

;------------------------------------------------------------------
; EMM �̑��݃`�F�b�N(�������݉�)�ւ̃p�b�`
;------------------------------------------------------------------
	ORG	7482H
	CALL	P_EMM			;RLCA / RLCA / LD C,A
endif ;EMMX


;------------------------------------------------------------------
; IPL��HD�u�[�g�������珉�����������O��
;------------------------------------------------------------------
;;;	ORG	737DH
;;;	DB	11H			;CALL HDINIT

;------------------------------------------------------------------
; BIOS FDCRED/FDCWRT/FDCVFY
; HD Read/Write/Verify
;------------------------------------------------------------------
;	ORG	73A8H
;	DW	__S_READ
;	.assert	__S_READ == HFDCRED

;	ORG	73B5H
;	DW	__S_WRITE
;	.assert	__S_WRITE == HFDCWRT

;	ORG	73C2H
;	DW	__S_VERIFY

;------------------------------------------------------------------
; �������� SASI �������(�ꕔ�AFDC�����Ƌ��p�ɗ���)
;------------------------------------------------------------------
	ORG	78C1H

;------------------------------------------------------------------
; IPL�ł�SPC������
;------------------------------------------------------------------
IPLSPC:
	CALL	S_INIT			;SPC���������o�X���Z�b�g
	JP	IPLPAT			;���X�̏����ֈڍs

;------------------------------------------------------------------
; REQ�҂�
;
; ����	D = ���s�\��t�F�[�Y
; �o��	�L�����[�t���O(�t�F�[�X�̕s��v)
;	A = 0(����I����)
;	B = High SPCBASE
; �j��	AF,BC
;------------------------------------------------------------------
REQWA:
	LD	BC,PSNS
REQWA1:
	IN	A,(C)
	JP	P,REQWA1		;REQ�܂�
	
	AND	111B			;MSG, C/D, I/O ���c��
	XOR	D			;�t�F�[�Y�̔���
	JR	NZ,_POPCRET		;���s�\��t�F�[�Y�ƈقȂ�
	
	LD	C,LOW PCTL
	OUT	(C),D			;���s�t�F�[�Y��ݒ�
	
	RET

;------------------------------------------------------------------
; HDINIT(HD�u�[�g���̂݌Ă΂��H)
;
; ����	�Ȃ�(����)
; �o��	�L�����[�t���O�����Z�b�g
; �j��	AF
;------------------------------------------------------------------
__HDINIT:
	.assert	$ == HDINIT
	XOR	A
	RET

;------------------------------------------------------------------
; SPC���������o�X���Z�b�g
;
; ����	�Ȃ�
; �o��	�Ȃ�
; �j��	AF,BC,D,HL
;------------------------------------------------------------------
S_INIT:
	LD	BC,SCTL
	LD	A,10010000B		;SPC Reset & Disable, Arbitration Enable
	JR	_S_INIT

;------------------------------------------------------------------
; HDOFFS(HuBASIC,turbo CP/M �̃R�}���h����Ă΂��)
;
; ����	�Ȃ�(����)
; �o��	�L�����[�t���O�����Z�b�g
; �j��	AF
;------------------------------------------------------------------
__HDOFFS:
	.assert	$ == HDOFFS
	XOR	A
	RET

;------------------------------------------------------------------
; SPC�������̂Â�
;------------------------------------------------------------------
_S_INIT:
	OUT	(C),A
	DEC	C			;BC = BDID
	LD	A,SCSI_ID		;SCSI ID �Ƃ���l���Z�b�g
	OUT	(C),A			;SPC �ɖ{�@�� SCSI ID ��ݒ�
	
	XOR	A
	LD	HL,IRLST
	LD	D,IRCNT
IRSET:	LD	C,(HL)
	OUT	(C),A
	INC	HL
	DEC	D
	JR	NZ,IRSET
	
	LD	C,(HL)			;BC = SCTL
	LD	A,00010000B		;SPC Enable, Arbitration Enable
	OUT	(C),A
;------------------------------------------------------------------
; SCSI�o�X���Z�b�g
;
; ����	�Ȃ�
; �o��	�Ȃ�
; �j��	AF,BC,D
;------------------------------------------------------------------
S_RESET:
	LD	D,00010000B		;RST Out
	CALL	SETSCMD
	JR	_NEGRST


	DS	2

;------------------------------------------------------------------
; BIOS FDCRED
;
; ����	A' = �]�����R�[�h��
;	DE = �J�n���R�[�h�ԍ�
;	HL = �o�b�t�@�A�h���X
;------------------------------------------------------------------
__S_READ:
	.assert	$ == HFDCRED
	LD	A,08H			;SCSI READ(6)
	CALL	RWINIT			;�����ݒ�
SRDLOOP:
	CALL	SELCMD			;�Z���N�V�������R�}���h
	CALL	NC,S_DATAIN		;�f�[�^�C��
	CALL	GETSTMS			;�X�e�[�^�X�����b�Z�[�W
	JP	NZ,SRDLOOP		;���R�[�h�����̏������J��Ԃ�
	RET

;------------------------------------------------------------------
; SPC���������W�X�^���X�g
;------------------------------------------------------------------
IRLST:
	DB	LOW SCMD
	DB	LOW SDGC
	DB	LOW PCTL
	DB	LOW TEMP
	DB	LOW TCH
	DB	LOW TCM
	DB	LOW TCL
IRCNT	EQU	$-IRLST
	DB	LOW SCTL

;------------------------------------------------------------------
; �^�C���A�E�g�p�J�E���^���Z����
;
; ����	HL = �J�E���^
; �o��	HL = HL - 1
;	�L�����[�t���O(�^�C���A�E�g�̂Ƃ��ɃZ�b�g)
; �j��	AF,HL
;------------------------------------------------------------------
DECHLCY:
	DEC	HL
	LD	A,H
	OR	L
	RET	NZ			;�܂��^�C���A�E�g���Ȃ�
_POPCRET:
	POP	HL			;�߂�A�h���X��j��
	SCF
	RET


	DS	1

;------------------------------------------------------------------
; BIOS FDCWRT
;
; ����	A' = �]�����R�[�h��
;	DE = �J�n���R�[�h�ԍ�
;	HL = �o�b�t�@�A�h���X
;------------------------------------------------------------------
__S_WRITE:
	.assert	$ == HFDCWRT
	LD	A,0AH			;SCSI WRITE(6)
	CALL	RWINIT			;�����ݒ�
SWRLOOP:
	CALL	SELCMD			;�Z���N�V�������R�}���h
	CALL	NC,S_DATAOUT		;�f�[�^�A�E�g
	CALL	GETSTMS			;�X�e�[�^�X�����b�Z�[�W
	JP	NZ,SWRLOOP		;���R�[�h�����̏������J��Ԃ�
	RET

;------------------------------------------------------------------
; ���N�G�X�g�Z���X
;
; ����	UNITNO[0FADEH] = �h���C�u�ԍ�
; �o��	HDSPCB[0FDB7H�`] = �g���Z���X�f�[�^(18�o�C�g)
;	E = �X�e�[�^�X
;	A = ���b�Z�[�W
;	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
REQUEST:
	CALL	UNITSEL
	LD	HL,CREQUEST		;REQUEST SENSE CDB
	CALL	NC,S_CMD6OUT
	LD	HL,DMAIOF
	LD	D,(HL)
	LD	(HL),A			;�]���Ώۂ��ꎞ�I�Ɂu�������v�ɐݒ肷��
	PUSH	DE
	LD	DE,SENSLEN
	LD	HL,HDSPCB
	CALL	NC,S_DATAIN
	POP	AF
	LD	(DMAIOF),A		;�]���Ώۂ����ɖ߂�
;------------------------------------------------------------------
; �X�e�[�^�X�����b�Z�[�W�C��(1�o�C�g�̂�)
;
; ����	�Ȃ�
; �o��	�L�����[�t���O(�t�F�[�Y�J�ڂُ̈�)
;	A = Message
;	E = Status
; �j��	AF,BC,DE
;------------------------------------------------------------------
S_STSMSG:
	LD	D,P_STAT		;�X�e�[�^�X�t�F�[�Y
	CALL	_S_STSIN
	LD	E,A			;E = �X�e�[�^�X
	
	LD	D,P_MSGI		;���b�Z�[�W�C���t�F�[�Y
_S_STSIN:
	CALL	REQWA			;REQ�҂�
	
	LD	D,11101100B		;D = Set ACK
	LD	C,LOW SCMD
	OUT	(C),D			;Set ACK
	
	LD	D,11001100B		;D = Reset ACK
	
ESREQ1:
	LD	A,B
	IN	A,(LOW PSNS)
	RLCA
	JR	C,ESREQ1		;REQ�l�Q�[�g�҂�
	
	LD	A,B
	IN	A,(LOW TEMP)		;��M�f�[�^�ǂݏo��
	
	OUT	(C),D			;Reset ACK
	RET

;------------------------------------------------------------------
; SCSI�o�X���Z�b�g�̂Â�
;------------------------------------------------------------------
_NEGRST:
	CALL	W1MS			;SRST�M���A�T�[�g����
	LD	D,A			;D = 0
;------------------------------------------------------------------
; SPC�R�}���h���s
;
; ����	D = SPC Command
; �o��	B = High SPCBASE
; �j��	A, BC
;------------------------------------------------------------------
SETSCMD:
	LD	BC,INTS
	LD	A,11111111B
	OUT	(C),A			;���荞�݃N���A
_SSCMD0:
	LD	C,LOW SCMD
_SSCMD1:
	OUT	(C),D			;SPC Command
	RET

;------------------------------------------------------------------
;�����ݒ�
RWINIT:
	LD	(CMDTBL),A		;SCSI �R�}���h�I�y�R�[�h��ݒ�
	LD	BC,0001H		;B = �R���g���[���o�C�g, C = �]���u���b�N��
	LD	(HDLEN),BC		;�]���u���b�N��(01H)�ƃR���g���[���o�C�g(00H)�̐ݒ�
	LD	A,MAXTRY		;���s��
	EX	AF,AF'
	RET

;�Z���N�V�������R�}���h
SELCMD:
	POP	BC			;�߂�A�h���X
	PUSH	AF			;�c�背�R�[�h��
	PUSH	DE			;���R�[�h�ԍ�
	PUSH	HL			;�o�b�t�@�A�h���X
	PUSH	BC
	PUSH	HL
	
	LD	H,E			;���R�[�h�ԍ��̏㉺�o�C�g����ւ�
	LD	L,D			;
	LD	(HDREC),HL		;LBA Mid Low
	
	CALL	UNITSEL			;�Z���N�V����
	JP	C,DEVOFE		;���Y�f�o�C�X�́A�g�p�s�\ or ���݂��Ȃ��A���邢�̓o�X���g���Ȃ�
	
	LD	HL,CMDTBL		;CDB�i�[�A�h���X
	CALL	S_CMD6OUT		;SCSI�R�}���h���M
	
	LD	DE,256			;�]���o�C�g���́A���� 256bytes
	POP	HL			;HL = �o�b�t�@�A�h���X
	RET				;�Ăяo�����ɖ߂�

;�X�e�[�^�X�����b�Z�[�W
GETSTMS:
	CALL	S_STSMSG		;E = �X�e�[�^�X / A = ���b�Z�[�W
	ADC	A,A			;�X�e�[�^�X�����b�Z�[�W�̎擾�󋵁A���b�Z�[�W�� Command Complete(00H) ���H
	JR	NZ,DIERR		;��L������ُ킾����
	LD	A,00111110B
	AND	E			;�X�e�[�^�X�� Good(SCSI2����) ���H
	JP	Z,STGOOD		;Good ��������
	
	CALL	W500MS			;�����ŁA������Ƒ҂��Ă݂�
	CALL	REQUEST			;�����[�o�u���f�o�C�X�� Check Condition �΍�����˂�
	ADC	A,A			;�X�e�[�^�X�����b�Z�[�W�̎擾�󋵁A���b�Z�[�W�� Command Complete(00H) ���H
	JR	NZ,DIERR		;��L������ُ킾����
	LD	A,00111110B
	AND	E			;�X�e�[�^�X�� Good(SCSI2����) ���H
	JR	NZ,DIERR		;Good �ł͂Ȃ�
	LD	A,(HDSPCB+12)		;Additional Sense Code �擾
	CP	27H			;�܂����̏������݋֎~��ԁH
	JP	Z,DEVWPE		;Write protected
STGOOD:
	POP	BC			;�߂�A�h���X
	POP	HL
	POP	DE
	JR	NZ,STRETRY		;�Ď��s������
	
	EX	AF,AF'
	LD	A,MAXTRY		;���s�񐔂̍Đݒ�
	EX	AF,AF'
	INC	H			;HL += 256
	INC	DE			;���̃��R�[�h��
	POP	AF
	DEC	A			;�c�背�R�[�h���̌��Z
	PUSH	BC
	RET				;�Ăяo�����ɖ߂�

STRETRY:
	EX	AF,AF'			;A'=���s��
	DEC	A
	JR	Z,DIERR			;���g���C�I�[�o�[
	EX	AF,AF'
	POP	AF			;�c�背�R�[�h��
	OR	A
	PUSH	BC
	RET				;�Ăяo�����ɖ߂�

DIERR:
	CALL	S_RESET
	JP	DEVIOE			;Device I/O ERROR

;------------------------------------------------------------------
; BIOS FDCRED/FDCWRT�p�Z���N�V����
;
; ����	UNITNO[0FADEH] = �h���C�u�ԍ�(0�`9)
;	LUNMOD[0FDAFH] = ����LUN���[�h(0,2,3)
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
;	A = 0(����I����)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
UNITSEL:
	LD	A,(LUNMOD)		;����LUN���[�h
	LD	C,A
	CP	02H			;0��c 2��z 3��nz
	LD	A,(UNITNO)		;�h���C�u�ԍ��̎擾
	LD	B,A
	JP	C,SLMOD0
	LD	L,A			;L = SCSI ID
	LD	A,0
	JR	NZ,SLMOD3
	LD	A,L
	RRCA				;(LUNMOD) = 2 �̂Ƃ�
SLMOD0:
	RRCA				;(LUNMOD) = 0 or 2 �̂Ƃ�
	LD	L,A			;L = SCSI ID
	
	LD	A,C			;C = 00B or 10B
	INC	A			;A = 01B or 11B
	AND	B			;B = (UNITNO) �̉���2�r�b�g
SLMOD3:
	LD	(HDDRV),A		;LBA High �ɁA����LUN�l��ݒ�
;------------------------------------------------------------------
; �Z���N�V����
;
; ����	L = �^�[�Q�b�gID
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
;	A = 0(����I����)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
S_SELECT:
	LD	B,L
	INC	B
	LD	A,10000000B		;A = �^�[�Q�b�gID �̃r�b�g
N2BLOOP:
	RLCA
	DJNZ	N2BLOOP			;ID�ɑΉ�����r�b�g�ʒu�܂Ŏ����Ă���
	LD	E,A			;E = Target bit
	
	LD	H,B
	LD	L,B			;HL = 0
	LD	BC,PCTL
	OUT	(C),L			;Selection �J�n
SELW1:
	CALL	DECHLCY			;��̃^�C���A�E�g����
	LD	A,B
	IN	A,(LOW SSTS)
	AND	11111000B		;SPC�ƃo�X���g����󋵂�
	JR	NZ,SELW1
	
	LD	A,B
	IN	A,(LOW BDID)
	OR	E			;�����ƃ^�[�Q�b�g��ID������
	LD	C,LOW TEMP
	OUT	(C),A			;SCSI�o�X�o�͒l���Z�b�g
	INC	C			;BC = TCH
	LD	HL,1004H		;�����Ď����� (HL�~256+15)�~125[ns]�~2 �� 262.40[ms]
	OUT	(C),H			;TCH = 10H
	INC	C
	OUT	(C),L			;TCM = 04H
	INC	C
	OUT	(C),L			;TCL = 4
	
	LD	D,00100000B		;Select
	CALL	SETSCMD
	PUSH	DE			;Wait for Arbitration (55 + TCL)�~125[ns] �� �ŏ�7.375[us]
	POP	DE
	LD	C,LOW INTS		;(10 + 11 + 10 + 7 + 8 + 3) x 250ns = 11.50[us](CPU 6MHz 7.666[us])
SELW2:
	IN	A,(C)			;���荞�ݗv���̓ǂݏo��
	JP	NZ,_CCEXIT		;�������N���Ă���I
	LD	A,B
	IN	A,(LOW SSTS)
	BIT	5,A			;SPC Busy ���ȁH
	JR	NZ,SELW2		;�܂� Busy
	RLCA				;�C�j�V�G�[�^�ɂȂ��Ă�H
	JR	C,_CCLOOP		;�Ȃ��Ă邩��
	
	SCF
	RET				;�Z���N�V�������s

;------------------------------------------------------------------
; �R�}���h(6�o�C�g��p)
;
; ����	HL = CDB�i�[�A�h���X
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
;	A = 0(����I����)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
S_CMD6OUT:
	LD	DE,6
;------------------------------------------------------------------
; �R�}���h
;
; ����	HL = CDB�i�[�A�h���X
; 	DE = �R�}���h��
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
;	A = 0(����I����)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
S_CMDOUT:
	CALL	SETDIO			;�]���o�C�g���̐ݒ�
	
	LD	D,P_CMD			;�R�}���h�t�F�[�Y
	CALL	REQWA			;REQ�҂�
	
	LD	D,10000100B		;Transfer without DREQ
	CALL	SETSCMD
	
	LD	D,10B			;d1 = FIFO full bit
	INC	E			;�]���o�C�g���̕␳
	LD	C,LOW DREG
COLOOP:
	LD	A,B
	IN	A,(LOW SSTS)
	AND	D			;check FIFO full(����A�܂������Ӗ����Ȃ��`�F�b�N)
	JR	NZ,COLOOP		;FIFO full
	INC	B			;���₭����
	OUTI
	DEC	E
	JP	NZ,COLOOP
_CCINTS:
	LD	C,LOW INTS
_CCLOOP:
	IN	A,(C)
	JR	Z,_CCLOOP		;���荞�ݔ����҂�
_CCEXIT:
	OUT	(C),A			;���荞�݃N���A
	XOR	00010000B		;�����������荞�݂� Command Complete �݂̂��H
	RET	Z			;����I����
	
	SCF
	RET

;------------------------------------------------------------------
; �f�[�^�A�E�g
;
; ����	DE = �]���o�C�g��
;       HL = �o�b�t�@�A�h���X
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
S_DATAOUT:
	CALL	SETDIO			;�]���o�C�g���̐ݒ�
	CALL	SDMADO			;DMA �f�[�^�A�E�g�ݒ�
	
	LD	D,P_DOUT		;�f�[�^�A�E�g�t�F�[�Y
	
	JP	_CDXFR

;------------------------------------------------------------------
; �f�[�^�C��
;
; ����	DE = �]���o�C�g��
;       HL = �o�b�t�@�A�h���X
; �o��	�L�����[�t���O(�Ȃ�炩�̃G���[�������ɃZ�b�g)
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
S_DATAIN:
	CALL	SETDIO			;�]���o�C�g���̐ݒ�
	CALL	SDMADI			;DMA �f�[�^�C���ݒ�
	
	LD	D,P_DINP		;�f�[�^�C���t�F�[�Y
_CDXFR:
	CALL	REQWA			;REQ�҂�
	
	LD	D,10000001B		;Transfer with DREQ + Padding
	CALL	SETSCMD
	
	JP	HDDMAS			;RAM�ɓW�J���ꂽ�]�������҂�������

;------------------------------------------------------------------
; �]���o�C�g���̐ݒ�
;
; ����	DE = �]���o�C�g��
; �o��	DE = �]���o�C�g��-1
; �j��	AF,BC,DE
;------------------------------------------------------------------
SETDIO:
	LD	BC,TCH
	XOR	A
	OUT	(C),A			;TCH = 0
	INC	C
	OUT	(C),D			;TCM = D
	INC	C
	OUT	(C),E			;TCL = E
	
	DEC	DE			;DE = DMA�ɐݒ肷��]���o�C�g��
	RET

;------------------------------------------------------------------
; SCSI Read DMA�ݒ�
;
; ����	DE = �]���o�C�g��-1
;       HL = �o�b�t�@�A�h���X
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
SDMADI:
	LD	BC,DMAIO
	PUSH	HL		;�o�b�t�@�A�h���X���X�^�b�N��
	LD	HL,RDPARM
	CALL	DMASET
	OUT	(C),E		;�]���o�C�g��-1
	OUT	(C),D
	LD	E,00010000B	;WR2
	CALL	MDPARM
_DLSET:
	POP	DE		;�X�^�b�N����A
	OUT	(C),E		;�o�b�t�@�A�h���X(SCSI Read) , �]���o�C�g��-1(SCSI Write)
	OUT	(C),D
DMASET:
	LD	A,(HL)
	INC	HL
DSLOOP:
	INC	B		;������
	OUTI
	DEC	A
	JP	NZ,DSLOOP
	RET

;------------------------------------------------------------------
; FDC/SASI���p����
;------------------------------------------------------------------
hoge	set	7AD2H-$
	.assert	$ <= 7AD2H

;------------------------------------------------------------------
	ORG	7AE2H
;------------------------------------------------------------------
; SCSI Write DMA�ݒ�
;
; ����	DE = �]���o�C�g��-1
;       HL = �o�b�t�@�A�h���X
; �j��	AF,BC,DE,HL
;------------------------------------------------------------------
SDMADO:
	LD	BC,DMAIO|83H
	OUT	(C),C		;WR6 Disable
	PUSH	DE		;�]���o�C�g��-1���X�^�b�N��
	LD	E,00010100B	;WR1
	CALL	MDPARM
	EX	DE,HL		;DE = �o�b�t�@�A�h���X
	LD	HL,WRPARM
	CALL	DMASET
	OUT	(C),E		;�o�b�t�@�A�h���X
	OUT	(C),D
	JP	_DLSET		;�]���o�C�g��-1�̐ݒ��

;------------------------------------------------------------------
; DMA�ݒ�l�̏��׍H
; �u�]���Ώۂ̐ݒ�v�͕K�{����
;------------------------------------------------------------------
MDPARM:
	LD	A,(DMAIOF)	;�]���Ώۂ̐ݒ�
	OR	E
	OUT	(C),A		;set WR1/WR2
	
	LD	A,(DMAXMD)	;DMA�]�����[�h
	OR	10001101B	;WR4
	OUT	(C),A		;set WR4
	
	RET

;------------------------------------------------------------------
; DMA�ւ̃R�}���h
;------------------------------------------------------------------
;X1turbo �� SCSI Write
;	DB	3
;	DB	083H		;WR6 Disable
;	DB	00010100B	;WR1 PA = ������, �A�h���X++
;	DB	10001101B	;WR4 ���샂�[�h = �o�C�g���[�h, PB�A�h���X�ݒ�
WRPARM:
	DB	3
	DW	DREG		;    PB�A�h���X = I/O SPC DREG
	DB	01111001B	;WR0 �]���o�C�g���ݒ�, PA�A�h���X�ݒ�, Transfer Mode, PB��PA
;	dw	hhll		;    PA�A�h���X(������)
;	dw	hhll		;    �]���o�C�g��-1
	
	DB	5
	DB	00101000B	;WR2 PB = I/O, �A�h���X�Œ�
	DB	10010010B	;WR5 RDY = Low, CE/WAIT�}���`, ���X�^�[�g����
	DB	0CFH		;WR6 Load
	DB	00000101B	;WR0 �uPA��PB�v�ɕύX�B�f�B�X�e�B�l�[�V�����Œ肠�邠��
	DB	0CFH		;WR6 Load

;SCSI Read �� X1turbo
RDPARM:
	DB	4
	DB	083H		;WR6 Disable
	DB	01111101B	;WR0 �]���o�C�g���ݒ�, PA�A�h���X�ݒ�, Transfer Mode, PA��PB
	DW	DREG		;    PA�A�h���X = I/O SPC DREG
;	dw	hhll		;    �]���o�C�g��-1
	
;	DB	00010000B	;WR2 PB = ������, �A�h���X++
;	DB	10001101B	;WR4 ���샂�[�h = �o�C�g���[�h, PB�A�h���X�ݒ�
;	dw	hhll		;    PB�A�h���X(������)
	
	DB	3
	DB	00101100B	;WR1 PA = I/O, �A�h���X�Œ�
	DB	10010010B	;WR5 RDY = Low, CE/WAIT�}���`, ���X�^�[�g����
	DB	0CFH		;WR6 Load

;------------------------------------------------------------------
; REQUEST SENSE CDB
;------------------------------------------------------------------
CREQUEST:
	DB	03H,00H,00H,00H,SENSLEN,00H


hoge	set	7B2DH-$
	.assert	$ <= 7B2DH

;------------------------------------------------------------------
; RAM��ɓW�J�����A�f�[�^�]�������҂�����
; �V���[�v���A�v���P�[�V�����ɂ́A���̃R�[�h�����������镨������
;------------------------------------------------------------------
	ORG	7EC5H
	.PHASE	0F929H
HDDMAS:
	.DEPHASE
;	LD	B,1EH
;	OUT	(C),B			;RAM�o���N�ɐ؂�ւ�
;	DI				;DMA�]�����̃o���N�؂�ւ��h�~
;	LD	A,87H			;WR6 DMA Enable
;	LD	BC,DMAIO
;	OUT	(C),A
;	LD	E,10H
;	LD	HL,0
;	LD	BC,PSNS
	ORG	7ED7H
	.PHASE	0F93BH
	DW	PSNS
	.DEPHASE
;XFRA1:					;�]�������҂����[�v
;	IN	A,(C)			;���t�F�[�Y�̓ǂݏo��
;	AND	010B			;C/D �݂̂��c��
;	CP	010B			;�f�[�^�t�F�[�Y�ȊO���H
	ORG	7EDCH
	.PHASE	0F940H
	DB	010B
	CP	010B
	.DEPHASE
;	JR	Z,XFRA3			;�f�[�^�t�F�[�Y�ȊO�ɑJ�ڂ����烋�[�v�E�o
;	DEC	HL
;	LD	A,H
;	OR	L
;	JR	NZ,XFRA1
;	DEC	E
;	JR	NZ,XFRA1
;	SCF
;XFRA3:	LD	B,1DH
;	OUT	(C),B			;ROM�o���N�ɖ߂�
;	EI
;	RET

;------------------------------------------------------------------
; �o���N�������֘A�̑Ή�
;------------------------------------------------------------------
	ORG	7DECH
	.PHASE	0F850H
	DB	10H
	.DEPHASE

	END