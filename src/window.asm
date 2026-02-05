; window.asm - Main Window Creation and Message Handling

%include "include/constants.inc"

extern CreateWindowExA, DefWindowProcA, RegisterClassExA
extern ShowWindow, UpdateWindow, LoadImageA
extern CreateMenu, CreatePopupMenu, AppendMenuA, SetMenu
extern GetClientRect, MoveWindow, GetKeyState, GetAsyncKeyState, SendMessageA
extern MessageBoxA, DestroyWindow, PostQuitMessage
extern hInstance, hEdit, hMainWnd
extern ClassName, WindowName, EditClass
extern MenuFile, MenuEdit, MenuNew, MenuOpen, MenuSave, MenuSaveAs, MenuExit
extern MenuUndo, MenuRedo, MenuCut, MenuCopy, MenuPaste, MenuDelete, MenuSelectAll
extern MenuFind, MenuReplace
extern SavePrompt, WarningTitle, InfoTitle, NotFound
extern FileNew, FileOpen, FileSave, FileSaveAs
extern ShowFindDialog, ShowReplaceDialog
extern EmptyStr

global WndProc, CreateMainWindow

section .text

; ============================================================================
; CreateMainWindow - Register class and create main window
; Returns: Window handle in RAX
; ============================================================================
CreateMainWindow:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 160
    
    ; Fill WNDCLASSEX structure
    mov     dword [RBP - 136], 80
    mov     dword [RBP - 132], CS_HREDRAW | CS_VREDRAW
    lea     RAX, [REL WndProc]
    mov     qword [RBP - 128], RAX
    mov     dword [RBP - 120], 0
    mov     dword [RBP - 116], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RBP - 112], RAX
    
    ; Load icon
    sub     RSP, 48
    xor     ECX, ECX
    mov     EDX, IDI_APPLICATION
    mov     R8D, IMAGE_ICON
    xor     R9D, R9D
    mov     qword [RSP + 32], 0
    mov     qword [RSP + 40], LR_SHARED
    call    LoadImageA
    mov     qword [RBP - 104], RAX
    add     RSP, 48
    
    ; Load cursor
    sub     RSP, 48
    xor     ECX, ECX
    mov     EDX, IDC_ARROW
    mov     R8D, IMAGE_CURSOR
    xor     R9D, R9D
    mov     qword [RSP + 32], 0
    mov     qword [RSP + 40], LR_SHARED
    call    LoadImageA
    mov     qword [RBP - 96], RAX
    add     RSP, 48
    
    mov     qword [RBP - 88], COLOR_WINDOW + 1
    mov     qword [RBP - 80], 0
    lea     RAX, [REL ClassName]
    mov     qword [RBP - 72], RAX
    mov     qword [RBP - 64], 0
    
    ; Register class
    sub     RSP, 32
    lea     RCX, [RBP - 136]
    call    RegisterClassExA
    add     RSP, 32
    
    ; Create window
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL ClassName]
    lea     R8, [REL WindowName]
    mov     R9D, WS_OVERLAPPEDWINDOW
    mov     dword [RSP + 32], CW_USEDEFAULT
    mov     dword [RSP + 40], CW_USEDEFAULT
    mov     dword [RSP + 48], 900
    mov     dword [RSP + 56], 600
    mov     qword [RSP + 64], 0
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hMainWnd], RAX
    add     RSP, 96
    
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WndProc - Main window procedure
; ============================================================================
WndProc:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 64
    
    mov     qword [RBP + 16], RCX
    mov     qword [RBP + 24], RDX
    mov     qword [RBP + 32], R8
    mov     qword [RBP + 40], R9
    
    cmp     RDX, WM_CREATE
    je      near .Create
    cmp     RDX, WM_SIZE
    je      near .Size
    cmp     RDX, WM_COMMAND
    je      near .Command
    cmp     RDX, WM_KEYDOWN
    je      near .KeyDown
    cmp     RDX, WM_CLOSE
    je      near .Close
    cmp     RDX, WM_DESTROY
    je      near .Destroy
    
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

