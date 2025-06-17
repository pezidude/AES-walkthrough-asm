 
; https://gist.github.com/ConnerWill/d4b6c776b509add763e17f9f113fd25bu

section .data
  beginingOfTable db 0x1b, '[12A', 0x1b, '[2D', 0
  beginingOfTableLen equ $ - beginingOfTable

	items db 0AAh, 0ABh, 0BBh, 0BCh, 0CCh, 0CDh, 0DDh, 0DEh, 0EEh, 0EEh, 011h, 022h, 033h, 044h, 055h, 066h
	lenItems equ $ - items
	diff db 3 ; location in the line
	itemDiff db 0
	template db '        |        |        |        ', 10
	lenTemplate equ $ - template
  x db 'x'

timespec:
	dq 0
	dq 10000000

section .bss
	buffer resb lenTemplate    ; make a writable copy
	
section .text
    global _start
	
	
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
	
print_table:
    mov byte [itemDiff], 0
    ; mov byte [diff], 3
    call copy_template_to_buffer	
	
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
    mov al, [items + rdx]
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
  ret




	
_start:
  
  mov r8, 1000
loopBig:
	call print_table
	; sleep for 1 second
	mov rax, 35 ; syscall number for nanosleep
	lea rdi, [rel timespec]
  xor rsi, rsi ; Null pointer to rem
  syscall
  ; increment the value of all the items AA -> ABh
  xor rcx, rcx
  mov cl, lenItems
loopUpdate:
    dec cl
    inc byte [items + rcx]
    inc cl
    loop loopUpdate

    cmp r8, 1
    je endLoop
    mov rax, 1
    mov rdi, 1
    mov rsi, beginingOfTable
    mov rdx, beginingOfTableLen
    syscall

endLoop:
    dec r8
    cmp r8, 0
    jnz loopBig


    ; exit(int status)
    mov     rax, 60         ; syscall number for sys_exit
    xor     rdi, rdi        ; exit status 0
    syscall
