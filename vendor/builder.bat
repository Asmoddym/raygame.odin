@echo off

set COMMON_COMPILER_ARGS=-strict-style -vet -vet-cast -vet-semicolon
set BINARY_NAME=raygame
set MAIN_PACKAGE=src

IF "%1" == "run" (
  set ACTION=run
) ELSE IF "%1" == "build" (
  set ACTION=build
) ELSE (
  echo "First argument should be [run|build]"
  exit /b 1
)

IF "%2" == "debug" (
  set COMPILER_ARGS=%COMMON_COMPILER_ARGS% -debug
  set BINARY_NAME=%BINARY_NAME%-debug.exe
) ELSE IF "%2" == "release" (
  set COMPILER_ARGS=%COMMON_COMPILER_ARGS%
  set BINARY_NAME=%BINARY_NAME%-release.exe
) ELSE (
  echo "Second argument should be [debug|release]"
  exit /b 1
)

odin %ACTION% %MAIN_PACKAGE% %COMPILER_ARGS% -out:%BINARY_NAME%