; ============================================================================
; WM_CREATE - Create menu and edit control
; ============================================================================
.Create:
    sub     RSP, 32
    call    CreateMenu
    add     RSP, 32
    mov     R14, RAX
    
    ; Create File menu
    sub     RSP, 32
    call    CreatePopupMenu
    add     RSP, 32
    mov     R15, RAX
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_FILE_NEW
    lea     R9, [REL MenuNew]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_FILE_OPEN
    lea     R9, [REL MenuOpen]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    mov     EDX, 0x800
    xor     R8D, R8D
    xor     R9D, R9D
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_FILE_SAVE
    lea     R9, [REL MenuSave]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_FILE_SAVEAS
    lea     R9, [REL MenuSaveAs]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    mov     EDX, 0x800
    xor     R8D, R8D
    xor     R9D, R9D
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_FILE_EXIT
    lea     R9, [REL MenuExit]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R14
    mov     EDX, 0x10
    mov     R8, R15
    lea     R9, [REL MenuFile]
    call    AppendMenuA
    add     RSP, 48
    
    ; Create Edit menu
    sub     RSP, 32
    call    CreatePopupMenu
    add     RSP, 32
    mov     R15, RAX
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_UNDO
    lea     R9, [REL MenuUndo]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_REDO
    lea     R9, [REL MenuRedo]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    mov     EDX, 0x800
    xor     R8D, R8D
    xor     R9D, R9D
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_CUT
    lea     R9, [REL MenuCut]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_COPY
    lea     R9, [REL MenuCopy]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_PASTE
    lea     R9, [REL MenuPaste]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_DELETE
    lea     R9, [REL MenuDelete]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    mov     EDX, 0x800
    xor     R8D, R8D
    xor     R9D, R9D
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_SELECTALL
    lea     R9, [REL MenuSelectAll]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    mov     EDX, 0x800
    xor     R8D, R8D
    xor     R9D, R9D
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_FIND
    lea     R9, [REL MenuFind]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R15
    xor     EDX, EDX
    mov     R8D, ID_EDIT_REPLACE
    lea     R9, [REL MenuReplace]
    call    AppendMenuA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, R14
    mov     EDX, 0x10
    mov     R8, R15
    lea     R9, [REL MenuEdit]
    call    AppendMenuA
    add     RSP, 48
    
    ; Attach menu
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    mov     RDX, R14
    call    SetMenu
    add     RSP, 32
    
    ; Create edit control
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL EditClass]
    xor     R8D, R8D
    mov     R9D, WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL | ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL | ES_WANTRETURN
    mov     dword [RSP + 32], 0
    mov     dword [RSP + 40], 0
    mov     dword [RSP + 48], 800
    mov     dword [RSP + 56], 550
    mov     RAX, qword [RBP + 16]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hEdit], RAX
    add     RSP, 96
    
    ; Set RichEdit options for plain text mode
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETTEXTMODE
    mov     R8D, 1  ; TM_PLAINTEXT
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Set undo limit to 100 for RichEdit
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETUNDOLIMIT
    mov     R8D, 100
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_SIZE - Resize edit control
; ============================================================================
.Size:
    sub     RSP, 48
    mov     RCX, qword [RBP + 16]
    lea     RDX, [RSP + 32]
    call    GetClientRect
    
    mov     RCX, qword [REL hEdit]
    xor     EDX, EDX
    xor     R8D, R8D
    mov     R9D, dword [RSP + 40]
    mov     EAX, dword [RSP + 44]
    mov     dword [RSP + 32], EAX
    mov     dword [RSP + 40], 1
    call    MoveWindow
    add     RSP, 48
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_KEYDOWN - Handle keyboard shortcuts
; ============================================================================
.KeyDown:
    mov     EAX, dword [RBP + 32]  ; wParam = virtual key code
    
    ; Check for Z key
    cmp     EAX, 'Z'
    jne     .NotZ
    
    ; Check if Ctrl is pressed using GetAsyncKeyState
    sub     RSP, 32
    mov     ECX, VK_CONTROL
    call    GetAsyncKeyState
    add     RSP, 32
    
    ; GetAsyncKeyState returns high bit set if key is down
    test    AX, 8000h
    jz      .NotZ
    
    ; Ctrl is pressed, now check Shift using GetAsyncKeyState
    sub     RSP, 32
    mov     ECX, VK_SHIFT
    call    GetAsyncKeyState
    add     RSP, 32
    
    ; Check bit 15 (0x8000) - if set, Shift key is down
    test    AX, 8000h
    jnz     .KeyRedo
    
    ; Shift NOT pressed - do UNDO
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL MenuUndo]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK
    call    MessageBoxA
    add     RSP, 48
    
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_UNDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyRedo:
    ; Shift IS pressed - show message first
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL MenuRedo]
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK
    call    MessageBoxA
    add     RSP, 48
    
    ; First check if redo is available
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_CANREDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; If CanRedo returns 0, there's nothing to redo
    test    EAX, EAX
    jz      .NoRedo
    
    ; Shift IS pressed and redo is available - do REDO
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.NoRedo:
    ; Nothing to redo - show message
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL NotFound]  ; Borrow "not found" message
    lea     R8, [REL InfoTitle]
    mov     R9D, MB_OK
    call    MessageBoxA
    add     RSP, 48
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.NotZ:
    ; Check if Ctrl is pressed for other shortcuts
    sub     RSP, 32
    mov     ECX, VK_CONTROL
    call    GetKeyState
    add     RSP, 32
    
    test    AX, 8000h
    jz      near .Default
    
    mov     EAX, dword [RBP + 32]
    
    cmp     EAX, 'N'
    je      .KeyNew
    cmp     EAX, 'O'
    je      .KeyOpen
    cmp     EAX, 'S'
    je      .KeySave
    cmp     EAX, 'A'
    je      .KeySelectAll
    cmp     EAX, 'F'
    je      .KeyFind
    cmp     EAX, 'H'
    je      .KeyReplace
    
    jmp     near .Default

