; dialogs.asm - Find and Replace Dialog Management

%include "include/constants.inc"

extern CreateWindowExA, DestroyWindow, SendMessageA, MessageBoxA
extern EnableWindow, SetFocus
extern hInstance, hMainWnd, hFindDlg, hReplaceDlg
extern hFindEdit, hReplaceEdit1, hReplaceEdit2
extern SearchBuf, ReplaceBuf, NotFound, InfoTitle
extern DialogClassName, EditClass, ButtonClass, StaticClass
extern FindTitle, ReplaceTitle, LabelFind, LabelReplace
extern BtnOK, BtnCancel, BtnFindNext, BtnReplace, BtnReplaceAll
extern DoFindFirst, DoFindText, DoReplaceText, DoReplaceAll

global ShowFindDialog, ShowReplaceDialog, DialogProc

section .text

; ============================================================================
; ShowFindDialog - Create and show Find dialog
; ============================================================================
ShowFindDialog:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 32
    
    ; Check if already exists
    mov     RAX, qword [REL hFindDlg]
    test    RAX, RAX
    jnz     .Done
    
    ; Disable main window
    sub     RSP, 32
    mov     RCX, qword [REL hMainWnd]
    xor     EDX, EDX
    call    EnableWindow
    add     RSP, 32
    
    ; Create dialog
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL DialogClassName]
    lea     R8, [REL FindTitle]
    mov     R9D, WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE
    mov     dword [RSP + 32], 200
    mov     dword [RSP + 40], 200
    mov     dword [RSP + 48], 400
    mov     dword [RSP + 56], 110
    mov     RAX, qword [REL hMainWnd]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hFindDlg], RAX
    add     RSP, 96
    
    ; Create label
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL StaticClass]
    lea     R8, [REL LabelFind]
    mov     R9D, WS_CHILD | WS_VISIBLE
    mov     dword [RSP + 32], 10
    mov     dword [RSP + 40], 15
    mov     dword [RSP + 48], 80
    mov     dword [RSP + 56], 20
    mov     RAX, qword [REL hFindDlg]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Create edit box
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL EditClass]
    xor     R8D, R8D
    mov     R9D, WS_CHILD | WS_VISIBLE | WS_BORDER | ES_LEFT | ES_AUTOHSCROLL
    mov     dword [RSP + 32], 90
    mov     dword [RSP + 40], 12
    mov     dword [RSP + 48], 290
    mov     dword [RSP + 56], 22
    mov     RAX, qword [REL hFindDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_FIND_EDIT
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hFindEdit], RAX
    add     RSP, 96
    
    ; Create OK button
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnOK]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON
    mov     dword [RSP + 32], 150
    mov     dword [RSP + 40], 50
    mov     dword [RSP + 48], 100
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hFindDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_OK_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Create Cancel button
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnCancel]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    mov     dword [RSP + 32], 260
    mov     dword [RSP + 40], 50
    mov     dword [RSP + 48], 100
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hFindDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_CANCEL_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Set focus
    sub     RSP, 32
    mov     RCX, qword [REL hFindEdit]
    call    SetFocus
    add     RSP, 32
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; ShowReplaceDialog - Create and show Replace dialog
; ============================================================================
ShowReplaceDialog:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 32
    
    mov     RAX, qword [REL hReplaceDlg]
    test    RAX, RAX
    jnz     .Done
    
    ; Disable main window
    sub     RSP, 32
    mov     RCX, qword [REL hMainWnd]
    xor     EDX, EDX
    call    EnableWindow
    add     RSP, 32
    
    ; Create dialog
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL DialogClassName]
    lea     R8, [REL ReplaceTitle]
    mov     R9D, WS_POPUP | WS_CAPTION | WS_SYSMENU | WS_VISIBLE
    mov     dword [RSP + 32], 200
    mov     dword [RSP + 40], 200
    mov     dword [RSP + 48], 450
    mov     dword [RSP + 56], 180
    mov     RAX, qword [REL hMainWnd]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hReplaceDlg], RAX
    add     RSP, 96
    
    ; Label 1
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL StaticClass]
    lea     R8, [REL LabelFind]
    mov     R9D, WS_CHILD | WS_VISIBLE
    mov     dword [RSP + 32], 10
    mov     dword [RSP + 40], 15
    mov     dword [RSP + 48], 100
    mov     dword [RSP + 56], 20
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Edit 1
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL EditClass]
    xor     R8D, R8D
    mov     R9D, WS_CHILD | WS_VISIBLE | WS_BORDER | ES_LEFT | ES_AUTOHSCROLL
    mov     dword [RSP + 32], 110
    mov     dword [RSP + 40], 12
    mov     dword [RSP + 48], 320
    mov     dword [RSP + 56], 22
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_FIND_EDIT
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hReplaceEdit1], RAX
    add     RSP, 96
    
    ; Label 2
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL StaticClass]
    lea     R8, [REL LabelReplace]
    mov     R9D, WS_CHILD | WS_VISIBLE
    mov     dword [RSP + 32], 10
    mov     dword [RSP + 40], 50
    mov     dword [RSP + 48], 100
    mov     dword [RSP + 56], 20
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Edit 2
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL EditClass]
    xor     R8D, R8D
    mov     R9D, WS_CHILD | WS_VISIBLE | WS_BORDER | ES_LEFT | ES_AUTOHSCROLL
    mov     dword [RSP + 32], 110
    mov     dword [RSP + 40], 47
    mov     dword [RSP + 48], 320
    mov     dword [RSP + 56], 22
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_REPLACE_EDIT
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hReplaceEdit2], RAX
    add     RSP, 96
    
    ; Buttons: Find Next, Replace, Replace All, Cancel
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnFindNext]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    mov     dword [RSP + 32], 10
    mov     dword [RSP + 40], 95
    mov     dword [RSP + 48], 130
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_FINDNEXT_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnReplace]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_DEFPUSHBUTTON
    mov     dword [RSP + 32], 150
    mov     dword [RSP + 40], 95
    mov     dword [RSP + 48], 130
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_REPLACE_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnReplaceAll]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    mov     dword [RSP + 32], 290
    mov     dword [RSP + 40], 95
    mov     dword [RSP + 48], 130
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_REPLACEALL_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ButtonClass]
    lea     R8, [REL BtnCancel]
    mov     R9D, WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON
    mov     dword [RSP + 32], 150
    mov     dword [RSP + 40], 135
    mov     dword [RSP + 48], 130
    mov     dword [RSP + 56], 28
    mov     RAX, qword [REL hReplaceDlg]
    mov     qword [RSP + 64], RAX
    mov     dword [RSP + 72], IDC_CANCEL_BTN
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    add     RSP, 96
    
    ; Set focus
    sub     RSP, 32
    mov     RCX, qword [REL hReplaceEdit1]
    call    SetFocus
    add     RSP, 32
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; DialogProc - Window procedure for dialogs
; ============================================================================
extern DefWindowProcA

