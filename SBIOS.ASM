;------------------------------------------------------------------
;
; X1turbo SCSI BIOS
;
;  CPU/DMA 4MHz(6MHz)
;  SPC     8MHz(min.5MHz max.8MHz)
;

;------------------------------------------------------------------
; FDC ステップレートの変更
;------------------------------------------------------------------
FDCSTEP	EQU	1		;0=標準(20ms) 1=最高速(6ms)

;------------------------------------------------------------------
; EMM/ROMDISK関連
;------------------------------------------------------------------
EMMX	EQU	1		;EMM容量拡張 0=無効 1=有効
NUMROMD	EQU	9		;ROM Disk に用いるEMMドライブ番号

;------------------------------------------------------------------
; NMI関連
;------------------------------------------------------------------
UXNMI	EQU	1		;NMI再利用 0=しない 1=する

;------------------------------------------------------------------
; 機種固有値
;------------------------------------------------------------------
SCSI_ID	EQU	7		;本機の SCSI ID 初期値
SENSLEN	EQU	18		;リクエストセンスの受信データサイズ
MAXTRY	EQU	5		;試行回数

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
IPLPAT	EQU	0FA7H		;IPL初期化パッチ継続先
MONST	EQU	33C5H		;マシン語モニタの起動

DEVIOE	EQU	1000H		;Device I/O ERROR
DEVWPE	EQU	1003H		;Write protected
DEVOFE	EQU	1006H		;Device offline

W500MS	EQU	77A7H		;500ms 待ち(入力:なし 出力:A=0,BC=0)
W1MS	EQU	77C6H		;1ms 待ち(入力:なし 出力:A=0)
;------------------------------------------------------------------
HDINIT	EQU	78D9H		;HDD初期化BIOSエントリ
HDOFFS	EQU	78E2H		;HDOFFコマンドBIOSエントリ

HFDCRED	EQU	7906H		;HD用 FCDREDの非公開エントリ
HFDCWRT	EQU	7928H		;HD用 FCDWRTの非公開エントリ

;------------------------------------------------------------------
; BIOS WORK
;------------------------------------------------------------------
DMAIOF	EQU	0FAB9H		;転送対象 00H=メインメモリ 08H=I/Oメモリ(VRAM)
UNITNO	EQU	0FADEH		;ドライブ番号 0～F (HD4～9の使用はBASIC要改造。A～FはBASIC非対応)

LUNMOD	EQU	0FDAFH		;似非LUNモード 0:SASIっぽいやつ(標準 ID0=HD0,HD1 ID1=HD2,HD3) 2:4in1(ID0=HD0～3) 3:ID?=HD?(ID0=HD0 ID1=HD1 ...)
DMAXMD	EQU	0FDB0H		;DMA転送モード 00H:Byte(標準) 20H:Continuous(危険) 40H:Burst(危険)

CMDTBL	EQU	0FDB1H		;CDB Operation code
HDDRV	EQU	0FDB2H		;LUN(3) | LBA High(5)
HDREC	EQU	0FDB3H		;LBA Mid(8) / Low(8)
HDLEN	EQU	0FDB5H		;Transfer length(16)
CTLBYT	EQU	0FDB6H		;Control(8)

HDSPCB	EQU	0FDB7H		;比較的自由に使ってもいいらしいワークの先頭(最少10バイト、最大26バイト？)

;------------------------------------------------------------------
	.Z80
	ASEG

;------------------------------------------------------------------
; SPC初期化のフック
;------------------------------------------------------------------
	ORG	0018H
	JP	IPLSPC

if UXNMI
;------------------------------------------------------------------
; NMIの再利用
;------------------------------------------------------------------
	ORG	0066H+1
	DW	0F800H			;SIO Ch.B 割り込みベクタのアドレス

	ORG	7D9CH			;F800H～ に転送される
	JP	0006H			;オリジナル処理へ
endif ;UXNMI

