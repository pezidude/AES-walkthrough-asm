global ConvertHexToEAX
global byte_to_hex


extern roundKeys ; from keyExpansion.asm bss section

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

	
	
	
; ---------------------------
; Procedure: byte_to_hex
; Converts byte in AL to two ASCII hex characters at [RSI] and [RSI+1]
; Input:
;   AL  - byte to convert
;   RSI - pointer to where to store the result (2 bytes)
; Output:
;   [RSI]     = high nibble ASCII
;   [RSI + 1] = low nibble ASCII
; ---------------------------
byte_to_hex:
    push rax
    push rcx
    push rdx

    mov dl, al ; Save original byte in DL

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
	