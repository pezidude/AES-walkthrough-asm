section .bss
    originalKey resd 4 ; reserve 4 dwords (16 bytes)
	dwords resd 45 ; 44 double word and the t (varient that needed every 4 dwords (t4, t8, t12, ... ,t40))
section .data
	numbersStr:
    db "00","01","02","03","04","05","06","07","08","09","10","11","12","13","14","15"
    db "16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"
    db "32","33","34","35","36","37","38","39","40","41","42","43"
	
	tStr db "t:         " 
	tStrLength equ $ - tStr
	
	numberStrLength equ 2
	msgword db 'word'
	msgwordLength equ $ - msgword
	colonSymbol db ':'
	
	originalKeyLength equ 16
	dwordCounter db 0
	bindWordStr db 17 dup (0) ; 16 bits + newline character
	roundKeys dq 10 dup (0) ; 10 round Keys
	tCounter db 4 ; the first t is t4
	Rcon:
    dd 0x01000000, 0x02000000, 0x04000000, 0x08000000,0x10000000
    dd 0x20000000, 0x40000000, 0x80000000, 0x1B000000, 0x36000000
	
	roundCounter db 0
	
	timespec:
	dq 0 ; sec
	dq 250000000 ; nano sec
	
	goUpOneLine db 0x1b, '[1F' ; go the the beggining of the previous line
	goUpOneLineLength equ $ - goUpOneLine
	goRightXcolumns db 0x1b, '[11C'
	goRightXcolumnsLength equ $ - goRightXcolumns
	go4ColumnsRight db 0x1b, '[4C'
	go4ColumnsRightLenght equ $ - go4ColumnsRight
	
	
section .text
    global _start
	extern ConvertHexToEAX ; from formatConverter.asm
	extern substitute_al_via_sbox ; from AES_sbox_substitute.asm

	
; ----------------------------------------------------------------
; procedure that calls to function from formatConverter.asm
; the procedure handle a key in string format an input 
; and puts it in section .bss originalKey resd 4
; rsi = pointer to 32-char hex key string
; fills originalKey with 4 dwords
; ----------------------------------------------------------------
parse_key:
    xor rcx, rcx              ; index = 0

.loop:
    cmp rcx, 4
    je .done                  ; stop after 4 DWORDs

    mov rax, rsi              ; pointer to input string
    mov rdx, rcx
    shl rdx, 3                ; offset = rcx * 8 (8 hex chars per DWORD)
    add rax, rdx              ; point to next 8-hex-char block
    call ConvertHexToEAX          ; convert 8 hex chars at RAX to DWORD in RAX

    mov rbx, originalKey
    mov [rbx + rcx*4], eax    ; store DWORD at originalKey[rcx]

    inc rcx
    jmp .loop

.done:
    ret
	
	
; ----------------------------------------------------------------
; procedure that rotate a dword a byte left
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
; ----------------------------------------------------------------
printOpeningToWord:
	push rax
    push rcx
    push rbx
    push rsi
    push rdi
	
	;print 'word'
	mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, msgword
    mov     rdx, msgwordLength
	syscall
	
	xor rcx, rcx
	mov cl, [dwordCounter]
	;print the number of the word number based on [dwordCounter]
	mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    lea     rsi, [numbersStr + rcx*2]
    mov     rdx, numberStrLength ; numberStrLength = 2 (only one number)
	syscall
	
	;print ':'
	mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, colonSymbol
    mov     rdx, 1
	syscall
	
	;go 4 columns right
	mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, go4ColumnsRight
    mov     rdx, go4ColumnsRightLenght
	syscall
	
	pop rdi
    pop rsi
    pop rbx
    pop rcx
    pop rax
    ret
	
	
; ----------------------------------------------------------------
; procedure that prints 't:         '
; ----------------------------------------------------------------
printTopening:
	push rax
    push rcx
    push rbx
    push rsi
    push rdi
	
	;print t:
	mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, tStr
    mov     rdx, tStrLength
	syscall
	
	pop rdi
    pop rsi
    pop rbx
    pop rcx
    pop rax
	ret 
	
	
; ----------------------------------------------------------------
; void BinaryPrintIndexed(rdi = index into dwords array)
; Prints binary representation of dwords[rdi] with newline
; ----------------------------------------------------------------
BinaryPrintIndexed:
    push rax
    push rcx
    push rbx
    push rsi
    push rdi

    mov rbx, rdi                   ; Save index in rbx
    lea rsi, [dwords]              ; Point to start of dwords array
    mov eax, dword [rsi + rbx*4]  ; Load the desired double word

    mov rcx, 32                    ; Number of bits
    lea rsi, [bindWordStr]              ; Pointer to output buffer

.loop:
    shl eax, 1                     ; Shift MSB into CF
    jc .bit_is_1
    mov byte [rsi], '0'
    jmp .advance
.bit_is_1:
    mov byte [rsi], '1'
