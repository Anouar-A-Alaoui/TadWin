; file_ops.asm - File Operations (Open, Save, New)

%include "include/constants.inc"

extern CreateFileA, WriteFile, ReadFile, CloseHandle
extern GetOpenFileNameA, GetSaveFileNameA
extern MessageBoxA, SendMessageA, GetFileSize, lstrlenA
extern hInstance, hEdit, hMainWnd, CurrentFile, FileBuffer
extern EmptyStr, FileFilter, SaveTitle, OpenTitle
extern ErrorRead, ErrorWrite, ErrorTitle
extern UpdateWindowTitle

global FileNew, FileOpen, FileSave, FileSaveAs, SaveToFile, FileOpenByPath

section .text

; ============================================================================
; FileNew - Clear editor and reset current file
; ============================================================================
FileNew:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 48
    
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0C
    xor     R8D, R8D
    lea     R9, [REL EmptyStr]
    call    SendMessageA
    
    mov     byte [REL CurrentFile], 0
    
    ; Clear modified flag
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    
    ; Empty undo buffer to start fresh
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_EMPTYUNDOBUFFER
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    
    ; Update window title
    sub     RSP, 32
    call    UpdateWindowTitle
    add     RSP, 32
    
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; FileOpen - Show Open dialog and load file
; ============================================================================
FileOpen:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 192
    
    mov     byte [REL CurrentFile], 0
    
    ; Zero OPENFILENAME structure
    lea     RDI, [RBP - 152]
    mov     ECX, 152
    xor     EAX, EAX
    rep stosb
    
    ; Fill structure
    mov     dword [RBP - 152], 152
    mov     RAX, qword [REL hMainWnd]
    mov     qword [RBP - 144], RAX
    mov     qword [RBP - 136], 0
    lea     RAX, [REL FileFilter]
    mov     qword [RBP - 128], RAX
    mov     qword [RBP - 120], 0
    mov     dword [RBP - 112], 0
    mov     dword [RBP - 108], 1
    lea     RAX, [REL CurrentFile]
    mov     qword [RBP - 104], RAX
    mov     dword [RBP - 96], 260
    mov     qword [RBP - 88], 0
    mov     dword [RBP - 80], 0
    mov     qword [RBP - 72], 0
    lea     RAX, [REL OpenTitle]
    mov     qword [RBP - 64], RAX
    mov     dword [RBP - 56], OFN_FILEMUSTEXIST | OFN_PATHMUSTEXIST
    
    ; Call dialog
    sub     RSP, 32
    lea     RCX, [RBP - 152]
    call    GetOpenFileNameA
    add     RSP, 32
    
    test    EAX, EAX
    jz      near .Done
    
    ; Open file
    sub     RSP, 64
    lea     RCX, [REL CurrentFile]
    mov     EDX, GENERIC_READ
    xor     R8D, R8D
    xor     R9D, R9D
    mov     dword [RSP + 32], OPEN_EXISTING
    mov     dword [RSP + 40], FILE_ATTRIBUTE_NORMAL
    mov     qword [RSP + 48], 0
    call    CreateFileA
    add     RSP, 64
    
    cmp     RAX, -1
    je      near .Error
    
    mov     R12, RAX
    
    ; Get file size
    sub     RSP, 32
    mov     RCX, R12
    xor     EDX, EDX
    call    GetFileSize
    add     RSP, 32
    
    cmp     EAX, -1
    je      near .Close
    
    mov     R13D, EAX
    
    ; Read file
    sub     RSP, 48
    mov     RCX, R12
    lea     RDX, [REL FileBuffer]
    mov     R8D, R13D
    lea     R9, [RBP - 160]
    mov     qword [RSP + 32], 0
    call    ReadFile
    add     RSP, 48
    
    ; Null terminate
    lea     RAX, [REL FileBuffer]
    add     RAX, R13
    mov     byte [RAX], 0
    
    ; Set text in editor
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0C
    xor     R8D, R8D
    lea     R9, [REL FileBuffer]
    call    SendMessageA
    add     RSP, 48
    
    ; Clear modified flag
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Empty undo buffer - fresh start after loading file
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_EMPTYUNDOBUFFER
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Update window title
    sub     RSP, 32
    call    UpdateWindowTitle
    add     RSP, 32
    
