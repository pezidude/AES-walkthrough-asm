section .data
    msg db "Hello, World!", 10  ; message + newline
    len equ $ - msg             ; length of message

section .text
    global _start               ; entry point

_start:
    ; sys_write(int fd, const void *buf, size_t count)
    mov     rax, 1              ; syscall number for sys_write
    mov     rdi, 1              ; file descriptor 1 = stdout
    mov     rsi, msg            ; pointer to message
    mov     rdx, len            ; message length
    syscall                     ; invoke the kernel

    ; sys_exit(int status)
    mov     rax, 60             ; syscall number for sys_exit
    xor     rdi, rdi            ; exit code 0
    syscall                     ; exit the program
