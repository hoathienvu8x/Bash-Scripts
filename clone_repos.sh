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

rm -rf CppTrader CppCommon icomet

git clone https://github.com/chronoxor/CppTrader

git clone https://github.com/chronoxor/CppCommon

git clone https://github.com/ideawu/icomet

echo "Copy all header + source to repository \"$repo\""

cp -rf CppTrader/include/trader/* $repo/include/

cp -rf CppTrader/source/trader/* $repo/source/

cp -rf CppTrader/examples/matching_engine.cpp $repo/

cp -rf CppCommon/include/* $repo/include/

cp -rf CppCommon/source/* $repo/source/

mkdir -p $repo/include/icomet
cp -rf icomet/src/comet/*.h $repo/include/icomet/
mkdir -p $repo/source/icomet
cp -rf icomet/src/comet/*.cpp $repo/source/icomet/
mkdir -p $repo/include/util
cp -rf icomet/src/util/*.h $repo/include/util/
mkdir -p $repo/source/util
cp -rf icomet/src/util/*.cpp $repo/source/util/


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

echo "Make build script command"

cat > $repo/build.sh << EOF
#!/bin/bash

BASE_DIR=\`pwd\`
JEMALLOC_PATH="\$BASE_DIR/dependencies/jemalloc"
LIBEVENT_PATH="\$BASE_DIR/dependencies/libevent"

if test -z "\$MAKE"; then
    MAKE=make
fi
if test -z "\$CC"; then
    CC=gcc
fi
if test -z "\$CXX"; then
    CXX=g++
fi

PLATFORM_LIBS="-lrt -pthread"

DIR=\`pwd\`
######### build jemalloc #########
cd \$JEMALLOC_PATH
if [ ! -f Makefile ]; then
    echo ""
    echo "##### building jemalloc... #####"
    ./configure
    make
    echo "##### building jemalloc finished #####"
    echo ""
fi
cd "\$DIR"

######### build libevent #########
cd "\$LIBEVENT_PATH"
if [ ! -f Makefile ]; then
    ./configure
    make
fi
cd "\$DIR"

######### generate build.mk #########

rm -f build.mk

echo PROJECT_DIR := \$(shell pwd) >> build.mk
echo C=\$C >> build.mk
echo CC=\$CC >> build.mk
echo CXX=\$CXX >> build.mk
echo CFLAGS := -std=c++11 -Wall -g -I\$(PROJECT_DIR)/include >> build.mk
echo CFLAGS += -O2 -Wall -Wno-sign-compare >> build.mk
echo CFLAGS += -D__STDC_FORMAT_MACROS >> build.mk
echo CFLAGS += -I \"\$LIBEVENT_PATH\" >> build.mk
echo CFLAGS += -I \"\$LIBEVENT_PATH/include\" >> build.mk
echo CFLAGS += -I \"\$LIBEVENT_PATH/compact\" >> build.mk

echo CLIBS := >> build.mk
echo CLIBS += \$PLATFORM_LIBS >> build.mk

echo "CLIBS += \"\$JEMALLOC_PATH/lib/libjemalloc.a\"" >> build.mk
echo "CFLAGS += -I \"\$JEMALLOC_PATH/include\"" >> build.mk

echo LIBEVENT_PATH = \$LIBEVENT_PATH >> build.mk
echo JEMALLOC_PATH = \$JEMALLOC_PATH >> build.mk
EOF

echo "General \"Makefile to build project\""

cat > $repo/fixed.md << EOF
Fixed max_align_t error
\`\`\`
// https://ceres-solver-review.googlesource.com/c/ceres-solver/+/9100/1/include/ceres/internal/port.h#b57
#ifdef CERES_USE_CXX11
    #if defined (__GNUC__) && __GNUC__ == 4 && __GNUC_MINOR__ == 8
        using ::max_align_t
    #else
        using std::max_align_t
    #endif
#endif
\`\`\`
EOF

cat > $repo/Makefile << EOF
# https://gist.github.com/Wenchy/64db1636845a3da0c4c7
PROJECT_DIR := \$(shell pwd)

\$(shell sh build.sh 1>&2)

CC := g++
CFLAGS := -std=c++11 -Wall -g -I\$(PROJECT_DIR)/include
TARGET := matching-engine

include build.mk

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