.Close:
    sub     RSP, 32
    mov     RCX, R12
    call    CloseHandle
    add     RSP, 32
    jmp     near .Done
    
.Error:
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL ErrorRead]
    lea     R8, [REL ErrorTitle]
    mov     R9D, MB_OK | MB_ICONERROR
    call    MessageBoxA
    add     RSP, 48
    mov     byte [REL CurrentFile], 0
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; FileOpenByPath - Open file by path (for drag-drop) - CLEAN VERSION
; ============================================================================
FileOpenByPath:
    push    RBP
    mov     RBP, RSP
    push    R12
    push    R13
    push    R14
    push    RSI
    push    RDI
    sub     RSP, 72          ; 6 pushes = 48 bytes, need +8 for alignment = 72
    
    ; Save filename pointer
    mov     R14, RCX
    
    ; Copy filename to CurrentFile
    mov     RSI, R14
    lea     RDI, [REL CurrentFile]
    xor     ECX, ECX
    
.CopyLoop:
    mov     AL, byte [RSI + RCX]
    mov     byte [RDI + RCX], AL
    test    AL, AL
    jz      .CopyDone
    inc     ECX
    cmp     ECX, 259
    jge     .CopyDone
    jmp     .CopyLoop
    
.CopyDone:
    mov     byte [RDI + RCX], 0
    
    ; Open file
    sub     RSP, 64
    lea     RCX, [REL CurrentFile]
    mov     EDX, GENERIC_READ
    xor     R8D, R8D
    xor     R9D, R9D
    mov     dword [RSP + 32], OPEN_EXISTING
    mov     dword [RSP + 40], FILE_ATTRIBUTE_NORMAL
    mov     qword [RSP + 48], 0
    call    CreateFileA
    add     RSP, 64
    
    cmp     RAX, -1
    je      near .Error
    
    mov     R12, RAX
    
    ; Get file size
    sub     RSP, 32
    mov     RCX, R12
    xor     EDX, EDX
    call    GetFileSize
    add     RSP, 32
    
    cmp     EAX, -1
    je      near .Close
    
    mov     R13D, EAX
    
    ; Read file
    sub     RSP, 48
    mov     RCX, R12
    lea     RDX, [REL FileBuffer]
    mov     R8D, R13D
    lea     R9, [RBP - 8]
    mov     qword [RSP + 32], 0
    call    ReadFile
    add     RSP, 48
    
    ; Null terminate
    lea     RAX, [REL FileBuffer]
    add     RAX, R13
    mov     byte [RAX], 0
    
    ; Set text in editor
    sub     RSP, 32
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0C
    xor     R8D, R8D
    lea     R9, [REL FileBuffer]
    call    SendMessageA
    add     RSP, 32
    
    ; Clear modified flag
    sub     RSP, 32
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 32
    
    ; Empty undo buffer
    sub     RSP, 32
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_EMPTYUNDOBUFFER
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 32
    
    ; Update window title
    sub     RSP, 32
    call    UpdateWindowTitle
    add     RSP, 32
    
.Close:
    sub     RSP, 32
    mov     RCX, R12
    call    CloseHandle
    add     RSP, 32
    jmp     near .FileOpenDone
    
.Error:
    sub     RSP, 32
    xor     ECX, ECX
    lea     RDX, [REL ErrorRead]
    lea     R8, [REL ErrorTitle]
    mov     R9D, MB_OK | MB_ICONERROR
    call    MessageBoxA
    add     RSP, 32
    