if FDCSTEP
;------------------------------------------------------------------
; FDC へのステップレートパラメータを最速設定
;------------------------------------------------------------------
	ORG	030DH			;IPL 5" 2D
	DB	00H			;Restore 20ms → 6ms

	ORG	031FH			;IPL 5" 2D
	DB	1CH			;Seek 20ms → 6ms

	ORG	762BH			;BIOS 5" FM 2D 160KB
	DB	1CH			;Seek 20ms → 6ms

	ORG	7631H			;BIOS 5" MFM 2D 320KB
	DB	1CH			;Seek 20ms → 6ms

	ORG	7857H			;BIOS 5" 8"共用
	DB	00H			;Restore 20ms → 6ms
endif ;FDCSTEP

;------------------------------------------------------------------
; IPLメニューの '5"HD' を 'SCSI' に変更
;------------------------------------------------------------------
	ORG	0E50H
	DB	'SCSI'			;'5"HD' → 'SCSI'
	ORG	0E56H
	DB	'6'			;'10M' → '16M'

;------------------------------------------------------------------
; IPLメニュー "M" の処理への対応
;------------------------------------------------------------------
;;;	ORG	0FD3H
;;;	DW	MONST			;マシン語モニタへ

;------------------------------------------------------------------
; IPLメニュー "M" のメモリクリア処理を潰した空間
;------------------------------------------------------------------
	ORG	72D5H
	JP	MONST			;マシン語モニタへ

if EMMX
;------------------------------------------------------------------
; EMM存在確認処理にパッチを行い、
; ROM DISK ドライブ指定時に書き込み可否をスキップするパッチ
;------------------------------------------------------------------
P_EMM:
	RLCA
	RLCA
	LD	C,A
	CP	NUMROMD SHL 2		;ROM Disk の番号か？
	RET	NZ			;ROM Disk でなければ通常処理を継続
	POP	AF
	JP	74A8H			;存在確認処理をスキップ
endif ;EMMX

hoge	set	72F5H-$


if EMMX
;------------------------------------------------------------------
; EMM の最大レコード番号チェック処理をつぶすパッチ
;------------------------------------------------------------------
	ORG	74ADH
	JP	74B7H

;------------------------------------------------------------------
; EMM の存在チェック(書き込み可否)へのパッチ
;------------------------------------------------------------------
	ORG	7482H
	CALL	P_EMM			;RLCA / RLCA / LD C,A
endif ;EMMX


;------------------------------------------------------------------
; IPLのHDブート処理から初期化処理を外す
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
; ここから SASI 処理空間(一部、FDC処理と共用に留意)
;------------------------------------------------------------------
	ORG	78C1H

;------------------------------------------------------------------
; IPLでのSPC初期化
;------------------------------------------------------------------
IPLSPC:
	CALL	S_INIT			;SPC初期化＆バスリセット
	JP	IPLPAT			;元々の処理へ移行

;------------------------------------------------------------------
; REQ待ち
;
; 入力	D = 実行予定フェーズ
; 出力	キャリーフラグ(フェースの不一致)
;	A = 0(正常終了時)
;	B = High SPCBASE
; 破壊	AF,BC
;------------------------------------------------------------------
REQWA:
	LD	BC,PSNS
REQWA1:
	IN	A,(C)
	JP	P,REQWA1		;REQまだ
	
	AND	111B			;MSG, C/D, I/O を残す
	XOR	D			;フェーズの判定
	JR	NZ,_POPCRET		;実行予定フェーズと異なる
	
	LD	C,LOW PCTL
	OUT	(C),D			;実行フェーズを設定
	
	RET

;------------------------------------------------------------------
; HDINIT(HDブート時のみ呼ばれる？)
;
; 入力	なし(無視)
; 出力	キャリーフラグをリセット
; 破壊	AF
;------------------------------------------------------------------
__HDINIT:
	.assert	$ == HDINIT
	XOR	A
	RET

;------------------------------------------------------------------
; SPC初期化＆バスリセット
;
; 入力	なし
; 出力	なし
; 破壊	AF,BC,D,HL
;------------------------------------------------------------------
S_INIT:
	LD	BC,SCTL
	LD	A,10010000B		;SPC Reset & Disable, Arbitration Enable
	JR	_S_INIT

