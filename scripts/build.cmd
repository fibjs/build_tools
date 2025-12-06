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

cmake -DBUILD_ARCH=%BUILD_ARCH% -DBUILD_TYPE=%BUILD_TYPE% -DBUILD_JOBS=%BUILD_JOBS% -DCLEAN_BUILD=%CLEAN_BUILD% -DBUILD_WITH_MSVC=%BUILD_WITH_MSVC% -P build.cmake

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