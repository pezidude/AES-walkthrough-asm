section .bss
    originalKey resd 4 ; reserve 4 dwords (16 bytes)
	dwords resd 45 ; 44 double word and the t (varient that needed every 4 dwords (t4, t8, t12, ... ,t40))
section .data
	
	;originalKey dd 2475A2B3h, 34755688h, 31E21200h, 13AA5487h
	originalKeyLength equ 16
	;dwords dd 45 dup (0) 
	dwordCounter db 0
	bindWordStr db 17 dup(0)         ; 16 bits + newline character
	roundKeys dq 10 dup (0) ; 10 round Keys
	Rcon:
    dd 0x01000000
    dd 0x02000000
    dd 0x04000000
    dd 0x08000000
    dd 0x10000000
    dd 0x20000000
    dd 0x40000000
    dd 0x80000000
    dd 0x1B000000
    dd 0x36000000
	
	roundCounter db 0
	
	timespec:
	dq 1 ; sec
	dq 0 ; nano sec
	
	goUpOneLine db 0x1b, '[1F' ; go the the beggining of the previous line
	goUpOneLineLength equ $ - goUpOneLine
	
	
	
section .text
    global _start
	extern ConvertHexToEAX
	
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
; initialize the first 4 word based on the originalKey
;----------------------------------------------------
preRoundTransformation:
	push rbx
    push rcx
	push rax
	
	xor rcx, rcx
	mov cl, 4
	xor rbx, rbx

	xor rax, rax
InitWords:
	xor rbx, rbx
	mov bl, [dwordCounter]
	mov eax, dword [originalKey + rbx*4]
	mov [dwords + rbx*4], eax
	inc byte [dwordCounter]
	loop InitWords
	
	pop rax
	pop rcx
    pop rbx
	ret
	
; proc that rotate a dword a byte left
; input rdi = index into dwords array (rdi =0 - word0 , rdi = 1 - word1)
;================================================
;************************VISUAL VERION************************
;================================================
RotWordVisual:
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
	
	; print the current rotation result
	mov rdi, 44 ; the t varient (special)
	call BinaryPrintIndexed ; with the index in rdi
	
	cmp cl, 1
	je endLoop
	; go the the beggining of the previous line (skipped in the last iteration)
	call moveCursorUpOneLine

endLoop:
	;sleep a little bit
	call nanosleep
	; countinue loop (if need)
	loop loopRotateBitLeft
	
	pop rcx
	pop rbx
	pop rax
	pop rsi
	ret


; proc that rotate a dword a byte left
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

SubWord:
	nop
	; code
	
	
	
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
    call BinaryPrintIndexed
	inc rdi
	loop printWords
	
	;----------test----------
	mov rdi, 3
	mov eax, dword [dwords +  rdi*4],
	mov rdi, 44
	mov dword [dwords +  rdi*4], eax	
	
	call RotWordVisual ; testing visual rotate on word3
	
	

_exit:
	; exit(int status)
    mov     rax, 60         ; syscall number for sys_exit
    xor     rdi, rdi        ; exit status 0
    syscall
	