.KeyNew:
    call    FileNew
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyOpen:
    call    FileOpen
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeySave:
    call    FileSave
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeySelectAll:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    mov     R9, -1
    call    SendMessageA
    add     RSP, 48
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyFind:
    call    ShowFindDialog
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyReplace:
    call    ShowReplaceDialog
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_COMMAND - Handle menu commands
; ============================================================================
.Command:
    mov     EAX, dword [RBP + 32]
    and     EAX, 0FFFFh
    
    cmp     EAX, ID_FILE_NEW
    je      .CmdNew
    cmp     EAX, ID_FILE_OPEN
    je      .CmdOpen
    cmp     EAX, ID_FILE_SAVE
    je      .CmdSave
    cmp     EAX, ID_FILE_SAVEAS
    je      .CmdSaveAs
    cmp     EAX, ID_FILE_EXIT
    je      .CmdExit
    cmp     EAX, ID_EDIT_UNDO
    je      .CmdUndo
    cmp     EAX, ID_EDIT_REDO
    je      .CmdRedo
    cmp     EAX, ID_EDIT_CUT
    je      .CmdCut
    cmp     EAX, ID_EDIT_COPY
    je      .CmdCopy
    cmp     EAX, ID_EDIT_PASTE
    je      .CmdPaste
    cmp     EAX, ID_EDIT_DELETE
    je      .CmdDelete
    cmp     EAX, ID_EDIT_SELECTALL
    je      .CmdSelectAll
    cmp     EAX, ID_EDIT_FIND
    je      .CmdFind
    cmp     EAX, ID_EDIT_REPLACE
    je      .CmdReplace
    
    jmp     near .Default

.CmdNew:
    call    FileNew
    jmp     .CmdDone
.CmdOpen:
    call    FileOpen
    jmp     .CmdDone
.CmdSave:
    call    FileSave
    jmp     .CmdDone
.CmdSaveAs:
    call    FileSaveAs
    jmp     .CmdDone
.CmdExit:
    sub     RSP, 48
    mov     RCX, qword [RBP + 16]
    mov     EDX, WM_CLOSE
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdUndo:
    ; Just do UNDO - Ctrl+Shift+Z has its own accelerator now
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_UNDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdRedo:
    ; Do REDO
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdCut:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x300
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdCopy:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x301
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdPaste:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x302
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdDelete:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REPLACESEL
    mov     R8D, 1
    lea     R9, [REL EmptyStr]
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdSelectAll:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    mov     R9, -1
    call    SendMessageA
    add     RSP, 48
    jmp     .CmdDone
.CmdFind:
    call    ShowFindDialog
    jmp     .CmdDone
.CmdReplace:
    call    ShowReplaceDialog
    jmp     .CmdDone

.CmdDone:
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_CLOSE - Handle window close with save prompt
; ============================================================================
.Close:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    test    EAX, EAX
    jz      .CloseDestroy
    
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL SavePrompt]
    lea     R8, [REL WarningTitle]
    mov     R9D, MB_YESNOCANCEL | MB_ICONWARNING
    call    MessageBoxA
    add     RSP, 48
    
    cmp     EAX, IDYES
    je      .CloseSave
    cmp     EAX, IDNO
    je      .CloseDestroy
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.CloseSave:
    call    FileSave

.CloseDestroy:
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    call    DestroyWindow
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_DESTROY - Quit application
; ============================================================================
.Destroy:
    sub     RSP, 32
    xor     ECX, ECX
    call    PostQuitMessage
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret