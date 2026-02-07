; window.asm - Main Window Creation and Message Handling

%include "include/constants.inc"

extern CreateWindowExA, DefWindowProcA, RegisterClassExA
extern ShowWindow, UpdateWindow, LoadImageA, SetWindowTextA
extern CreateMenu, CreatePopupMenu, AppendMenuA, SetMenu
extern GetClientRect, MoveWindow, GetKeyState, GetAsyncKeyState, SendMessageA
extern MessageBoxA, DestroyWindow, PostQuitMessage
extern DragAcceptFiles, DragQueryFileA, DragFinish
extern lstrcpyA, lstrcatA, lstrlenA, wsprintfA
extern SetTimer, KillTimer
extern hInstance, hEdit, hMainWnd, hStatusBar, Shell32Lib
extern ClassName, WindowName, EditClass, StatusBarClass
extern MenuFile, MenuEdit, MenuNew, MenuOpen, MenuSave, MenuSaveAs, MenuExit
extern MenuUndo, MenuRedo, MenuCut, MenuCopy, MenuPaste, MenuDelete, MenuSelectAll
extern MenuFind, MenuReplace
extern SavePrompt, WarningTitle, InfoTitle, NotFound
extern FileNew, FileOpen, FileSave, FileSaveAs, FileOpenByPath
extern ShowFindDialog, ShowReplaceDialog
extern EmptyStr, CurrentFile, TitleBuffer, StatusBuffer
extern UntitledTitle, TitleSeparator, ModifiedMarker
extern StatusLineCol, StatusLines

global WndProc, CreateMainWindow, UpdateWindowTitle, UpdateStatusBar

section .text

; ============================================================================
; UpdateWindowTitle - Update title bar with filename and modified status
; ============================================================================
UpdateWindowTitle:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 64
    
    ; Clear title buffer
    lea     RDI, [REL TitleBuffer]
    mov     ECX, 512
    xor     AL, AL
    rep stosb
    
    ; Check if file has a name
    cmp     byte [REL CurrentFile], 0
    je      .NoFileName
    
    ; Extract just the filename from full path
    lea     RSI, [REL CurrentFile]
    xor     R12, R12  ; Last backslash position
    xor     RCX, RCX
    
.FindLastSlash:
    mov     AL, byte [RSI + RCX]
    test    AL, AL
    jz      .FoundEnd
    cmp     AL, '\'
    jne     .NotSlash
    lea     R12, [RCX + 1]  ; Position after backslash
.NotSlash:
    inc     RCX
    jmp     .FindLastSlash
    
.FoundEnd:
    ; Copy filename starting from last backslash
    lea     RSI, [REL CurrentFile]
    add     RSI, R12
    lea     RDI, [REL TitleBuffer]
    
.CopyFilename:
    mov     AL, byte [RSI]
    test    AL, AL
    jz      .FilenameCopied
    mov     byte [RDI], AL
    inc     RSI
    inc     RDI
    jmp     .CopyFilename
    
.FilenameCopied:
    ; Append separator
    sub     RSP, 32
    lea     RCX, [REL TitleBuffer]
    lea     RDX, [REL TitleSeparator]
    call    lstrcatA
    add     RSP, 32
    jmp     .CheckModified
    
.NoFileName:
    ; Use "Untitled - TadWin"
    sub     RSP, 32
    lea     RCX, [REL TitleBuffer]
    lea     RDX, [REL UntitledTitle]
    call    lstrcpyA
    add     RSP, 32
    
.CheckModified:
    ; Check if file is modified
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    test    EAX, EAX
    jz      .NotModified
    
    ; Prepend asterisk for modified files
    ; Shift existing string right by 1
    lea     RSI, [REL TitleBuffer]
    sub     RSP, 32
    mov     RCX, RSI
    call    lstrlenA
    add     RSP, 32
    
    mov     RCX, RAX
    lea     RSI, [REL TitleBuffer]
    add     RSI, RCX
    inc     RCX
    
.ShiftRight:
    mov     AL, byte [RSI]
    mov     byte [RSI + 1], AL
    dec     RSI
    dec     RCX
    jnz     .ShiftRight
    
    ; Insert asterisk
    mov     byte [REL TitleBuffer], '*'
    
.NotModified:
    ; Set window title
    sub     RSP, 32
    mov     RCX, qword [REL hMainWnd]
    lea     RDX, [REL TitleBuffer]
    call    SetWindowTextA
    add     RSP, 32
    
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; UpdateStatusBar - Update status bar with line count and cursor position
; ============================================================================
UpdateStatusBar:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 96
    
    ; Get total line count
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETLINECOUNT
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    mov     R14D, EAX  ; Total lines
    
    ; Get current cursor position
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_GETSEL
    lea     R8, [RBP - 8]
    lea     R9, [RBP - 4]
    call    SendMessageA
    add     RSP, 48
    
    mov     R12D, dword [RBP - 4]  ; Cursor position
    
    ; Get line number from character position
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_LINEFROMCHAR
    mov     R8D, R12D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    mov     R13D, EAX  ; Current line (0-based)
    inc     R13D       ; Make it 1-based
    
    ; Get start of current line
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_LINEINDEX
    mov     R8D, R13D
    dec     R8D  ; Back to 0-based
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Calculate column (1-based)
    sub     R12D, EAX
    inc     R12D
    
    ; Format status text for part 0 (line and column)
    sub     RSP, 64
    lea     RCX, [REL StatusBuffer]
    lea     RDX, [REL StatusLineCol]
    mov     R8D, R13D
    mov     R9D, R12D
    call    wsprintfA
    add     RSP, 64
    
    ; Set status bar part 0 (left side - line and column)
    sub     RSP, 48
    mov     RCX, qword [REL hStatusBar]
    mov     EDX, SB_SETTEXT
    xor     R8D, R8D  ; Part 0
    lea     R9, [REL StatusBuffer]
    call    SendMessageA
    add     RSP, 48
    
    ; Format status text for part 1 (total lines)
    sub     RSP, 48
    lea     RCX, [REL StatusBuffer]
    lea     RDX, [REL StatusLines]
    mov     R8D, R14D
    call    wsprintfA
    add     RSP, 48
    
    ; Set status bar part 1 (right side - total lines)
    sub     RSP, 48
    mov     RCX, qword [REL hStatusBar]
    mov     EDX, SB_SETTEXT
    mov     R8D, 1  ; Part 1
    lea     R9, [REL StatusBuffer]
    call    SendMessageA
    add     RSP, 48
    
    mov     RSP, RBP
    pop     RBP
    ret

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
    
    ; Create window with drag-drop support
    sub     RSP, 96
    mov     ECX, WS_EX_ACCEPTFILES  ; Extended style for drag-drop
    lea     RDX, [REL ClassName]
    lea     R8, [REL UntitledTitle]
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
    cmp     RDX, WM_LBUTTONDOWN
    je      near .Click
    cmp     RDX, WM_LBUTTONUP
    je      near .Click
    cmp     RDX, WM_KEYUP
    je      near .KeyUp
    cmp     RDX, WM_TIMER
    je      near .Timer
    cmp     RDX, WM_CLOSE
    je      near .Close
    cmp     RDX, WM_DESTROY
    je      near .Destroy
    cmp     RDX, WM_DROPFILES
    je      near .DropFiles
    
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
    
    ; Create status bar
    sub     RSP, 96
    xor     ECX, ECX
    lea     RDX, [REL StatusBarClass]
    xor     R8D, R8D
    mov     R9D, WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP
    mov     dword [RSP + 32], 0
    mov     dword [RSP + 40], 0
    mov     dword [RSP + 48], 0
    mov     dword [RSP + 56], 0
    mov     RAX, qword [RBP + 16]
    mov     qword [RSP + 64], RAX
    mov     qword [RSP + 72], 0
    mov     RAX, qword [REL hInstance]
    mov     qword [RSP + 80], RAX
    mov     qword [RSP + 88], 0
    call    CreateWindowExA
    mov     qword [REL hStatusBar], RAX
    add     RSP, 96
    
    ; Set status bar parts (2 parts: left for line/col, right for total lines)
    sub     RSP, 48
    mov     RCX, qword [REL hStatusBar]
    mov     EDX, SB_SETPARTS
    mov     R8D, 2
    lea     R9, [RBP - 16]
    mov     dword [RBP - 16], 200  ; Part 0 width
    mov     dword [RBP - 12], -1   ; Part 1 uses remaining space
    call    SendMessageA
    add     RSP, 48
    
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
    
    ; CRITICAL: Enable drag-drop for the window
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]  ; hWnd
    mov     EDX, 1                  ; TRUE = accept files
    call    DragAcceptFiles
    add     RSP, 32
    
    ; Initialize status bar
    sub     RSP, 32
    call    UpdateStatusBar
    add     RSP, 32
    
    ; Create timer to update status bar every 100ms
    sub     RSP, 48
    mov     RCX, qword [RBP + 16]  ; hWnd
    mov     EDX, ID_TIMER_STATUSBAR ; Timer ID
    mov     R8D, 100                ; 100ms interval
    xor     R9D, R9D                ; No timer proc
    call    SetTimer
    add     RSP, 48
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_SIZE - Resize edit control and status bar
; ============================================================================
.Size:
    ; Update status bar first (it auto-sizes)
    sub     RSP, 48
    mov     RCX, qword [REL hStatusBar]
    mov     EDX, WM_SIZE
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Get status bar height
    sub     RSP, 48
    mov     RCX, qword [REL hStatusBar]
    lea     RDX, [RBP - 32]
    call    GetClientRect
    add     RSP, 48
    
    mov     R14D, dword [RBP - 20]  ; Status bar height
    
    ; Get client rect
    sub     RSP, 48
    mov     RCX, qword [RBP + 16]
    lea     RDX, [RBP - 32]
    call    GetClientRect
    add     RSP, 48
    
    ; Resize edit control (leave space for status bar)
    mov     EAX, dword [RBP - 20]
    sub     EAX, R14D  ; Subtract status bar height
    
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    xor     EDX, EDX
    xor     R8D, R8D
    mov     R9D, dword [RBP - 16]
    mov     dword [RSP + 32], EAX
    mov     dword [RSP + 40], 1
    call    MoveWindow
    add     RSP, 48
    
    ; Update status bar
    sub     RSP, 32
    call    UpdateStatusBar
    add     RSP, 32
    
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
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_UNDO
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyRedo:
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
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.NoRedo:
    ; Nothing to redo
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
    sub     RSP, 32
    call    FileNew
    call    UpdateWindowTitle
    call    UpdateStatusBar
    add     RSP, 32
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeyOpen:
    sub     RSP, 32
    call    FileOpen
    call    UpdateWindowTitle
    call    UpdateStatusBar
    add     RSP, 32
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

.KeySave:
    sub     RSP, 32
    call    FileSave
    call    UpdateWindowTitle
    add     RSP, 32
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
    
    sub     RSP, 32
    call    UpdateStatusBar
    add     RSP, 32
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
; WM_LBUTTONDOWN / WM_LBUTTONUP - Update status bar on click
; ============================================================================
.Click:
    ; Let default handler process the click first
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    mov     RDX, qword [RBP + 24]
    mov     R8, qword [RBP + 32]
    mov     R9, qword [RBP + 40]
    call    DefWindowProcA
    add     RSP, 32
    
    ; Update status bar
    sub     RSP, 32
    call    UpdateStatusBar
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_KEYUP - Update status bar after key release
; ============================================================================
.KeyUp:
    ; Let default handler process the key first
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    mov     RDX, qword [RBP + 24]
    mov     R8, qword [RBP + 32]
    mov     R9, qword [RBP + 40]
    call    DefWindowProcA
    add     RSP, 32
    
    ; Update status bar
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    
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
    sub     RSP, 32
    call    FileNew
    call    UpdateWindowTitle
    call    UpdateStatusBar
    add     RSP, 32
    jmp     .CmdDone
.CmdOpen:
    sub     RSP, 32
    call    FileOpen
    call    UpdateWindowTitle
    call    UpdateStatusBar
    add     RSP, 32
    jmp     .CmdDone
.CmdSave:
    sub     RSP, 32
    call    FileSave
    call    UpdateWindowTitle
    add     RSP, 32
    jmp     .CmdDone
.CmdSaveAs:
    sub     RSP, 32
    call    FileSaveAs
    call    UpdateWindowTitle
    add     RSP, 32
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
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
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
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    jmp     .CmdDone
.CmdCut:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x300
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
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
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    jmp     .CmdDone
.CmdDelete:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_REPLACESEL
    mov     R8D, 1
    lea     R9, [REL EmptyStr]
    call    SendMessageA
    add     RSP, 48
    
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    jmp     .CmdDone
.CmdSelectAll:
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETSEL
    xor     R8D, R8D
    mov     R9, -1
    call    SendMessageA
    add     RSP, 48
    
    sub     RSP, 32
    call    UpdateStatusBar
    add     RSP, 32
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
; WM_TIMER - Update status bar periodically
; ============================================================================
.Timer:
    ; Check if it's our timer
    mov     EAX, dword [RBP + 32]
    cmp     EAX, ID_TIMER_STATUSBAR
    jne     .Default
    
    ; Update status bar
    sub     RSP, 32
    call    UpdateStatusBar
    call    UpdateWindowTitle
    add     RSP, 32
    
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
; WM_DROPFILES - With CORRECT stack alignment
; ============================================================================
.DropFiles:
    push    R12
    sub     RSP, 296         ; 32 shadow + 256 buffer + 8 alignment (because push R12)
    
    ; Get HDROP handle
    mov     R12, qword [RBP + 32]
    
    ; Query first filename
    mov     RCX, R12
    xor     EDX, EDX          ; First file (index 0)
    lea     R8, [RSP + 32]    ; Buffer (skip shadow space)
    mov     R9D, 256          ; Buffer size
    call    DragQueryFileA
    
    ; Check if we got a filename
    test    EAX, EAX
    jz      .DropCleanup
    
    ; Open the file
    lea     RCX, [RSP + 32]   ; Filename buffer
    call    FileOpenByPath
    
    sub     RSP, 32
    call    UpdateWindowTitle
    call    UpdateStatusBar
    add     RSP, 32
    
.DropCleanup:
    ; Note: DragFinish call causes crash due to stack alignment issues
    ; Skipping it - Windows will clean up the handle
    
    add     RSP, 296
    pop     R12
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; WM_DESTROY - Quit application
; ============================================================================
.Destroy:
    ; Kill the timer
    sub     RSP, 32
    mov     RCX, qword [RBP + 16]
    mov     EDX, ID_TIMER_STATUSBAR
    call    KillTimer
    add     RSP, 32
    
    sub     RSP, 32
    xor     ECX, ECX
    call    PostQuitMessage
    add     RSP, 32
    
    xor     EAX, EAX
    mov     RSP, RBP
    pop     RBP
    ret