;------------------------------------------------------------------
; HDOFFS(HuBASIC,turbo CP/M のコマンドから呼ばれる)
;
; 入力	なし(無視)
; 出力	キャリーフラグをリセット
; 破壊	AF
;------------------------------------------------------------------
__HDOFFS:
	.assert	$ == HDOFFS
	XOR	A
	RET

;------------------------------------------------------------------
; SPC初期化のつづき
;------------------------------------------------------------------
_S_INIT:
	OUT	(C),A
	DEC	C			;BC = BDID
	LD	A,SCSI_ID		;SCSI ID とする値をセット
	OUT	(C),A			;SPC に本機の SCSI ID を設定
	
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
; SCSIバスリセット
;
; 入力	なし
; 出力	なし
; 破壊	AF,BC,D
;------------------------------------------------------------------
S_RESET:
	LD	D,00010000B		;RST Out
	CALL	SETSCMD
	JR	_NEGRST


	DS	2

;------------------------------------------------------------------
; BIOS FDCRED
;
; 入力	A' = 転送レコード数
;	DE = 開始レコード番号
;	HL = バッファアドレス
;------------------------------------------------------------------
__S_READ:
	.assert	$ == HFDCRED
	LD	A,08H			;SCSI READ(6)
	CALL	RWINIT			;初期設定
SRDLOOP:
	CALL	SELCMD			;セレクション＆コマンド
	CALL	NC,S_DATAIN		;データイン
	CALL	GETSTMS			;ステータス＆メッセージ
	JP	NZ,SRDLOOP		;レコード数分の処理を繰り返す
	RET

;------------------------------------------------------------------
; SPC初期化レジスタリスト
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
; タイムアウト用カウンタ減算処理
;
; 入力	HL = カウンタ
; 出力	HL = HL - 1
;	キャリーフラグ(タイムアウトのときにセット)
; 破壊	AF,HL
;------------------------------------------------------------------
DECHLCY:
	DEC	HL
	LD	A,H
	OR	L
	RET	NZ			;まだタイムアウトしない
_POPCRET:
	POP	HL			;戻りアドレスを破棄
	SCF
	RET


	DS	1

;------------------------------------------------------------------
; BIOS FDCWRT
;
; 入力	A' = 転送レコード数
;	DE = 開始レコード番号
;	HL = バッファアドレス
;------------------------------------------------------------------
__S_WRITE:
	.assert	$ == HFDCWRT
	LD	A,0AH			;SCSI WRITE(6)
	CALL	RWINIT			;初期設定
SWRLOOP:
	CALL	SELCMD			;セレクション＆コマンド
	CALL	NC,S_DATAOUT		;データアウト
	CALL	GETSTMS			;ステータス＆メッセージ
	JP	NZ,SWRLOOP		;レコード数分の処理を繰り返す
	RET

;------------------------------------------------------------------
; リクエストセンス
;
; 入力	UNITNO[0FADEH] = ドライブ番号
; 出力	HDSPCB[0FDB7H～] = 拡張センスデータ(18バイト)
;	E = ステータス
;	A = メッセージ
;	キャリーフラグ(なんらかのエラー発生時にセット)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
REQUEST:
	CALL	UNITSEL
	LD	HL,CREQUEST		;REQUEST SENSE CDB
	CALL	NC,S_CMD6OUT
	LD	HL,DMAIOF
	LD	D,(HL)
	LD	(HL),A			;転送対象を一時的に「メモリ」に設定する
	PUSH	DE
	LD	DE,SENSLEN
	LD	HL,HDSPCB
	CALL	NC,S_DATAIN
	POP	AF
	LD	(DMAIOF),A		;転送対象を元に戻す
;------------------------------------------------------------------
; ステータス＆メッセージイン(1バイトのみ)
;
; 入力	なし
; 出力	キャリーフラグ(フェーズ遷移の異常)
;	A = Message
;	E = Status
; 破壊	AF,BC,DE
;------------------------------------------------------------------
S_STSMSG:
	LD	D,P_STAT		;ステータスフェーズ
	CALL	_S_STSIN
	LD	E,A			;E = ステータス
	
	LD	D,P_MSGI		;メッセージインフェーズ
