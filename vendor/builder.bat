@echo off

set COMMON_COMPILER_ARGS=-strict-style 
set STRICT_COMPILER_ARGS=-vet -vet-cast -vet-semicolon
set BINARY_NAME=raygame
set MAIN_PACKAGE=src

IF "%1" == "run" (
  set ACTION=run
) ELSE IF "%1" == "run-strict" (
  set ACTION=run
) ELSE IF "%1" == "build" (
  set ACTION=build
) ELSE IF "%1" == "build-strict" (
  set ACTION=build
) ELSE IF "%1" == "check" (
  set ACTION=check
) ELSE (
  echo "First argument should be [run|run-strict|build|build-strict|check]"
  exit /b 1
)

if "%1" == "run" (
  if "%2" == "debug" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% -debug -out:%BINARY_NAME%-debug.exe
  ) else if "%2" == "release" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% -out:%BINARY_NAME%.exe -no-bounds-check -o:speed
  ) else (
    echo "Second argument should be [debug|release]"
    exit /b 1
  )
)

if "%1" == "run-strict" (
  if "%2" == "debug" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% %STRICT_COMPILER_ARGS% -debug -out:%BINARY_NAME%-debug.exe
  ) else if "%2" == "release" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% %STRICT_COMPILER_ARGS% -out:%BINARY_NAME%.exe -no-bounds-check -o:speed
  ) else (
    echo "Second argument should be [debug|release]"
    exit /b 1
  )
)

if "%1" == "build" (
  if "%2" == "debug" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% -debug -out:%BINARY_NAME%-debug.exe
  ) else if "%2" == "release" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% -out:%BINARY_NAME%.exe -no-bounds-check -o:speed
  ) else (
    echo "Second argument should be [debug|release]"
    exit /b 1
  )
)

if "%1" == "build-strict" (
  if "%2" == "debug" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% %STRICT_COMPILER_ARGS% -debug -out:%BINARY_NAME%-debug.exe
  ) else if "%2" == "release" (
    set COMPILER_ARGS=%COMMON_COMPILER_ARGS% %STRICT_COMPILER_ARGS% -out:%BINARY_NAME%.exe -no-bounds-check -o:speed
  ) else (
    echo "Second argument should be [debug|release]"
    exit /b 1
  )
)

if "%1" == "check" (
  set COMPILER_ARGS=%COMMON_COMPILER_ARGS% %STRICT_COMPILER_ARGS%
)

odin %ACTION% %MAIN_PACKAGE% %COMPILER_ARGS%
