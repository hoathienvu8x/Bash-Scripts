#!/bin/bash

reponame="${1:-Crypto-Exchange-Matching-Engine}"

repo="`pwd`/$reponame"

echo "Remove old repository \"$repo\""

rm -rf $repo

echo "Make repository \"$repo\" directory and subfolders"

mkdir -p $repo
mkdir -p $repo/include
mkdir -p $repo/source

cd $repo

cd /tmp

if [ ! -d "CppTrader/.git" ];
then
    echo "Clone \"CppTrader\" repository from github"
    git clone https://github.com/chronoxor/CppTrader
else
    cd CppTrader
    echo "Pull master from \"CppTrader\" repository"
    git pull origin master
    cd /tmp
fi

if [ ! -d "CppCommon/.git" ];
then
    echo "Clone \"CppCommon\" repository from github"
    git clone https://github.com/chronoxor/CppCommon
else
    cd CppCommon
    echo "Pull master from \"CppCommon\" repository"
    git pull origin master
    cd /tmp
fi

if [ ! -d "fmt/.git" ];
then
    echo "Clone \"fmt\" repository from github"
    git clone https://github.com/fmtlib/fmt
else
    cd fmt
    echo "Pull master from \"fmt\" repository"
    git pull origin master
    cd /tmp
fi

echo "Copy all header + source to repository \"$repo\""

cp -rf CppTrader/include/trader/* $repo/include/

cp -rf CppTrader/source/trader/* $repo/source/

cp -rf CppTrader/examples/matching_engine.cpp $repo/

cp -rf CppCommon/include/* $repo/include/

cp -rf CppCommon/source/* $repo/source/

cp -rf fmt/include/* $repo/include/

if [ ! -d "$repo/source/fmt" ];
then
    mkdir -p $repo/source/fmt
fi

cp -rf fmt/src/* $repo/source/fmt/

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

echo "CC = g++" > $repo/Makefile
echo "PROJECT_DIR = \$(shell pwd)" >> $repo/Makefile
echo "CFLAGS = -std=c++17 -Wall -g -I\$(PROJECT_DIR)/include" >> $repo/Makefile
echo "TARGET = matching-engine" >> $repo/Makefile
i=0
srcs=($(find $repo -name '*.cpp'))
len=${#srcs[*]}
for file in "${srcs[@]}";
do
    # https://stackoverflow.com/a/24347937 + https://stackoverflow.com/a/525875
    if [ $i -eq 0 ]; then
        echo "SRCS = \$(PROJECT_DIR)${file/#$repo/} \\" >> $repo/Makefile
    else
        if [ $i -lt $((len-1)) ]; then
            echo -e "\t\$(PROJECT_DIR)${file/#$repo/} \\" >> $repo/Makefile
        else
            echo -e "\t\$(PROJECT_DIR)${file/#$repo/}" >> $repo/Makefile
        fi
    fi
    i=$(( i + 1 ))
done

sed -i -e 's/\\\n$//' $repo/Makefile
echo "" >> $repo/Makefile
echo "OBJS = \$(SRCS:.cpp=.o)" >> $repo/Makefile
echo "" >> $repo/Makefile
echo "all: \$(TARGET)" >> $repo/Makefile
echo "" >> $repo/Makefile
echo "\$(TARGET): \$(OBJS)" >> $repo/Makefile
echo -e "\t\$(CC) -o \$@ \$^" >> $repo/Makefile
echo "" >> $repo/Makefile
echo "%.o: %.cpp" >> $repo/Makefile
echo -e "\t\$(CC) \$(CFLAGS) -c \$< -o \$@" >> $repo/Makefile
echo "" >> $repo/Makefile
echo "clean:" >> $repo/Makefile
echo -e "\trm -rf \$(TARGET) *.o" >> $repo/Makefile
echo "" >> $repo/Makefile
echo ".PHONY: all clean" >> $repo/Makefile