_S_STSIN:
	CALL	REQWA			;REQ待ち
	
	LD	D,11101100B		;D = Set ACK
	LD	C,LOW SCMD
	OUT	(C),D			;Set ACK
	
	LD	D,11001100B		;D = Reset ACK
	
ESREQ1:
	LD	A,B
	IN	A,(LOW PSNS)
	RLCA
	JR	C,ESREQ1		;REQネゲート待ち
	
	LD	A,B
	IN	A,(LOW TEMP)		;受信データ読み出し
	
	OUT	(C),D			;Reset ACK
	RET

;------------------------------------------------------------------
; SCSIバスリセットのつづき
;------------------------------------------------------------------
_NEGRST:
	CALL	W1MS			;SRST信号アサート期間
	LD	D,A			;D = 0
;------------------------------------------------------------------
; SPCコマンド発行
;
; 入力	D = SPC Command
; 出力	B = High SPCBASE
; 破壊	A, BC
;------------------------------------------------------------------
SETSCMD:
	LD	BC,INTS
	LD	A,11111111B
	OUT	(C),A			;割り込みクリア
_SSCMD0:
	LD	C,LOW SCMD
_SSCMD1:
	OUT	(C),D			;SPC Command
	RET

;------------------------------------------------------------------
;初期設定
RWINIT:
	LD	(CMDTBL),A		;SCSI コマンドオペコードを設定
	LD	BC,0001H		;B = コントロールバイト, C = 転送ブロック数
	LD	(HDLEN),BC		;転送ブロック数(01H)とコントロールバイト(00H)の設定
	LD	A,MAXTRY		;試行回数
	EX	AF,AF'
	RET

;セレクション＆コマンド
SELCMD:
	POP	BC			;戻りアドレス
	PUSH	AF			;残りレコード数
	PUSH	DE			;レコード番号
	PUSH	HL			;バッファアドレス
	PUSH	BC
	PUSH	HL
	
	LD	H,E			;レコード番号の上下バイト入れ替え
	LD	L,D			;
	LD	(HDREC),HL		;LBA Mid Low
	
	CALL	UNITSEL			;セレクション
	JP	C,DEVOFE		;当該デバイスは、使用不能 or 存在しない、あるいはバスが使えない
	
	LD	HL,CMDTBL		;CDB格納アドレス
	CALL	S_CMD6OUT		;SCSIコマンド送信
	
	LD	DE,256			;転送バイト数は、いつも 256bytes
	POP	HL			;HL = バッファアドレス
	RET				;呼び出し元に戻る

;ステータス＆メッセージ
GETSTMS:
	CALL	S_STSMSG		;E = ステータス / A = メッセージ
	ADC	A,A			;ステータス＆メッセージの取得状況、メッセージは Command Complete(00H) か？
	JR	NZ,DIERR		;上記何れも異常だった
	LD	A,00111110B
	AND	E			;ステータスは Good(SCSI2準拠) か？
	JP	Z,STGOOD		;Good だったよ
	
	CALL	W500MS			;ここで、ちょっと待ってみる
	CALL	REQUEST			;リムーバブルデバイスの Check Condition 対策も兼ねる
	ADC	A,A			;ステータス＆メッセージの取得状況、メッセージは Command Complete(00H) か？
	JR	NZ,DIERR		;上記何れも異常だった
	LD	A,00111110B
	AND	E			;ステータスは Good(SCSI2準拠) か？
	JR	NZ,DIERR		;Good ではない
	LD	A,(HDSPCB+12)		;Additional Sense Code 取得
	CP	27H			;まさかの書き込み禁止状態？
	JP	Z,DEVWPE		;Write protected
STGOOD:
	POP	BC			;戻りアドレス
	POP	HL
	POP	DE
	JR	NZ,STRETRY		;再試行処理へ
	
	EX	AF,AF'
	LD	A,MAXTRY		;試行回数の再設定
	EX	AF,AF'
	INC	H			;HL += 256
	INC	DE			;次のレコードへ
	POP	AF
	DEC	A			;残りレコード数の減算
	PUSH	BC
	RET				;呼び出し元に戻る