.advance:
    inc rsi
    loop .loop

    ; Add newline at the end
    mov byte [rsi], 0x0A          ; ASCII newline
    inc rsi

    ; Write output to stdout
    mov rax, 1                    ; sys_write
    mov rdi, 1                    ; stdout
	lea rsi, [bindWordStr]   ; Reset pointer to start of buffer
    mov rdx, 33                   ; 32 chars + newline
    syscall

    pop rdi
    pop rsi
    pop rbx
    pop rcx
    pop rax
    ret

; sleep for X sec, Y nano sec (X,Y are based on the values in the timespec that in the data segment)
nanosleep:
	push rax
    push rdi
    push rsi
	push rcx 
	push rbx
	
    mov     rax, 35             ; syscall number for nanosleep (Linux x86-64)
    lea     rdi, [rel timespec] ; pointer to struct timespec
    xor     rsi, rsi            ; NULL for rem (we don't care about remaining time)
    syscall

    ; Restore registers
	pop rbx
	pop rcx 
    pop rsi
    pop rdi
    pop rax
    ret
	
;----------------------------------------------------
; moveCursorUpOneLine
; Moves the terminal cursor to the beginning of the previous line
; using ANSI escape code via syscall write
;----------------------------------------------------
moveCursorUpOneLine:
    push rax
    push rdi
    push rsi
    push rdx
	push rcx 
	push rbx

    mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, goUpOneLine       ; pointer to ANSI escape sequence
    mov     rdx, goUpOneLineLength ; length of the sequence
    syscall
	pop rbx
	pop rcx 
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
	
	
;----------------------------------------------------
; moveCursorToRight
; Moves the terminal cursor X columns  to the right 
; (based on  section .data goRightXcolumns)
; using ANSI escape code via syscall write
;----------------------------------------------------
moveCursorToRight:
    push rax
    push rdi
    push rsi
    push rdx
	push rcx 
	push rbx

    mov     rax, 1          ; syscall number for write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, goRightXcolumns
    mov     rdx, goRightXcolumnsLength
    syscall
	pop rbx
	pop rcx 
    pop rdx
    pop rsi
    pop rdi
    pop rax
    ret
	
	
;----------------------------------------------------
; initialize the first 4 word based on the originalKey
;----------------------------------------------------
preRoundTransformation:
	push rbx
    push rcx
	push rax
	
	xor rcx, rcx
	mov cl, 4
	xor rax, rax
	xor rbx, rbx
InitWords:
	mov eax, dword [originalKey + rbx*4]
	mov [dwords + rbx*4], eax
	inc bl
	loop InitWords
	
	pop rax
	pop rcx
    pop rbx
	ret
	
	
; procedure that rotate a dword a byte left
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
;================================================
;************************VISUAL VERION************************
;================================================
VisualRotWord:
	push rsi
	push rax
	push rbx
	push rcx
	
	call BinaryPrintIndexed
	;sleep a little bit
	call nanosleep
	; go the the beggining of the previous line
	call moveCursorUpOneLine
	
	mov rdi, 44 ; the t varient (special)
	lea rsi, [dwords]
	xor rax, rax
	xor rcx, rcx
	mov cl, 8
	
loopRotateBitLeft:
	mov eax, dword [rsi + rdi*4]
	mov ebx, eax
	shl eax, 1 ; shift eax a byte left
	shr ebx, 31 ; shift ebx a 31 bytes right
	or eax, ebx ; eax is now rotated dword ( a byte left )
	mov rdi, 44 ; the t varient (special)
	mov dword [dwords +  rdi*4], eax	
	
	
	;move cursor to the right
	call moveCursorToRight
	; print the current rotation result
	mov rdi, 44 ; the t varient (special)
	call BinaryPrintIndexed ; with the index in rdi
	
	; go the the beggining of the previous line (skipped in the last iteration)
	call moveCursorUpOneLine

	;sleep a little bit
	call nanosleep
	; countinue loop (if need)
	loop loopRotateBitLeft
	
	pop rcx
	pop rbx
	pop rax
	pop rsi
	ret


; procedure that rotate a dword a byte left
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
;================================================
;************************NOT VISUAL VERION************************
;================================================
RotWord:
	push rsi
	push rax
	push rbx
	
	lea rsi, [dwords]
	xor rax, rax
    mov eax, dword [rsi + rdi*4]
	mov ebx, eax
	shl eax, 8 ; shift eax a byte left
	shr ebx, 24 ; shift ebx a 3 bytes right
	or eax, ebx ; eax is now rotated dword ( a byte left )
	mov dword [dwords +  rdi*4], eax	
	
	pop rbx
	pop rax
	pop rsi
	ret
	
	
; procedure that substitutes every byte in the dword by the Sbox
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
;================================================
;************************VISUAL VERION************************
;================================================	
VisualSubWord:
	push rsi
	push rax
	push rcx
	push r8
	
	lea rsi, [dwords + rdi*4] ; rsi holds the pointer to the word that i need to sub
	xor rax,rax
	xor r8, r8 ; counter 
	xor rcx, rcx
	mov cl, 4 ; 4 bytes to sub in a dword
Visualsubloop:
	mov al, byte [rsi + r8]
	call substitute_al_via_sbox ; al is the input (al holds the byte to sub, at the end al will have sbox(al) )
	mov byte [rsi + r8], al ; save the substituted byte
	inc r8
	
	;move cursor to the right
	call moveCursorToRight
	;print the dword with the current change
	mov rdi, 44 ; the t varient (special)
	call BinaryPrintIndexed
	
	;cmp cl, 1============================
	;je endSubLoop========================
	; go the the beggining of the previous line (skipped in the last iteration)
	call moveCursorUpOneLine
	

;endSubLoop:===========================
	;sleep a little bit
	call nanosleep
	; countinue loop (if need)
	loop Visualsubloop
	
	pop r8
	pop rcx
	pop rax
	pop rsi
	ret
	
	
; procedure that substitutes every byte in the dword by the Sbox
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
;================================================
;************************NOT VISUAL VERION************************
;================================================	
SubWord:
	push rsi
	push rax
	push rcx
	push r8
	
	lea rsi, [dwords + rdi*4] ; rsi holds the pointer to the word that i need to sub
	xor rax,rax
	xor r8, r8 ; counter 
	xor rcx, rcx
	mov cl, 4 ; 4 bytes to sub in a dword
subloop:
	mov al, byte [rsi + r8]
	call substitute_al_via_sbox ; al is the input (al holds the byte to sub, at the end al will have sbox(al) )
	mov byte [rsi + r8], al ; save the substituted byte
	inc r8
	loop subloop
	
	pop r8
	pop rcx
	pop rax
	pop rsi
	ret

	
;------------------------------------------
; procedure that addresses this condition: 
; if ( i mod 4) != 0,  Wi = W(i-1) ^ W(i-4)
;------------------------------------------
generateNewWordREGULAR:
	push rax
	push rbx
	push rdi
	
	xor rax, rax
	xor rbx, rbx
	movzx rdi, byte [dwordCounter]
	dec rdi
	mov eax, [dwords + rdi*4] ; W(i-1)
	inc rdi
	
	sub rdi, 4
	mov ebx, [dwords + rdi*4 ] ; W(i-4)
	add rdi, 4
	
	xor eax, ebx ; Wi = W(i-1) ^ W(i-4)
	mov dword [dwords + rdi*4], eax ; place the new word in the correct index
	
	pop rdi
	pop rbx
	pop rax
	ret
	
	
;------------------------------------------
; procedure that addresses this condition: 
; if ( i mod 4) == 0,  Wi = t ^ W(i - 4)
; t = Subword( Rotword(w(i-1)) ) ^ Rcon(i/4)
;------------------------------------------
generateNewWordSPECIAL:
	push rax
	push rbx
	push rdi
	
	xor rax, rax
	xor rbx, rbx
	movzx rdi, byte [dwordCounter]
	dec rdi
	mov eax, [dwords + rdi*4] ; W(i-1)
	inc rdi
	
	;set the t value
	mov rdi, 44
	mov [dwords + rdi*4], eax ; put W(i-1) in the t value (inital step)
	
	call printTopening
	call VisualRotWord
	call nanosleep ; sleep
	call VisualSubWord
	call nanosleep ; sleep
	
	movzx rdi, byte [dwordCounter]
	mov eax, [Rcon + rdi - 4] ; the current Round constant: rcon(rdi/4)
	mov rdi, 44
	xor [dwords + rdi*4], eax ; now [dwords + rdi*4] has the final t value
	
	call moveCursorToRight
	call BinaryPrintIndexed ; print the t value
	
	xor rax, rax 
	mov eax, [dwords + rdi*4] ; final t value
	movzx rdi, byte [dwordCounter]
	sub rdi, 4
	mov ebx, [dwords + rdi*4 ] ; W(i-4)
	add rdi, 4
	
	xor eax, ebx ; Wi = t ^ W(i-4)
	mov dword [dwords + rdi*4], eax ; place the new word in the correct index
	
	pop rdi
	pop rbx
	pop rax
	ret
	
	
_start:
	mov rdi, [rsp]          ; argc
    cmp rdi, 2
    jl _exit                ; if less than 2 args, exit
    mov rsi, [rsp + 16]     ; argv[1] - pointer to input string (key)
    call parse_key          ; call function to process the key
	
	
	call preRoundTransformation	
	xor rcx, rcx 
	mov cl, 4
	mov rdi, 0
printWords:
	call printOpeningToWord
    call BinaryPrintIndexed
	call nanosleep
	inc byte [dwordCounter]
	inc rdi
	loop printWords
	
	;----------test----------
	xor rcx, rcx 
	mov cx, 40
CreateAllWordsLoop:
	mov al, byte [dwordCounter] ; al is the dwordCounter
	and al, 0b11 ; al mod 4 result
	cmp al, 0
	je specialWord
	call generateNewWordREGULAR
	jmp continue
	
specialWord:
	call generateNewWordSPECIAL
	
continue:
	call printOpeningToWord
	movzx rdi, byte [dwordCounter]
	call BinaryPrintIndexed
	inc byte [dwordCounter]
	call nanosleep
	loop CreateAllWordsLoop
	

	
_exit:
	; exit(int status)
    mov     rax, 60         ; syscall number for sys_exit
    xor     rdi, rdi        ; exit status 0
    syscall
	