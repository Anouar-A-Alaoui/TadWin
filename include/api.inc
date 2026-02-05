; api.inc - Windows API External Declarations

; Window Management
extern CreateWindowExA
extern DefWindowProcA
extern DispatchMessageA
extern ExitProcess
extern GetMessageA
extern GetModuleHandleA
extern LoadImageA
extern LoadLibraryA
extern PostQuitMessage
extern RegisterClassExA
extern ShowWindow
extern TranslateMessage
extern UpdateWindow
extern DestroyWindow

; Menu APIs
extern CreateMenu
extern CreatePopupMenu
extern AppendMenuA
extern SetMenu

; Window Helper Functions
extern GetClientRect
extern MoveWindow
extern SetFocus
extern EnableWindow
extern IsWindow

; Message Box
extern MessageBoxA

; Edit Control Messages
extern SendMessageA
extern SendDlgItemMessageA

; File I/O
extern CreateFileA
extern WriteFile
extern ReadFile
extern CloseHandle
extern GetFileSize

; File Dialogs
extern GetOpenFileNameA
extern GetSaveFileNameA

; Keyboard
extern GetKeyState
extern GetAsyncKeyState

; String Functions
extern lstrlenA

; Accelerator Functions
extern CreateAcceleratorTableA
extern TranslateAcceleratorA
