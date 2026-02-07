; data.asm - Data Section (Strings and Resources)

%include "include/constants.inc"

section .data
    global WindowName, ClassName, DialogClassName
    global EditClass, ButtonClass, StaticClass, StatusBarClass
    global RichEditLib
    global RichEditLib, Shell32Lib
    
    WindowName      db "TadWin", 0
    ClassName       db "TadWinClass", 0
    DialogClassName db "TadWinDialog", 0
    EditClass       db "RichEdit20A", 0  ; RichEdit ANSI version
    ButtonClass     db "BUTTON", 0
    StaticClass     db "STATIC", 0
    StatusBarClass  db "msctls_statusbar32", 0
    RichEditLib     db "Riched20.dll", 0
    Shell32Lib      db "Shell32.dll", 0
    
    ; Title strings
    global UntitledTitle, TitleSeparator, ModifiedMarker
    UntitledTitle   db "Untitled - TadWin", 0
    TitleSeparator  db " - TadWin", 0
    ModifiedMarker  db "*", 0
    
    ; Status bar format strings
    global StatusLineCol, StatusLines
    StatusLineCol   db "Ln %d, Col %d", 0
    StatusLines     db "Lines: %d", 0
    
    ; Menu Strings
    global MenuFile, MenuEdit, MenuNew, MenuOpen, MenuSave, MenuSaveAs, MenuExit
    global MenuUndo, MenuRedo, MenuCut, MenuCopy, MenuPaste, MenuDelete, MenuSelectAll
    global MenuFind, MenuReplace
    
    MenuFile        db "&File", 0
    MenuEdit        db "&Edit", 0
    MenuNew         db "&New", 9, "Ctrl+N", 0
    MenuOpen        db "&Open...", 9, "Ctrl+O", 0
    MenuSave        db "&Save", 9, "Ctrl+S", 0
    MenuSaveAs      db "Save &As...", 0
    MenuExit        db "E&xit", 0
    
    MenuUndo        db "&Undo", 9, "Ctrl+Z", 0
    MenuRedo        db "&Redo", 9, "Ctrl+Shift+Z", 0
    MenuCut         db "Cu&t", 9, "Ctrl+X", 0
    MenuCopy        db "&Copy", 9, "Ctrl+C", 0
    MenuPaste       db "&Paste", 9, "Ctrl+V", 0
    MenuDelete      db "&Delete", 0
    MenuSelectAll   db "Select &All", 9, "Ctrl+A", 0
    MenuFind        db "&Find...", 9, "Ctrl+F", 0
    MenuReplace     db "&Replace...", 9, "Ctrl+H", 0
    
    ; File Dialog Strings
    global FileFilter, SaveTitle, OpenTitle, FindTitle, ReplaceTitle
    
    FileFilter      db "Text Files (*.txt)", 0, "*.txt", 0
                    db "All Files (*.*)", 0, "*.*", 0, 0
    SaveTitle       db "Save As", 0
    OpenTitle       db "Open File", 0
    FindTitle       db "Find", 0
    ReplaceTitle    db "Replace", 0
    
    ; Message Strings
    global ErrorTitle, InfoTitle, WarningTitle
    global ErrorRead, ErrorWrite, NotFound, ReplaceSuccessMsg, SavePrompt
    
    ErrorTitle      db "Error", 0
    InfoTitle       db "Information", 0
    WarningTitle    db "Warning", 0
    ErrorRead       db "Could not read file!", 0
    ErrorWrite      db "Could not save file!", 0
    NotFound        db "Text not found.", 0
    ReplaceSuccessMsg db "Text replaced successfully!", 0
    SavePrompt      db "Save changes?", 0
    
    ; Dialog Labels
    global LabelFind, LabelReplace
    global BtnFindNext, BtnReplace, BtnReplaceAll, BtnCancel, BtnOK
    global EmptyStr
    
    LabelFind       db "Find what:", 0
    LabelReplace    db "Replace with:", 0
    BtnFindNext     db "Find Next", 0
    BtnReplace      db "Replace", 0
    BtnReplaceAll   db "Replace All", 0
    BtnCancel       db "Cancel", 0
    BtnOK           db "OK", 0
    
    EmptyStr        db 0

section .data
    ; Accelerator table for keyboard shortcuts
    ; Structure: ACCEL { BYTE fVirt, WORD key, WORD cmd }
    align 4
    global AccelTable, AccelCount
    
AccelTable:
    ; Ctrl+N - New
    db 0x09, 0          ; FVIRTKEY | FCONTROL
    dw 'N'
    dw ID_FILE_NEW
    
    ; Ctrl+O - Open
    db 0x09, 0
    dw 'O'
    dw ID_FILE_OPEN
    
    ; Ctrl+S - Save
    db 0x09, 0
    dw 'S'
    dw ID_FILE_SAVE
    
    ; Ctrl+Z - Undo
    db 0x09, 0          ; FVIRTKEY | FCONTROL
    dw 'Z'
    dw ID_EDIT_UNDO
    
    ; Ctrl+Shift+Z - Redo
    db 0x0D, 0          ; FVIRTKEY | FCONTROL | FSHIFT
    dw 'Z'
    dw ID_EDIT_REDO
    
    ; Ctrl+A - Select All
    db 0x09, 0
    dw 'A'
    dw ID_EDIT_SELECTALL
    
    ; Ctrl+F - Find
    db 0x09, 0
    dw 'F'
    dw ID_EDIT_FIND
    
    ; Ctrl+H - Replace
    db 0x09, 0
    dw 'H'
    dw ID_EDIT_REPLACE

AccelCount dd 8

section .bss
    alignb 8
    global hInstance, hEdit, hMainWnd, hFindDlg, hReplaceDlg, hStatusBar
    global hFindEdit, hReplaceEdit1, hReplaceEdit2
    global CurrentFile, FileBuffer, SearchBuf, ReplaceBuf
    global hAccel
    global TitleBuffer, StatusBuffer
    
    hInstance       resq 1
    hEdit           resq 1
    hMainWnd        resq 1
    hFindDlg        resq 1
    hReplaceDlg     resq 1
    hFindEdit       resq 1
    hReplaceEdit1   resq 1
    hReplaceEdit2   resq 1
    hAccel          resq 1
    hStatusBar      resq 1
    CurrentFile     resb 260
    FileBuffer      resb 1048576
    SearchBuf       resb 256
    ReplaceBuf      resb 256
    TitleBuffer     resb 512
    StatusBuffer    resb 256