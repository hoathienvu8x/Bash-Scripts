#!/bin/bash

cd /tmp

git clone https://github.com/loentar/ngrest

DEST="/tmp/resful"
SRC="/tmp/ngrest/core"

for f in `find $SRC/ -name '*.h'`
do
	n="`echo $f | sed 's/\/src\//\//'`"
	n="${n/#$SRC/$DEST\/include}"
	d=$(dirname $n)
	l=$(basename $d)
	mkdir -p $d
	cp -rf $f $n
	sed -i "s/<ngrest\//</g" $n
	#sed -i "s/#include \"/#include <$l\//g" $n
	#sed -i "s/\.h\"/.h>/g" $n
done

for f in `find $SRC/ -name '*.cpp'`
do
	n="`echo $f | sed 's/\/src\//\//'`"
	n="${n/#$SRC/$DEST\/source}"
	d=$(dirname $n)
	l=$(basename $d)
	mkdir -p $d
	cp -rf $f $n
	sed -i "s/<ngrest\//</g" $n
	sed -i "s/#include \"/#include <$l\//g" $n
	sed -i "s/\.h\"/.h>/g" $n
done


cat > $DEST/Makefile <<EOF
CC = g++
CFLAGS = -Wall -Werror -O3 -std=c++11 -Wl,--no-undefined -pedantic
INCDIR = \$(shell pwd)/include
INCLUDES = -I./ -I/usr/local/include -I\$(INCDIR) -lpthread -ldl -DHAS_EPOLL

%.o: %.cpp
	\$(CC) \$(CFLAGS) -c \$< \$(INCLUDES) -o \$@

OBJECTS = \\
EOF

for f in `find $DEST/source/ -name '*.cpp'`
do
	n="`echo $f | sed 's/\.cpp/.o/'`"
	n="${n/#$DEST\//}"
	echo -e "\t$n \\" >> $DEST/Makefile
done

cat<<EOF >> $DEST/Makefile

all: \$(OBJECTS)
	\$(CC) \$(CFLAGS) \$(OBJECTS) -o resful \$(INCLUDES)

.PHONY: all clean

clean:
	@rm -rf resful \$(OBJECTS)
EOF
