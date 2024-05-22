#!/bin/bash

[ -d "./ext/LuaJIT" ] || git clone https://github.com/LuaJIT/LuaJIT ext/LuaJIT

LJ_DIR=ext/LuaJIT
cd $LJ_DIR && make && cd ../..
shopt -s nullglob
cp -f $LJ_DIR/src/*.{dll,so} .

LJ_LIB=$(basename $(ls $LJ_DIR/src/libluajit*))

SCBS_CXX=g++

SCBS_CMD="$SCBS_CXX -c -std=c++20 -g source/luascbs/main.cpp -o obj/main.o -Iinclude -I$LJ_DIR/src"
echo $SCBS_CMD
$SCBS_CMD
SCBS_CMD="$SCBS_CXX -o luascbs obj/main.o -l:$LJ_LIB -L$LJ_DIR/src"
echo $SCBS_CMD
$SCBS_CMD


