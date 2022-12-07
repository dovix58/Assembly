;Atpazistamas komandos atvejis 1011wreg bojb [bovb]
;MOV registras, betarpiskas operandas

;Konkreciau - programoje parodytas tik 10111011 bobj bovb
;MOV bx, bovb bojb
;Pvz.: BB 12 34 => MOV bx, 03412h

;Prefiksai sioje pavyzdineje programoje nenagrinejami todel, kad
;si komanda nedirba su atmintim (registrai yra ne atmintyje, o procesoriuje)
;ir nera eilutine

.model small
.stack 100h
.data
	senasIP dw ?
	senasCS dw ?
	
	regAX dw ?
	regBX dw ?
	regCX dw ?
	regDX dw ?
	regSP dw ?
	regBP dw ?
	regSI dw ?
	regDI dw ?
	
	baitas1 db ?
	baitas2 db ?
	baitas3 db ?
	baitas4 db ?
	baitas5 db ?
	baitas6 db ?
	
	zingsn_pranesimas db "Zingsninis pertraukimas: $"
	mov_bx_kabl		  db "MOV bx, $"
	bx_lygu db "bx=$"
	enteris db 13,10,"$"
.code
	mov ax, @data
	mov ds, ax
	
	;<<<<Cia turetu buti help parametra /? apdorojantis kodas>>>>>
	
;============ISSISAUGOME SENUS PERTRAUKIMO CS,IP============
	;Zingsninis pertraukimas yra INT 1
	;Vektoriu lentele prasideda adresu 00000
	;N-tojo pertraukimo (INT n), adresu 4n
	;Pirmojo: INT 1 adresu 00004
	;IP zodis padetas: 00004, 00005 (jaun, vyr)
	;CS zodis padetas: 00006, 00007 (jaun, vyr)
	;Pertraukimo apdorojimo proceduros AA=CS*10h+IP
	mov ax, 0
	mov es, ax ;Extra segmentas prasides ten pat kur vektoriu lentele
				;To reikia, kad galetume prieiti prie vektoriu lenteles baitu reiksmiu
	
	mov ax, es:[4]
	mov bx, es:[6]
	mov senasCS, bx
	mov senasIP, ax ;neisikeliam tiesiai, nes nera perdavimo is atminties i atminti (butina panaudoti registrus, isimtis eilutines komandos, bet jas panaudoti butu sudetingiau)

;===================PERIMAME PERTRAUKIMA==========================
	;Pertraukimo CS reiksme imame tokia, kokia ji yra sioje programos vietoje
	;Pertraukimo IP reiksme imama offset pertraukimas
	;t.y. "pertraukimas" proceduros poslinkis nuo kodo segmento pradzios
	mov ax, cs
	mov bx, offset pertraukimas
	
	mov es:[4], bx
	mov es:[6], ax

;=================AKTYVUOJAME ZINGSNINI REZIMA===================
	;Tam reikia nustatyti status flag registre pozymi TF vienetu
	;Su SF registru galime "bendrauti" tik per steka (noredami keisti TF pozymi)
	pushf ;PUSH SF
	pop ax
	or ax, 100h ;0000 0001 0000 0000 (TF=1, kiti lieka kokie buvo)
	push ax
	popf  ;POP SF ;>Zingsninis rezimas ijungiamas po sios komandos ivykdymo - ivykdzius kiekviena sekancia komanda ivyks zingsninis pertraukimas

;==================BELEKOKIOS KOMANDOS====================
	;Testinis gabaliukas, kur vykdomos komandos, kurias pertraukimas
	;Zingsninis vykdomas PO kiekvienos komandos bandys atpazinti
	;Pirmoji komanda siame bloke nebus atpazinta todel, kad zingsninis pertraukimas
	;Ivykes po pirmosios komandos ivykdymo gauna CS,IP reiksmes, kurios rodo
	;i sekancia, o ne einamaja komanda
	mov ax, 8414h
	mov bx, 9854h
	mov bx, 7897h
	mov bx, 7897h
	mov bx, 7897h
	mov bx, 7897h
	inc bx
	mov bx, 9854h
;==================ISJUNGIAME ZINGSNINI REZIMA======================
	pushf
	pop  ax
	and  ax, 0FEFFh ;1111 1110 1111 1111 (nuliukas priekyj F, nes skaiciai privalo prasideti skaitmeniu, ne raide) - TF=0, visi kiti liks nepakeisti
	push ax
	popf ;>Zingsninis rezimas isjungiamas po sios komandos ivykdymo
;===================ATSTATOME PERTRAUKIMO CS, IP===================
;Kaip reikia uzdaryti failus, taip ir kai pertraukimas nereikalingas
;butina atstatyti vektoriu lenteleje ankstesni jo adresa
;Principas - "kaip radom taip ir paliekam"
	mov ax, senasIP
	mov bx, senasCS
	mov es:[4], ax
	mov es:[6], bx
	
uzdaryti_programa:
	mov ah, 4Ch
	int 21h
	
	
	
	
	
