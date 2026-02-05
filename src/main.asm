; main.asm - Application Entry Point

extern GetModuleHandleA, ExitProcess
extern GetMessageA, TranslateMessage, DispatchMessageA
extern RegisterClassExA, ShowWindow, UpdateWindow, LoadImageA
extern CreateAcceleratorTableA, TranslateAcceleratorA
extern LoadLibraryA
extern hInstance, hMainWnd, hAccel, AccelTable, AccelCount
extern CreateMainWindow, DialogProc, DialogClassName
extern RichEditLib

global Start

section .text

; ============================================================================
; Start - Application entry point
; ============================================================================
Start:
    sub     RSP, 8          ; Align stack
    
    ; Get module handle
    sub     RSP, 32
    xor     ECX, ECX
    call    GetModuleHandleA
    mov     qword [REL hInstance], RAX
    add     RSP, 32
    
    ; Call WinMain
    call    WinMain
    
    ; Exit
    xor     ECX, ECX
    call    ExitProcess

; ============================================================================
; WinMain - Main application logic
; ============================================================================
%include "include/constants.inc"

WinMain:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 160
    
    ; Load RichEdit 2.0 library for proper undo support
    sub     RSP, 32
    lea     RCX, [REL RichEditLib]
    call    LoadLibraryA
    add     RSP, 32
    test    RAX, RAX
    jz      .Error  ; If failed to load, exit
    
    ; Register dialog class
    mov     dword [RBP - 136], 80
    mov     dword [RBP - 132], CS_HREDRAW | CS_VREDRAW
    lea     RAX, [REL DialogProc]
    mov     qword [RBP - 128], RAX
    mov     dword [RBP - 120], 0
    mov     dword [RBP - 116], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RBP - 112], RAX
    mov     qword [RBP - 104], 0
    mov     qword [RBP - 96], 0
    mov     qword [RBP - 88], COLOR_WINDOW + 1
    mov     qword [RBP - 80], 0
    lea     RAX, [REL DialogClassName]
    mov     qword [RBP - 72], RAX
    mov     qword [RBP - 64], 0
    
    sub     RSP, 32
    lea     RCX, [RBP - 136]
    call    RegisterClassExA
    add     RSP, 32
    
    ; Create main window
    call    CreateMainWindow
    mov     qword [RBP - 8], RAX
    
    ; Show window
    sub     RSP, 32
    mov     RCX, qword [RBP - 8]
    mov     EDX, SW_SHOWNORMAL
    call    ShowWindow
    add     RSP, 32
    
    ; Update window
    sub     RSP, 32
    mov     RCX, qword [RBP - 8]
    call    UpdateWindow
    add     RSP, 32
    
    ; Create accelerator table for keyboard shortcuts
    sub     RSP, 32
    lea     RCX, [REL AccelTable]
    mov     EDX, dword [REL AccelCount]
    call    CreateAcceleratorTableA
    mov     qword [REL hAccel], RAX
    add     RSP, 32
    
.MsgLoop:
    ; Get message
    sub     RSP, 32
    lea     RCX, [RBP - 56]
    xor     EDX, EDX
    xor     R8D, R8D
    xor     R9D, R9D
    call    GetMessageA
    add     RSP, 32
    
    test    RAX, RAX
    jz      .MsgDone
    
    ; Try accelerator table first
    sub     RSP, 48
    mov     RCX, qword [REL hMainWnd]
    mov     RDX, qword [REL hAccel]
    lea     R8, [RBP - 56]
    call    TranslateAcceleratorA
    add     RSP, 48
    test    EAX, EAX
    jnz     .MsgLoop  ; Accelerator handled, get next message
    
    ; Translate message
    sub     RSP, 32
    lea     RCX, [RBP - 56]
    call    TranslateMessage
    add     RSP, 32
    
    ; Dispatch message
    sub     RSP, 32
    lea     RCX, [RBP - 56]
    call    DispatchMessageA
    add     RSP, 32
    jmp     .MsgLoop
    
.MsgDone:
    mov     RSP, RBP
    pop     RBP
    xor     EAX, EAX
    ret

.Error:
    ; Failed to load RichEdit library
    mov     RSP, RBP
    pop     RBP
    mov     EAX, -1
    ret
