; search_replace.asm - Find and Replace Functions

%include "include/constants.inc"

extern SendMessageA, MessageBoxA, lstrlenA, SetFocus
extern hEdit, hMainWnd, SearchBuf, ReplaceBuf, FileBuffer
extern NotFound, InfoTitle, ReplaceSuccessMsg

global DoFindFirst, DoFindText, DoFindNext, DoReplaceText, DoReplaceAll

section .text

; ============================================================================
; DoFindFirst - Find from beginning of document
; ============================================================================
DoFindFirst:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 96
    
    ; Check if search buffer is empty
    cmp     byte [REL SearchBuf], 0
    je      near .NotFound
    
    ; Move cursor to beginning
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Search
    call    DoFindText
    
    mov     RSP, RBP
    pop     RBP
    ret

.NotFound:
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; DoFindText - Core search function from current cursor position
; Returns: EAX = 1 if found, 0 if not found
; ============================================================================
DoFindText:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 96
    
    ; Check if search buffer is empty
    cmp     byte [REL SearchBuf], 0
    je      near .NotFound
    
    ; Get current cursor position
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETSEL
    lea     R8, [RBP - 8]
    lea     R9, [RBP - 4]
    call    SendMessageA
    add     RSP, 48
    
    mov     R14D, dword [RBP - 4]    ; Start from end of selection
    
    ; Get text length
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0E
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    mov     R13D, EAX
    test    EAX, EAX
    jz      near .NotFound
    
    ; Check if at end
    cmp     R14D, R13D
    jge     near .NotFound
    
    ; Get all text
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0D
    mov     R8D, R13D
    inc     R8D
    lea     R9, [REL FileBuffer]
    call    SendMessageA
    add     RSP, 48
    
    ; Get search string length
    sub     RSP, 32
    lea     RCX, [REL SearchBuf]
    call    lstrlenA
    add     RSP, 32
    mov     R15D, EAX
    test    EAX, EAX
    jz      near .NotFound
    
    ; Setup search
    lea     RSI, [REL FileBuffer]
    add     RSI, R14
    lea     RDI, [REL SearchBuf]
    mov     R12D, R14D
    
.Loop:
    ; Check bounds
    mov     EAX, R12D
    add     EAX, R15D
    cmp     EAX, R13D
    jg      near .NotFound
    
    ; Check null terminator
    mov     AL, byte [RSI]
    test    AL, AL
    jz      near .NotFound
    
    ; Compare first character
    mov     BL, byte [RDI]
    cmp     AL, BL
    jne     near .Next
    
    ; First char matches - check rest
    push    RSI
    push    RDI
    mov     ECX, 1
    
.Compare:
    cmp     ECX, R15D
    jge     near .Found
    
    mov     AL, byte [RSI + RCX]
    mov     BL, byte [RDI + RCX]
    cmp     AL, BL
    jne     near .NoMatch
    
    inc     ECX
    jmp     near .Compare
    
.Found:
    pop     RDI
    pop     RSI
    
    ; Select the found text
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    mov     R8D, R12D
    mov     R9D, R12D
    add     R9D, R15D
    call    SendMessageA
    add     RSP, 48
    
    ; Set focus
    sub     RSP, 32
    mov     RCX, qword [REL hEdit]
    call    SetFocus
    add     RSP, 32
    
    mov     EAX, 1
    jmp     near .Done
    
.NoMatch:
    pop     RDI
    pop     RSI
    
.Next:
    inc     RSI
    inc     R12D
    jmp     near .Loop
    
.NotFound:
    xor     EAX, EAX
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; DoFindNext - Find next occurrence
; ============================================================================
DoFindNext:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 48
    
    ; Check if search buffer is empty
    cmp     byte [REL SearchBuf], 0
    je      near .NotFound
    
    ; Get current selection
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETSEL
    lea     R8, [RBP - 8]
    lea     R9, [RBP - 4]
    call    SendMessageA
    add     RSP, 48
    
    mov     EAX, dword [RBP - 4]
    
    ; If selection exists, move past it
    cmp     EAX, dword [RBP - 8]
    je      .NoSelection
    inc     EAX
    
.NoSelection:
    ; Set cursor
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    mov     R8D, EAX
    mov     R9D, EAX
    call    SendMessageA
    add     RSP, 48
    
    ; Search
    call    DoFindText
    test    EAX, EAX
    jnz     .Done
    
.NotFound:
    ; Show message
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL NotFound]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK | MB_ICONINFORMATION
    call    MessageBoxA
    add     RSP, 48
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; DoReplaceText - Replace current selection
; ============================================================================
DoReplaceText:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 64
    
    ; Get current selection
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETSEL
    lea     R8, [RBP - 8]
    lea     R9, [RBP - 4]
    call    SendMessageA
    add     RSP, 48
    
    mov     EAX, dword [RBP - 8]
    mov     EBX, dword [RBP - 4]
    
    ; Check if something is selected
    cmp     EAX, EBX
    je      .NoSelection
    
    ; Replace
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REPLACESEL
    mov     R8D, 1
    lea     R9, [REL ReplaceBuf]
    call    SendMessageA
    add     RSP, 48
    
.NoSelection:
    ; Find next
    call    DoFindNext
    
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; DoReplaceAll - Replace all occurrences
; ============================================================================
DoReplaceAll:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 96
    
    ; Start from beginning
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    xor     R15D, R15D          ; Counter
    
.Loop:
    ; Find next
    call    DoFindText
    test    EAX, EAX
    jz      .Done
    
    ; Replace
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REPLACESEL
    mov     R8D, 1
    lea     R9, [REL ReplaceBuf]
    call    SendMessageA
    add     RSP, 48
    
    inc     R15D
    
    ; Safety limit
    cmp     R15D, 100000
    jge     .Done
    
    jmp     .Loop
    
.Done:
    ; Show result
    test    R15D, R15D
    jz      .ShowNotFound
    
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL ReplaceSuccessMsg]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK | MB_ICONINFORMATION
    call    MessageBoxA
    add     RSP, 48
    jmp     .End
    
.ShowNotFound:
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL NotFound]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK | MB_ICONINFORMATION
    call    MessageBoxA
    add     RSP, 48
    
.End:
    ; Move to beginning
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    mov     RSP, RBP
    pop     RBP
    ret
