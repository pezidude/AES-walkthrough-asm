global ConvertHexToEAX
section .text

; Convert 8 hex chars at [RAX] to a 32-bit value in EAX
; Assumptions:
; - [RAX] points to a null-terminated string of 8 uppercase hex characters (e.g., "1A3F5C7E")
; - The string contains only valid uppercase hex digits ('0'-'9', 'A'-'F')
; - The result is stored in EAX

ConvertHexToEAX:
    push rbx            ; Preserve RBX
    push rcx            ; Preserve RCX
    push rdx            ; Preserve RDX
    xor rdx, rdx        ; Clear RDX (will hold the result)

    mov rcx, 8          ; Set counter for 8 hex digits

ConvertLoop:
    movzx rbx, byte [rax] ; Load next byte (hex char) from string
    test  rbx, rbx        ; Check if it's the null terminator
    jz    Done            ; If null terminator, we're done

    ; Convert ASCII hex char to its numeric value
    cmp   bl, '0'
    jb    InvalidChar
    cmp   bl, '9'
    jbe   ValidHexDigit
    cmp   bl, 'A'
    jb    InvalidChar
    cmp   bl, 'F'
    jbe   ValidHexDigit
InvalidChar:
    pop rdx
    pop rcx
    pop rbx
    ret

ValidHexDigit:
    sub   bl, '0'         ; Convert '0'-'9' to 0-9
    cmp   bl, 10
    jl    NotAlpha
    sub   bl, 7           ; Convert 'A'-'F' to 10-15
NotAlpha:
    shl   rdx, 4          ; Shift left by 4 to make room for the next digit
    or    dl, bl          ; Add the digit to the result

    inc   rax             ; Move to the next character
    loop  ConvertLoop     ; Repeat for all 8 digits

Done:
    mov eax, edx          ; Move the result to EAX
    pop rdx               ; Restore RDX
    pop rcx               ; Restore RCX
    pop rbx               ; Restore RBX
    ret
