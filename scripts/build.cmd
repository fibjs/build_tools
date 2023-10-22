@echo off

SETLOCAL ENABLEDELAYEDEXPANSION

set ARG_ERROR=no

for %%a in (%*) do (
    set ARG_ERROR=yes

    if "%%a"=="x64" (
    	set BUILD_ARCH=x64
        set ARG_ERROR=no
    )

    if "%%a"=="x86" (
    	set BUILD_ARCH=x86
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

    if "%%a"=="--use-clang" (
    	set BUILD_USE_CLANG=true
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

cmake -DBUILD_ARCH=%BUILD_ARCH% -DBUILD_TYPE=%BUILD_TYPE% -DBUILD_JOBS=%BUILD_JOBS% -DCLEAN_BUILD=%CLEAN_BUILD% -DBUILD_USE_CLANG=%BUILD_USE_CLANG% -P build.cmake

goto finished

:usage
	echo.
	echo Usage: `basename $0` [options] [-jn] [-v] [-h]
	echo Options:
	echo   release, debug: 
	echo       Specifies the build type.
	echo   x86, x64, arm64:
	echo       Specifies the architecture for code generation.
	echo   clean: 
	echo       Clean the build folder.
	echo   ci: 
	echo       Specifies the environment is CI.
	echo   -h, --help:
	echo       Print this message and exit.
	echo   -j: enable make '-j' option.
	echo       if 'n' is not given, will set jobs to auto detected core count, otherwise n is used.
	echo   --use-clang:
	echo       Force use clang on Windows.
	echo.
    exit /B 1

:finished