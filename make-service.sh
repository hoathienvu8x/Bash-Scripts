#!/bin/bash

WORKDIR="/tmp/repos"

mkdir -p $WORKDIR

cd $WORKDIR

if [ ! -d "$WORKDIR/RSJp-cpp/.git" ]
then
	git clone https://github.com/hoathienvu8x/RSJp-cpp
else
	cd $WORKDIR/RSJp-cpp
	git pull
fi

if [ ! -d "$WORKDIR/cpp-httplib/.git" ]
then
	git clone https://github.com/yhirose/cpp-httplib
else
	cd $WORKDIR/cpp-httplib
	git pull
fi

if [ ! -d "$WORKDIR/service" ]
then
	mkdir -p $WORKDIR/service/include
else
	rm -rf $WORKDIR/service/*
	mkdir -p $WORKDIR/service/include
fi

cp -rf $WORKDIR/cpp-httplib/httplib.h $WORKDIR/service/include/
cat $WORKDIR/RSJp-cpp/RSJparser.tcc > $WORKDIR/service/include/json.h

sed -i 's/RSJ/JSON/g' $WORKDIR/service/include/json.h
#sed -i 's/int /size_t /g' $WORKDIR/service/include/json.h
#sed -i 's/int\*/size_t*/g' $WORKDIR/service/include/json.h
#sed -i 's/new int/new size_t/g' $WORKDIR/service/include/json.h
#sed -i 's/size_t  JSONresource::as<int>/int JSONresource::as<int>/g' $WORKDIR/service/include/json.h
sed -i 's/int b=0/size_t b=0/g' $WORKDIR/service/include/json.h
sed -i 's/int a=0/size_t a=0/g' $WORKDIR/service/include/json.h
sed -i 's/int newline_pos =/size_t newline_pos =/g' $WORKDIR/service/include/json.h
sed -i 's/int\* parse_start_str_pos/size_t* parse_start_str_pos/g' $WORKDIR/service/include/json.h
sed -i 's/parse_start_str_pos = new int;/parse_start_str_pos = new size_t;/g' $WORKDIR/service/include/json.h
sed -i 's/operator\[\] (int indx)/operator[] (size_t indx)/g' $WORKDIR/service/include/json.h

cat > $WORKDIR/service/service.cpp <<EOF
#include <iostream>
#include <string>
#include <httplib.h>
#include <json.h>

using namespace httplib;

JSONresource *json_decode(std::string);
std::string json_encode(JSONresource);

int main(int argc, char **argv) {
    Server svr;
    svr.Get("/", [](const Request& req, Response& res) {
	JSONresource *data = json_decode("{'RSJ': 'string data', 'keyName': [2,3,5,7]}");
	if (data != NULL) {
            res.set_content(json_encode(*data), "text/plain");
        } else {
            res.set_content("{}", "text/plain");
        }
    });
    svr.listen("127.0.0.1", 9600);
    return 0;
}

JSONresource *json_decode(std::string str) {
    return new JSONresource(str);
}
std::string json_encode(JSONresource src) {
    return src.as_str(false, true, false);
}
EOF

cat > $WORKDIR/service/Makefile <<EOF
CC = g++
CFLAGS = -Wall -Werror -O3 -std=c++11
INCDIR = \$(shell pwd)/include
INCLUDES = -I./ -I/usr/local/include -I\$(INCDIR) -lpthread -ldl

%.o: %.cpp
	\$(CC) \$(CFLAGS) -c \$< \$(INCLUDES) -o \$@

OBJECTS = service.o

all: \$(OBJECTS)
	\$(CC) \$(CFLAGS) \$(OBJECTS) -o service \$(INCLUDES)

.PHONY: all clean

clean:
	@rm -rf service \$(OBJECTS)
EOF

cd $WORKDIR/service
#g++ -std=c++11 -Wall service.cpp -o service -lpthread
#./service

make

if [ -f "$WORKDIR/service/service" ]
then
	./service
else
	echo "Build faild"
fi
