@echo off

REM Entry script of the example (Windows): the same shape as the entry scripts of
REM the real repositories (fibjs/build.cmd).  The shared driver configures and
REM builds the CMake project of this directory in one pass:
REM
REM   build.cmd x64 release -j4

set SOURCE_ROOT=%~dp0

cd /d "%SOURCE_ROOT%"

set WORK_ROOT=%cd%
set VENDER_ROOT=%SOURCE_ROOT%..\..
set BUILD_ENTRY=%SOURCE_ROOT%

call "%SOURCE_ROOT%..\..\scripts\build.cmd" %*