STRETRY:
	EX	AF,AF'			;A'=試行回数
	DEC	A
	JR	Z,DIERR			;リトライオーバー
	EX	AF,AF'
	POP	AF			;残りレコード数
	OR	A
	PUSH	BC
	RET				;呼び出し元に戻る

DIERR:
	CALL	S_RESET
	JP	DEVIOE			;Device I/O ERROR

;------------------------------------------------------------------
; BIOS FDCRED/FDCWRT用セレクション
;
; 入力	UNITNO[0FADEH] = ドライブ番号(0～9)
;	LUNMOD[0FDAFH] = 似非LUNモード(0,2,3)
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
;	A = 0(正常終了時)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
UNITSEL:
	LD	A,(LUNMOD)		;似非LUNモード
	LD	C,A
	CP	02H			;0→c 2→z 3→nz
	LD	A,(UNITNO)		;ドライブ番号の取得
	LD	B,A
	JP	C,SLMOD0
	LD	L,A			;L = SCSI ID
	LD	A,0
	JR	NZ,SLMOD3
	LD	A,L
	RRCA				;(LUNMOD) = 2 のとき
SLMOD0:
	RRCA				;(LUNMOD) = 0 or 2 のとき
	LD	L,A			;L = SCSI ID
	
	LD	A,C			;C = 00B or 10B
	INC	A			;A = 01B or 11B
	AND	B			;B = (UNITNO) の下位2ビット
SLMOD3:
	LD	(HDDRV),A		;LBA High に、似非LUN値を設定
;------------------------------------------------------------------
; セレクション
;
; 入力	L = ターゲットID
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
;	A = 0(正常終了時)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
S_SELECT:
	LD	B,L
	INC	B
	LD	A,10000000B		;A = ターゲットID のビット
N2BLOOP:
	RLCA
	DJNZ	N2BLOOP			;IDに対応するビット位置まで持っていく
	LD	E,A			;E = Target bit
	
	LD	H,B
	LD	L,B			;HL = 0
	LD	BC,PCTL
	OUT	(C),L			;Selection 開始
SELW1:
	CALL	DECHLCY			;謎のタイムアウト処理
	LD	A,B
	IN	A,(LOW SSTS)
	AND	11111000B		;SPCとバスが使える状況か
	JR	NZ,SELW1
	
	LD	A,B
	IN	A,(LOW BDID)
	OR	E			;自分とターゲットのIDを合成
	LD	C,LOW TEMP
	OUT	(C),A			;SCSIバス出力値をセット
	INC	C			;BC = TCH
	LD	HL,1004H		;応答監視時間 (HL×256+15)×125[ns]×2 → 262.40[ms]
	OUT	(C),H			;TCH = 10H
	INC	C
	OUT	(C),L			;TCM = 04H
	INC	C
	OUT	(C),L			;TCL = 4
	
	LD	D,00100000B		;Select
	CALL	SETSCMD
	PUSH	DE			;Wait for Arbitration (55 + TCL)×125[ns] → 最小7.375[us]
	POP	DE
	LD	C,LOW INTS		;(10 + 11 + 10 + 7 + 8 + 3) x 250ns = 11.50[us](CPU 6MHz 7.666[us])
SELW2:
	IN	A,(C)			;割り込み要因の読み出し
	JP	NZ,_CCEXIT		;何かが起きている！
	LD	A,B
	IN	A,(LOW SSTS)
	BIT	5,A			;SPC Busy かな？
	JR	NZ,SELW2		;まだ Busy
	RLCA				;イニシエータになってる？
	JR	C,_CCLOOP		;なってるかも
	
	SCF
	RET				;セレクション失敗

;------------------------------------------------------------------
; コマンド(6バイト専用)
;
; 入力	HL = CDB格納アドレス
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
;	A = 0(正常終了時)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
S_CMD6OUT:
	LD	DE,6