;==================================================================
;Pertraukimo apdorojimo procedura
;==================================================================
pertraukimas:	
			;issisaugom registru reiksmes, nes pertraukime ketiname su jom dirbti, o pertraukimas
			;turetu ivykti nepaveikdamas programos darbo (ir senu registru reiksmiu)
			;be to gali tekti vietomis spausdinti iskvieciant pertraukima esancias registru reiksmes :]
	mov regAX, ax				
	mov regBX, bx
	mov regCX, cx
	mov regDX, dx
	mov regSP, sp
	mov regBP, bp
	mov regSI, si
	mov regDI, di
	
		;Sie veiksmai reikalingi norint gauti komandos poslinki nuo kodo segmento pradzios i SI registra (kad galetume prieiti prie tu baitu reiksmiu)
		pop si ;pasiimam IP reiksme (kvieciant pertraukima ji buvo i steka padeta paskutine)
		pop di ;pasiimam CS reiksme
		push di ;padedam CS reiksme
		push si ;vel padedam atgal - nagrinejama komanda esancia CS:IP (naudosime DI:SI)
		
		;Susidedam masininio kodo baitus i atminti
		mov ax, cs:[si]
		mov bx, cs:[si+2]
		mov cx, cs:[si+4]
		
		mov baitas1, al
		mov baitas2, ah
		mov baitas3, bl
		mov baitas4, bh
		mov baitas5, cl
		mov baitas6, ch
		
		;Siame formate niekada nebuna segmento keitimo prefiksu, ju neapdorosime
		;Jei pirmas baitas yra BB reiskia apdorojam ta komandos atveji, jei ne iseinam
		cmp al, 0BBh
		jne grizti_is_pertraukimo
		
		mov ah, 9 ;Spausdinam pranesima apie zingsnini pertraukima
		mov dx, offset zingsn_pranesimas
		int 21h
		
	;Spausdinam "CS:IP"
		mov ax, di ;spausdinam CS
		call printAX
	
		mov ah, 2
		mov dl, ":"
		int 21h ;spausdinam dvitaski
		
		mov ax, si ;spausdinam IP
		call printAX
	
	call printSpace
	
	;Spausdinam masininio kodo baitus (musu atveju butinai trys)
	mov ah, baitas1
	mov al, baitas2
	call printAX
	mov al, baitas3
	call printAL
	
	call printSpace
	call printSpace
	
	;Spausdinam komandos mnemonika (asemblerini uzrasa)
	mov ah, 9
	mov dx, offset mov_bx_kabl ;MOV bx, 
	int 21h
	
	mov ah, 2 ;nulio simbolis, nes kai priekyj raide butina prirasyt nuli (konstantu uzrasymo taisykles)
				;T.y. MOV bx, FFFFh nekompiliuos, o MOV bx, 0FFFFh kompiliuos
	mov dl, "0"
	int 21h
	
	 
	;spausdinam betarpiska operanda (operanda konstanta)
	mov ah, baitas3
	mov al, baitas2
	call printAX
	
	mov ah, 2 ;h raide prie sesioliktainio skaiciaus (butina rasant asemblerines komandas)
	mov dl, "h"
	int 21h
	
	call printSpace
	call printSpace
	
	mov ah, 2 ;Spausdinam kabliataski
	mov dl, ";"
	int 21h
	call printSpace
	
	mov ah, 9
	mov dx, offset bx_lygu
	int 21h
	
	;Spausdiname bx reiksme esancia PRIES EINAMOSIOS KOMANDOS VYKDYMA
	mov ax, regBX
	call printAX
	
	;Spausdinam enteri
		mov ah, 9
		mov dx, offset enteris
		int 21h
	
	grizti_is_pertraukimo:
	mov ax, regAX
	mov bx, regBX
	mov cx, regCX
	mov dx, regDX
	mov sp, regSP
	mov bp, regBP
	mov si, regSI
	mov di, regDI
IRET ;grizimas is pertraukimo apdorojimo proceduros

;===================PAGALBINES pertraukime naudojamos proceduros================

;>>>Spausdinti AX reiksme
printAX:
	push ax
	mov al, ah
	call printAL
	pop ax
	call printAL
RET

;>>>>Spausdink tarpa
printSpace:
	push ax
	push dx
		mov ah, 2
		mov dl, " "
		int 21h
	pop dx
	pop ax
RET

;>>>Spausdinti AL reiksme
printAL:
	push ax
	push cx
		push ax
		mov cl, 4
		shr al, cl
		call printHexSkaitmuo
		pop ax
		call printHexSkaitmuo
	pop cx
	pop ax
RET

;>>>Spausdina hex skaitmeni pagal AL jaunesniji pusbaiti (4 jaunesnieji bitai - > AL=72, tai 0010)
printHexSkaitmuo:
	push ax
	push dx
	
	and al, 0Fh ;nunulinam vyresniji pusbaiti AND al, 00001111b
	cmp al, 9
	jbe PrintHexSkaitmuo_0_9
	jmp PrintHexSkaitmuo_A_F
	
	PrintHexSkaitmuo_A_F: 
	sub al, 10 ;10-15 ===> 0-5
	add al, 41h
	mov dl, al
	mov ah, 2; spausdiname simboli (A-F) is DL'o
	int 21h
	jmp PrintHexSkaitmuo_grizti
	
	
	PrintHexSkaitmuo_0_9: ;0-9
	mov dl, al
	add dl, 30h
	mov ah, 2 ;spausdiname simboli (0-9) is DL'o
	int 21h
	jmp printHexSkaitmuo_grizti
	
	printHexSkaitmuo_grizti:
	pop dx
	pop ax
RET

END
