@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

REM Get default architecture
REM On Windows, when running under WoW64 (32-bit process on 64-bit OS),
REM PROCESSOR_ARCHITECTURE returns the emulated architecture (e.g., x86),
REM while PROCESSOR_ARCHITEW6432 returns the real host architecture.
REM We need to check PROCESSOR_ARCHITEW6432 first to get the true host arch.
set HOST_ARCH=%PROCESSOR_ARCHITEW6432%
if "%HOST_ARCH%"=="" set HOST_ARCH=%PROCESSOR_ARCHITECTURE%

if "%HOST_ARCH%"=="AMD64" (
    set DEFAULT_ARCH=x64
) else if "%HOST_ARCH%"=="ARM64" (
    set DEFAULT_ARCH=arm64
) else (
    set DEFAULT_ARCH=ia32
)

set BUILD_ARCH=%DEFAULT_ARCH%

set ARG_ERROR=no

for %%a in (%*) do (
    set ARG_ERROR=yes

    if "%%a"=="x64" (
    	set BUILD_ARCH=x64
        set ARG_ERROR=no
    )

    if "%%a"=="ia32" (
    	set BUILD_ARCH=ia32
        set ARG_ERROR=no
    )

    if "%%a"=="win32" (
    	set BUILD_OS=win32
        set ARG_ERROR=no
    )

    if "%%a"=="arm64" (
    	set BUILD_ARCH=arm64
        set ARG_ERROR=no
    )

    if "%%a"=="release" (
    	set BUILD_TYPE=release
        set ARG_ERROR=no
    )

    if "%%a"=="debug" (
    	set BUILD_TYPE=debug
        set ARG_ERROR=no
    )

    if "%%a"=="--use-msvc" (
    	set BUILD_WITH_MSVC=1
        set ARG_ERROR=no
    )

    if "%%a"=="clean" (
    	set CLEAN_BUILD=true
        set ARG_ERROR=no
    )

    if "%%a"=="-h" goto usage
    if "%%a"=="--help" goto usage

    if "!ARG_ERROR!"=="yes" (
        echo illegal option "%%a"
        goto usage
    )
)

if "%BUILD_TYPE%"=="" set BUILD_TYPE=release
if "%BUILD_OS%"=="" set BUILD_OS=Windows
if "%BUILD_JOBS%"=="" set BUILD_JOBS=%NUMBER_OF_PROCESSORS%

set DIST_DIRNAME=%BUILD_OS%_%BUILD_ARCH%_%BUILD_TYPE%
set BUILD_DIR=%WORK_ROOT%\out\%DIST_DIRNAME%
set BIN_DIR=%WORK_ROOT%\bin\%DIST_DIRNAME%

if "%BUILD_ARCH%"=="x64" set TargetArch=x64
if "%BUILD_ARCH%"=="ia32" set TargetArch=Win32
if "%BUILD_ARCH%"=="arm64" set TargetArch=ARM64

set MSBUILD_BUILD_TARGET=-T ClangCL
if NOT "%BUILD_WITH_MSVC%"=="" set MSBUILD_BUILD_TARGET=

if "%CLEAN_BUILD%"=="true" (
    if exist "%WORK_ROOT%\out" rmdir /s /q "%WORK_ROOT%\out"
    if exist "%WORK_ROOT%\bin" rmdir /s /q "%WORK_ROOT%\bin"
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

cmake -Wno-author -DBUILD_OS=%BUILD_OS% -DBUILD_ARCH=%BUILD_ARCH% -DBUILD_TYPE=%BUILD_TYPE% -DBUILD_JOBS=%BUILD_JOBS% -DBT_BIN_DIR=%BIN_DIR% %MSBUILD_BUILD_TARGET% -A %TargetArch% %BUILD_CMAKE_EXTRA_ARGS% -S . -B "%BUILD_DIR%"
if ERRORLEVEL 1 goto finished

cmake --build "%BUILD_DIR%" -j %BUILD_JOBS% --config %BUILD_TYPE% -- /nologo /verbosity:minimal /p:CL_MPcount=%BUILD_JOBS%
if ERRORLEVEL 1 goto finished

goto finished

:usage
	echo.
	echo Usage: `basename $0` [options] [-jn] [-v] [-h]
	echo Options:
	echo   release, debug: 
	echo       Specifies the build type.
	echo   ia32, x64, arm64:
	echo       Specifies the architecture for code generation.
	echo   clean: 
	echo       Clean the build folder.
    echo   ci: 
	echo       Specifies the environment is CI.
    echo   dev: 
	echo       Specifies to build in dev mode.
	echo   -h, --help:
	echo       Print this message and exit.
	echo   -j: enable make '-j' option.
	echo       if 'n' is not given, will set jobs to auto detected core count, otherwise n is used.
	echo   --use-clang:
	echo       Force use clang on Windows.
	echo.
    exit /B 1

:finished