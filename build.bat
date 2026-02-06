@echo off
cls
echo ================================================
echo   MODULAR TadWin BUILD SCRIPT
echo ================================================
echo.

:: Kill any running instances
taskkill /F /IM TadWin.exe 2>nul >nul

:: Clean previous build
if exist build\*.obj del /Q build\*.obj 2>nul
if exist TadWin.exe del /Q TadWin.exe 2>nul

echo Assembling modules...
echo.

:: Assemble each module
echo [1/7] Assembling data.asm...
nasm -f win64 -Iinclude src\data.asm -o build\data.obj
if %errorlevel% neq 0 goto :error

echo [2/7] Assembling file_ops.asm...
nasm -f win64 -Iinclude src\file_ops.asm -o build\file_ops.obj
if %errorlevel% neq 0 goto :error

echo [3/7] Assembling search_replace.asm...
nasm -f win64 -Iinclude src\search_replace.asm -o build\search_replace.obj
if %errorlevel% neq 0 goto :error

echo [4/7] Assembling dialogs.asm...
nasm -f win64 -Iinclude src\dialogs.asm -o build\dialogs.obj
if %errorlevel% neq 0 goto :error

echo [5/7] Assembling window.asm...
nasm -f win64 -Iinclude src\window.asm -o build\window.obj
if %errorlevel% neq 0 goto :error

echo [6/7] Assembling main.asm...
nasm -f win64 -Iinclude src\main.asm -o build\main.obj
if %errorlevel% neq 0 goto :error

echo.
echo [7/7] Linking TadWin.exe...
gcc -nostartfiles -mwindows ^
    build\main.obj ^
    build\window.obj ^
    build\file_ops.obj ^
    build\search_replace.obj ^
    build\dialogs.obj ^
    build\data.obj ^
    -o TadWin.exe ^
    -luser32 -lkernel32 -lcomdlg32 -lgdi32 -lshell32 ^
    -Wl,--entry=Start

if %errorlevel% neq 0 goto :error

echo.
echo ================================================
echo          BUILD SUCCESSFUL!
echo ================================================
echo.
echo MODULES COMPILED:
echo   - main.asm           (Entry point)
echo   - window.asm         (Window management)
echo   - file_ops.asm       (File operations)
echo   - search_replace.asm (Find/Replace)
echo   - dialogs.asm        (Dialog windows)
echo   - data.asm           (Global data)
echo.
echo OUTPUT: TadWin.exe
echo.
echo ================================================
echo.
pause
TadWin.exe
exit /b 0

:error
echo.
echo ================================================
echo          BUILD FAILED!
echo ================================================
echo Check errors above
echo.
pause
exit /b 1
