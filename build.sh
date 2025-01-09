#!/bin/sh

[ -d "./ext/luarjit2" ] || git clone https://github.com/reglnk/luarjit2 ./ext/luarjit2

wd=$(pwd)
LJ_DIR=./ext/luarjit2
cd $LJ_DIR && make && cd "$wd"
shopt -s nullglob
cp -f $LJ_DIR/src/*.{dll,so}* .

LJ_LIB=$(basename $(ls $LJ_DIR/src/libluarjit*))

SCBS_CXX=g++

SCBS_CMD="$SCBS_CXX -c -std=c++20 -g source/luascbs/main.cpp -o obj/main.o -Iinclude -I$LJ_DIR/src"
echo $SCBS_CMD
$SCBS_CMD
SCBS_CMD="$SCBS_CXX -o luascbs obj/main.o -l:$LJ_LIB -L$LJ_DIR/src"
echo $SCBS_CMD
$SCBS_CMD


