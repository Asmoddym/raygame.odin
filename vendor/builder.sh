#!/bin/bash

COMMON_COMPILER_ARGS="-strict-style"
STRICT_COMPILER_ARGS="-vet -vet-cast -vet-semicolon"
BINARY_NAME=raygame
MAIN_PACKAGE=src

ACTION=""

if [ "$1" == "check" ]; then
  ACTION=check
elif [ "$1" == "run" ] || [ "$1" == "run-strict" ]; then
  ACTION=run
elif [ "$1" == "build" ] || [ "$1" == "build-strict" ]; then
  ACTION=build
else
  echo "First argument should be [run|run-strict|build|build-strict]"
  exit 1
fi

COMPILER_ARGS="$COMMON_COMPILER_ARGS"

if [ "$2" = "debug" ]; then
  BINARY_NAME="$BINARY_NAME-debug"
  COMPILER_ARGS="$COMPILER_ARGS -debug"
fi

if [ "$1" == "run-strict" ] || [ "$1" == "build-strict" ] || [ "$ACTION" = "check" ]; then
  COMPILER_ARGS="$COMPILER_ARGS $STRICT_COMPILER_ARGS"
fi

FLAGS=$COMPILER_ARGS
if [ "$ACTION" = "run" ] || [ "$ACTION" = "build" ]; then
  FLAGS="$FLAGS -out:$BINARY_NAME"
fi

odin $ACTION $MAIN_PACKAGE $FLAGS