DialogProc:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 64
    
    mov     qword [RBP + 16], RCX
    mov     qword [RBP + 24], RDX
    mov     qword [RBP + 32], R8
    mov     qword [RBP + 40], R9
    
    cmp     RDX, WM_COMMAND
    je      near .Command
    cmp     RDX, WM_CLOSE
    je      near .Close
    cmp     RDX, WM_KEYDOWN
    je      near .KeyDown
    
.Default:
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    mov     RDX, qword [RBP + 24]
    mov     R8, qword [RBP + 32]
    mov     R9, qword [RBP + 40]
    call    DefWindowProcA
    add     RSP, 32
    
    mov     RSP, RBP
    pop     RBP
    ret

.Command:
    mov     EAX, dword [RBP + 32]
    and     EAX, 0FFFFh
    
    cmp     EAX, IDC_OK_BTN
    je      near .OK
    cmp     EAX, IDC_CANCEL_BTN
    je      near .Cancel
    cmp     EAX, IDC_FINDNEXT_BTN
    je      near .FindNext
    cmp     EAX, IDC_REPLACE_BTN
    je      near .ReplaceOne
    cmp     EAX, IDC_REPLACEALL_BTN
    je      near .ReplaceAll
    
    jmp     .Default

.OK:
    ; Get text and close
    mov     RAX, qword [REL hFindEdit]
    test    RAX, RAX
    jz      .CheckReplace
    
    ; Get find text
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL SearchBuf]
    call    SendMessageA
    add     RSP, 48
    
    call    .CloseDialog
    call    DoFindFirst
    
    test    EAX, EAX
    jnz     .OKDone
    
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL NotFound]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK | MB_ICONINFORMATION
    call    MessageBoxA
    add     RSP, 48
    jmp     .OKDone

.CheckReplace:
    mov     RAX, qword [REL hReplaceEdit1]
    test    RAX, RAX
    jz      .Default
    
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL SearchBuf]
    call    SendMessageA
    add     RSP, 48
    
    mov     RAX, qword [REL hReplaceEdit2]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL ReplaceBuf]
    call    SendMessageA
    add     RSP, 48
    
    call    .CloseDialog
    call    DoFindFirst
    
    test    EAX, EAX
    jnz     .OKDone
    
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL NotFound]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK | MB_ICONINFORMATION
    call    MessageBoxA
    add     RSP, 48

.OKDone:
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.Cancel:
    call    .CloseDialog
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.Close:
    call    .CloseDialog
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyDown:
    mov     EAX, dword [RBP + 32]
    cmp     EAX, VK_ESCAPE
    je      .Cancel
    cmp     EAX, VK_RETURN
    je      .OK
    jmp     .Default

.FindNext:
    mov     RAX, qword [REL hFindEdit]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL SearchBuf]
    call    SendMessageA
    add     RSP, 48
    
    call    DoFindText
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.ReplaceOne:
    mov     RAX, qword [REL hReplaceEdit1]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL SearchBuf]
    call    SendMessageA
    add     RSP, 48
    
    mov     RAX, qword [REL hReplaceEdit2]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL ReplaceBuf]
    call    SendMessageA
    add     RSP, 48
    
    call    DoReplaceText
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.ReplaceAll:
    mov     RAX, qword [REL hReplaceEdit1]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL SearchBuf]
    call    SendMessageA
    add     RSP, 48
    
    mov     RAX, qword [REL hReplaceEdit2]
    sub     RSP, 48
    mov     RCX, RAX
    mov     EDX, 0x0D
    mov     R8D, 256
    lea     R9, [REL ReplaceBuf]
    call    SendMessageA
    add     RSP, 48
    
    call    DoReplaceAll
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; Helper function to close dialog
; Expects: window handle on stack at [RBP + 16] from caller's frame
.CloseDialog:
    push    R12
    push    RBP
    mov     RBP, RSP
    
    ; Get window handle from caller's stack frame
    ; Caller's RBP is at [RBP], caller's [RBP+16] is at [RBP]+16
    mov     R12, qword [RBP]      ; Get caller's RBP
    mov     RCX, qword [R12 + 16] ; Get caller's window handle
    
    sub     RSP, 32
    call    DestroyWindow
    add     RSP, 32
    
    mov     qword [REL hFindDlg], 0
    mov     qword [REL hReplaceDlg], 0
    
    sub     RSP, 32
    mov     RCX, qword [REL hMainWnd]
    mov     EDX, 1
    call    EnableWindow
    add     RSP, 32
    
    mov     RSP, RBP
    pop     RBP
    pop     R12
    ret