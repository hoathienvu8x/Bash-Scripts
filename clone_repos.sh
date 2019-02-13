#!/bin/bash

reponame="${1:-Crypto-Exchange-Matching-Engine}"

repo="`pwd`/$reponame"

echo "Remove old repository \"$repo\""

rm -rf $repo

echo "Make repository \"$repo\" directory and subfolders"

mkdir -p $repo
mkdir -p $repo/include
mkdir -p $repo/source

mkdir -p $repo/dependencies

cd $repo

cd /tmp

echo "Clone \"CppTrader\" and \"CppCommon\" from git repositories"

rm -rf CppTrader CppCommon

git clone https://github.com/chronoxor/CppTrader

git clone https://github.com/chronoxor/CppCommon

echo "Copy all header + source to repository \"$repo\""

cp -rf CppTrader/include/trader/* $repo/include/

cp -rf CppTrader/source/trader/* $repo/source/

cp -rf CppTrader/examples/matching_engine.cpp $repo/

cp -rf CppCommon/include/* $repo/include/

cp -rf CppCommon/source/* $repo/source/

echo "Change include libs in source and header file"

for file in `find $repo -name '*.h'`;
do
    sed -i -e "s/trader\/matching\//matching\//g" $file
    sed -i -e "s/trader\/providers\//providers\//g" $file
    sed -i -e "s/std::max_align_t/max_align_t/g" $file
done

for file in `find $repo -name '*.cpp'`;
do
    sed -i -e "s/trader\/matching\//matching\//g" $file
    sed -i -e "s/trader\/providers\//providers\//g" $file
    sed -i -e "s/std::max_align_t/max_align_t/g" $file
done

for file in `find $repo -name '*.inl'`;
do
    sed -i -e "s/trader\/matching\//matching\//g" $file
    sed -i -e "s/trader\/providers\//providers\//g" $file
    sed -i -e "s/std::max_align_t/max_align_t/g" $file
done

echo "Clone \"jemalloc\" and \"libevent\" from git repositories"

cd $repo/dependencies

git clone https://github.com/libevent/libevent.git

git clone https://github.com/jemalloc/jemalloc.git

echo "General \"Makefile to build project\""

cat > $repo/fixed.md << EOF
Fixed max_align_t error
```
// https://ceres-solver-review.googlesource.com/c/ceres-solver/+/9100/1/include/ceres/internal/port.h#b57
#ifdef CERES_USE_CXX11
    #if defined (__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ == 8
        using ::max_align_t
    #else
        using std::max_align_t
    #endif
#endif
EOF

cat > $repo/Makefile << EOF
# https://gist.github.com/Wenchy/64db1636845a3da0c4c7
PROJECT_DIR := \$(shell pwd)

CC := g++
CFLAGS := -std=c++11 -Wall -g -I\$(PROJECT_DIR)/include
TARGET := matching-engine

SRCS := \$(wildcard *.cpp)
OBJS := \$(patsubst %.cpp,%.o,\$(SRCS))
all: \$(TARGET)

\$(TARGET): \$(OBJS)
	\$(CC) -o \$@ \$^
%.o: %.cpp
	\$(CC) \$(CFLAGS) -c \$<
clean:
	rm -rf \$(TARGET) *.o
.PHONY: all clean
EOF