;------------------------------------------------------------------
; コマンド
;
; 入力	HL = CDB格納アドレス
; 	DE = コマンド長
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
;	A = 0(正常終了時)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
S_CMDOUT:
	CALL	SETDIO			;転送バイト数の設定
	
	LD	D,P_CMD			;コマンドフェーズ
	CALL	REQWA			;REQ待ち
	
	LD	D,10000100B		;Transfer without DREQ
	CALL	SETSCMD
	
	LD	D,10B			;d1 = FIFO full bit
	INC	E			;転送バイト数の補正
	LD	C,LOW DREG
COLOOP:
	LD	A,B
	IN	A,(LOW SSTS)
	AND	D			;check FIFO full(現状、まったく意味がないチェック)
	JR	NZ,COLOOP		;FIFO full
	INC	B			;おやくそく
	OUTI
	DEC	E
	JP	NZ,COLOOP
_CCINTS:
	LD	C,LOW INTS
_CCLOOP:
	IN	A,(C)
	JR	Z,_CCLOOP		;割り込み発生待ち
_CCEXIT:
	OUT	(C),A			;割り込みクリア
	XOR	00010000B		;発生した割り込みは Command Complete のみか？
	RET	Z			;正常終了時
	
	SCF
	RET

;------------------------------------------------------------------
; データアウト
;
; 入力	DE = 転送バイト数
;       HL = バッファアドレス
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
S_DATAOUT:
	CALL	SETDIO			;転送バイト数の設定
	CALL	SDMADO			;DMA データアウト設定
	
	LD	D,P_DOUT		;データアウトフェーズ
	
	JP	_CDXFR

;------------------------------------------------------------------
; データイン
;
; 入力	DE = 転送バイト数
;       HL = バッファアドレス
; 出力	キャリーフラグ(なんらかのエラー発生時にセット)
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
S_DATAIN:
	CALL	SETDIO			;転送バイト数の設定
	CALL	SDMADI			;DMA データイン設定
	
	LD	D,P_DINP		;データインフェーズ
_CDXFR:
	CALL	REQWA			;REQ待ち
	
	LD	D,10000001B		;Transfer with DREQ + Padding
	CALL	SETSCMD
	
	JP	HDDMAS			;RAMに展開された転送完了待ち処理へ

;------------------------------------------------------------------
; 転送バイト数の設定
;
; 入力	DE = 転送バイト数
; 出力	DE = 転送バイト数-1
; 破壊	AF,BC,DE
;------------------------------------------------------------------
SETDIO:
	LD	BC,TCH
	XOR	A
	OUT	(C),A			;TCH = 0
	INC	C
	OUT	(C),D			;TCM = D
	INC	C
	OUT	(C),E			;TCL = E
	
	DEC	DE			;DE = DMAに設定する転送バイト数
	RET

;------------------------------------------------------------------
; SCSI Read DMA設定
;
; 入力	DE = 転送バイト数-1
;       HL = バッファアドレス
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
SDMADI:
	LD	BC,DMAIO
	PUSH	HL		;バッファアドレスをスタックへ
	LD	HL,RDPARM
	CALL	DMASET
	OUT	(C),E		;転送バイト数-1
	OUT	(C),D
	LD	E,00010000B	;WR2
	CALL	MDPARM
_DLSET:
	POP	DE		;スタックから、
	OUT	(C),E		;バッファアドレス(SCSI Read) , 転送バイト数-1(SCSI Write)
	OUT	(C),D
DMASET:
	LD	A,(HL)
	INC	HL
DSLOOP:
	INC	B		;いつもの
	OUTI
	DEC	A
	JP	NZ,DSLOOP
	RET

;------------------------------------------------------------------
; FDC/SASI共用処理
;------------------------------------------------------------------
hoge	set	7AD2H-$
	.assert	$ <= 7AD2H

;------------------------------------------------------------------
	ORG	7AE2H
;------------------------------------------------------------------
; SCSI Write DMA設定
;
; 入力	DE = 転送バイト数-1
;       HL = バッファアドレス
; 破壊	AF,BC,DE,HL
;------------------------------------------------------------------
SDMADO:
	LD	BC,DMAIO|83H
	OUT	(C),C		;WR6 Disable
	PUSH	DE		;転送バイト数-1をスタックへ
	LD	E,00010100B	;WR1
	CALL	MDPARM
	EX	DE,HL		;DE = バッファアドレス
	LD	HL,WRPARM
	CALL	DMASET
	OUT	(C),E		;バッファアドレス
	OUT	(C),D
	JP	_DLSET		;転送バイト数-1の設定へ

