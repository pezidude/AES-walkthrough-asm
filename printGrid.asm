


section .data
    msg     db      'Hello, world!', 10,10,10    ; string with newline
    len     equ     $ - msg             ; length of the string
	
	item0 db 0AAh
	item1 db 0ABh
	item2 db 0BBh
	item3 db 0BCh
	item4 db 0CCh
	item5 db 0CDh
	item6 db 0DDh
	item7 db 0DEh
	item8 db 0EEh
	item9 db 0EEh
	item10 db 011h
	item11 db 022h
	item12 db 033h
	item13 db 044h
	item14 db 055h
	item15 db 066h
	lenItem equ $ - item8
	diff db 3 ; location in the line
	itemDiff db 0
	template db '        |        |        |        ', 10
	lenTemplate equ $ - template

section .bss
	buffer resb lenTemplate    ; make a writable copy
	
section .text
    global _start
	
	
; ---------------------------
; Procedure: byte_to_hex
; Converts byte in AL to two ASCII hex characters at [RSI] and [RSI+1]
; Preserves: all general-purpose registers
; Input:
;   AL  - byte to convert
;   RSI - pointer to where to store the result (2 bytes)
; Output:
;   [RSI]     = high nibble ASCII
;   [RSI + 1] = low nibble ASCII
; ---------------------------

byte_to_hex:
    ; Save all potentially clobbered registers
    push rax
    push rcx
    push rdx

    mov dl, al              ; Save original byte in DL

    ; Convert high nibble
    mov al, dl
    shr al, 4
    call nibble_to_ascii
    mov [rsi], al

    ; Convert low nibble
    mov al, dl
    and al, 0Fh
    call nibble_to_ascii
    mov [rsi + 1], al

    ; Restore saved registers
    pop rdx
    pop rcx
    pop rax
    ret

; ---------------------------
; Procedure: nibble_to_ascii
; Converts 0–15 in AL to ASCII '0'–'9', 'A'–'F'
; Destroys only AL
; ---------------------------
nibble_to_ascii:
    cmp al, 9
    jbe .is_digit
    add al, 'A' - 10
    ret
.is_digit:
    add al, '0'
    ret
	
	

	; ---------------------------------
; Procedure: copy_template_to_buffer
; Copies "template" to "buffer"
; Clobbers: rsi, rdi, rcx, al
; ---------------------------------
copy_template_to_buffer:
    mov rsi, template
    mov rdi, buffer
    mov rcx, lenTemplate
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    loop .copy_loop
    ret
	
; write_template: writes the buffer pointed to by 'template' of length 'lenTemplate' to stdout
write_template:
    ; save caller-saved registers that we will clobber
    push    rax
    push    rdi
    push    rsi
    push    rdx
    push    rcx            ; also save RCX to preserve loop counters

    ; prepare and invoke syscall: sys_write(stdout, template, lenTemplate)
    mov     rax, 1              ; syscall number for sys_write
    mov     rdi, 1              ; file descriptor 1 = stdout
    mov     rsi, template       ; pointer to buffer
    mov     rdx, lenTemplate    ; buffer length
    syscall                     

    ; restore registers in reverse order of push
    pop     rcx
    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
	ret
	
	
	
_start:
	call copy_template_to_buffer	
    ; write(int fd, const void *buf, size_t count)
    mov     rax, 1          ; syscall number for sys_write
    mov     rdi, 1          ; file descriptor 1 = stdout
    mov     rsi, msg        ; pointer to string
    mov     rdx, len        ; length of string
    syscall                 ; make syscall
	
	mov rcx, 4
loopGrid:
	call write_template
	push rcx
    call copy_template_to_buffer
	push rcx
	push rax
	push rbx
	push rdx
	movzx rbx, byte [diff]
	mov rcx, 4
setItems:
	movzx rdx, byte[itemDiff]
    mov al, [item0 + rdx]
    lea rsi, [buffer + rbx]
	add rbx, 9
	inc byte [itemDiff]
	call byte_to_hex
	loop setItems 
	; setItems loop ended

	pop rdx
	pop rbx
	pop rax
	pop rcx
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, buffer     
    mov     rdx, lenTemplate
    syscall
	call write_template
    pop rcx
	loop loopGrid

	
	
    ; exit(int status)
    mov     rax, 60         ; syscall number for sys_exit
    xor     rdi, rdi        ; exit status 0
    syscall
