@echo off
cls
echo ================================================
echo   TadWin BUILD WITH DEBUG OUTPUT
echo ================================================
echo.
echo This script will show you exactly what's happening
echo.

:: Check if NASM exists
where nasm >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] NASM not found in PATH!
    echo Please install NASM and add it to PATH
    echo Download from: https://www.nasm.us/
    pause
    exit /b 1
)

:: Check if GCC exists
where gcc >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] GCC not found in PATH!
    echo Please install MinGW-w64 and add it to PATH
    pause
    exit /b 1
)

echo [OK] NASM found: 
nasm -v
echo.
echo [OK] GCC found:
gcc --version | findstr gcc
echo.

:: Kill any running instances
echo Killing any running TadWin.exe...
taskkill /F /IM TadWin.exe 2>nul >nul
timeout /t 2 /nobreak >nul
echo.

:: Clean previous build
echo Cleaning old files...
if exist build\*.obj del /Q build\*.obj 2>nul
if exist TadWin.exe (
    echo Deleting old TadWin.exe...
    del /Q TadWin.exe 2>nul
    if exist TadWin.exe (
        echo [WARNING] Could not delete TadWin.exe - file may be in use
        pause
        exit /b 1
    )
)
echo.

:: Create build directory
if not exist build mkdir build

echo ================================================
echo   ASSEMBLING MODULES
echo ================================================
echo.

:: Assemble each module
echo [1/6] Assembling data.asm...
nasm -f win64 -Iinclude src\data.asm -o build\data.obj
if %errorlevel% neq 0 (
    echo [FAILED] data.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] data.obj created

echo [2/6] Assembling file_ops.asm...
nasm -f win64 -Iinclude src\file_ops.asm -o build\file_ops.obj
if %errorlevel% neq 0 (
    echo [FAILED] file_ops.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] file_ops.obj created

echo [3/6] Assembling search_replace.asm...
nasm -f win64 -Iinclude src\search_replace.asm -o build\search_replace.obj
if %errorlevel% neq 0 (
    echo [FAILED] search_replace.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] search_replace.obj created

echo [4/6] Assembling dialogs.asm...
nasm -f win64 -Iinclude src\dialogs.asm -o build\dialogs.obj
if %errorlevel% neq 0 (
    echo [FAILED] dialogs.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] dialogs.obj created

echo [5/6] Assembling window.asm (WITH FIXES)...
nasm -f win64 -Iinclude src\window.asm -o build\window.obj
if %errorlevel% neq 0 (
    echo [FAILED] window.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] window.obj created (THIS HAS THE CTRL+Z FIX!)

echo [6/6] Assembling main.asm...
nasm -f win64 -Iinclude src\main.asm -o build\main.obj
if %errorlevel% neq 0 (
    echo [FAILED] main.asm assembly failed!
    pause
    exit /b 1
)
echo [OK] main.obj created

echo.
echo ================================================
echo   LINKING
echo ================================================
echo.

echo Linking all modules into TadWin.exe...
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

if %errorlevel% neq 0 (
    echo [FAILED] Linking failed!
    pause
    exit /b 1
)

echo.
echo ================================================
echo   BUILD SUCCESSFUL!
echo ================================================
echo.

:: Verify executable was created
if exist TadWin.exe (
    echo [OK] TadWin.exe created successfully!
    dir TadWin.exe | findstr TadWin
    echo.
    echo ================================================
    echo   TESTING INSTRUCTIONS
    echo ================================================
    echo.
    echo 1. The application will now start
    echo 2. Type some text: "Hello World 123"
    echo 3. Press Ctrl+Z - should remove "3"
    echo 4. Press Ctrl+Z again - should remove "2"
    echo 5. Press Ctrl+Z again - should remove "1"
    echo 6. Press Ctrl+A - should select all text
    echo.
    echo If shortcuts still don't work:
    echo - Make sure you're using THIS TadWin.exe
    echo - Check Windows keyboard settings
    echo - Try running as Administrator
    echo.
    echo ================================================
    pause
    echo.
    echo Starting TadWin.exe...
    start TadWin.exe
) else (
    echo [FAILED] TadWin.exe was not created!
    pause
    exit /b 1
)

exit /b 0