.FileOpenDone:
    add     RSP, 72
    pop     RDI
    pop     RSI
    pop     R14
    pop     R13
    pop     R12
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; FileSave - Save current file (or call SaveAs if no filename)
; ============================================================================
FileSave:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 32
    
    cmp     byte [REL CurrentFile], 0
    je      near .SaveAs
    
    call    SaveToFile
    jmp     near .Done
    
.SaveAs:
    call    FileSaveAs
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; FileSaveAs - Show Save As dialog and save file
; ============================================================================
FileSaveAs:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 192
    
    ; Zero structure
    lea     RDI, [RBP - 152]
    mov     ECX, 152
    xor     EAX, EAX
    rep stosb
    
    ; Fill structure
    mov     dword [RBP - 152], 152
    mov     RAX, qword [REL hMainWnd]
    mov     qword [RBP - 144], RAX
    mov     qword [RBP - 136], 0
    lea     RAX, [REL FileFilter]
    mov     qword [RBP - 128], RAX
    mov     qword [RBP - 120], 0
    mov     dword [RBP - 112], 0
    mov     dword [RBP - 108], 1
    lea     RAX, [REL CurrentFile]
    mov     qword [RBP - 104], RAX
    mov     dword [RBP - 96], 260
    mov     qword [RBP - 88], 0
    mov     dword [RBP - 80], 0
    mov     qword [RBP - 72], 0
    lea     RAX, [REL SaveTitle]
    mov     qword [RBP - 64], RAX
    mov     dword [RBP - 56], OFN_OVERWRITEPROMPT | OFN_HIDEREADONLY
    
    ; Call dialog
    sub     RSP, 32
    lea     RCX, [RBP - 152]
    call    GetSaveFileNameA
    add     RSP, 32
    
    test    EAX, EAX
    jz      near .Done
    
    call    SaveToFile
    
    ; Update window title with new filename
    sub     RSP, 32
    call    UpdateWindowTitle
    add     RSP, 32
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret

; ============================================================================
; SaveToFile - Actually write file to disk
; ============================================================================
SaveToFile:
    push    RBP
    mov     RBP, RSP
    sub     RSP, 64
    
    ; Get text length
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0E
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    mov     R13D, EAX
    
    ; Get text
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, 0x0D
    mov     R8D, R13D
    inc     R8D
    lea     R9, [REL FileBuffer]
    call    SendMessageA
    add     RSP, 48
    
    ; Create file
    sub     RSP, 64
    lea     RCX, [REL CurrentFile]
    mov     EDX, GENERIC_WRITE
    xor     R8D, R8D
    xor     R9D, R9D
    mov     dword [RSP + 32], CREATE_ALWAYS
    mov     dword [RSP + 40], FILE_ATTRIBUTE_NORMAL
    mov     qword [RSP + 48], 0
    call    CreateFileA
    add     RSP, 64
    
    cmp     RAX, -1
    je      near .Error
    
    mov     R12, RAX
    
    ; Write file
    sub     RSP, 48
    mov     RCX, R12
    lea     RDX, [REL FileBuffer]
    mov     R8D, R13D
    lea     R9, [RBP - 8]
    mov     qword [RSP + 32], 0
    call    WriteFile
    add     RSP, 48
    
    ; Close file
    sub     RSP, 32
    mov     RCX, R12
    call    CloseHandle
    add     RSP, 32
    
    ; Clear modified flag
    sub     RSP, 48
    mov     RCX, qword [REL hEdit]
    mov     EDX, EM_SETMODIFY
    xor     R8D, R8D
    xor     R9D, R9D
    call    SendMessageA
    add     RSP, 48
    
    ; Update window title (remove asterisk)
    sub     RSP, 32
    call    UpdateWindowTitle
    add     RSP, 32
    
    jmp     near .Done
    
.Error:
    sub     RSP, 48
    xor     ECX, ECX
    lea     RDX, [REL ErrorWrite]
    lea     R8, [REL ErrorTitle]
    mov     R9D, MB_OK | MB_ICONERROR
    call    MessageBoxA
    add     RSP, 48
    
.Done:
    mov     RSP, RBP
    pop     RBP
    ret