;------------------------------------------------------------------
; DMA設定値の小細工
; 「転送対象の設定」は必須処理
;------------------------------------------------------------------
MDPARM:
	LD	A,(DMAIOF)	;転送対象の設定
	OR	E
	OUT	(C),A		;set WR1/WR2
	
	LD	A,(DMAXMD)	;DMA転送モード
	OR	10001101B	;WR4
	OUT	(C),A		;set WR4
	
	RET

;------------------------------------------------------------------
; DMAへのコマンド
;------------------------------------------------------------------
;X1turbo → SCSI Write
;	DB	3
;	DB	083H		;WR6 Disable
;	DB	00010100B	;WR1 PA = メモリ, アドレス++
;	DB	10001101B	;WR4 動作モード = バイトモード, PBアドレス設定
WRPARM:
	DB	3
	DW	DREG		;    PBアドレス = I/O SPC DREG
	DB	01111001B	;WR0 転送バイト数設定, PAアドレス設定, Transfer Mode, PB→PA
;	dw	hhll		;    PAアドレス(メモリ)
;	dw	hhll		;    転送バイト数-1
	
	DB	5
	DB	00101000B	;WR2 PB = I/O, アドレス固定
	DB	10010010B	;WR5 RDY = Low, CE/WAITマルチ, リスタート無し
	DB	0CFH		;WR6 Load
	DB	00000101B	;WR0 「PA→PB」に変更。ディスティネーション固定あるある
	DB	0CFH		;WR6 Load

;SCSI Read → X1turbo
RDPARM:
	DB	4
	DB	083H		;WR6 Disable
	DB	01111101B	;WR0 転送バイト数設定, PAアドレス設定, Transfer Mode, PA→PB
	DW	DREG		;    PAアドレス = I/O SPC DREG
;	dw	hhll		;    転送バイト数-1
	
;	DB	00010000B	;WR2 PB = メモリ, アドレス++
;	DB	10001101B	;WR4 動作モード = バイトモード, PBアドレス設定
;	dw	hhll		;    PBアドレス(メモリ)
	
	DB	3
	DB	00101100B	;WR1 PA = I/O, アドレス固定
	DB	10010010B	;WR5 RDY = Low, CE/WAITマルチ, リスタート無し
	DB	0CFH		;WR6 Load

;------------------------------------------------------------------
; REQUEST SENSE CDB
;------------------------------------------------------------------
CREQUEST:
	DB	03H,00H,00H,00H,SENSLEN,00H


hoge	set	7B2DH-$
	.assert	$ <= 7B2DH

;------------------------------------------------------------------
; RAM上に展開される、データ転送完了待ち処理
; シャープ製アプリケーションには、このコードを書き換える物がある
;------------------------------------------------------------------
	ORG	7EC5H
	.PHASE	0F929H
HDDMAS:
	.DEPHASE
;	LD	B,1EH
;	OUT	(C),B			;RAMバンクに切り替え
;	DI				;DMA転送中のバンク切り替え防止
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
;XFRA1:					;転送完了待ちループ
;	IN	A,(C)			;現フェーズの読み出し
;	AND	010B			;C/D のみを残す
;	CP	010B			;データフェーズ以外か？
	ORG	7EDCH
	.PHASE	0F940H
	DB	010B
	CP	010B
	.DEPHASE
;	JR	Z,XFRA3			;データフェーズ以外に遷移したらループ脱出
;	DEC	HL
;	LD	A,H
;	OR	L
;	JR	NZ,XFRA1
;	DEC	E
;	JR	NZ,XFRA1
;	SCF
;XFRA3:	LD	B,1DH
;	OUT	(C),B			;ROMバンクに戻す
;	EI
;	RET

;------------------------------------------------------------------
; バンクメモリ関連の対応
;------------------------------------------------------------------
	ORG	7DECH
	.PHASE	0F850H
	DB	10H
	.DEPHASE

	END
