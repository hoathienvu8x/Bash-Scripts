#!/bin/bash

WORKDIR="/home/mrnhat/repos"

mkdir -p $WORKDIR

cd $WORKDIR

if [ ! -d "$WORKDIR/RSJp-cpp/.git" ]
then
	git clone https://github.com/subh83/RSJp-cpp
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
	mkdir -p $WORKDIR/service
else
	rm -rf $WORKDIR/service/*
fi

cp -rf $WORKDIR/cpp-httplib/httplib.h $WORKDIR/service/
cat $WORKDIR/RSJp-cpp/RSJparser.tcc > $WORKDIR/service/json.h

sed -i 's/RSJ/JSON/g' $WORKDIR/service/json.h
#sed -i 's/int /size_t /g' $WORKDIR/service/json.h
#sed -i 's/int\*/size_t*/g' $WORKDIR/service/json.h
#sed -i 's/new int/new size_t/g' $WORKDIR/service/json.h
#sed -i 's/size_t  JSONresource::as<int>/int JSONresource::as<int>/g' $WORKDIR/service/json.h
sed -i 's/int b=0/size_t b=0/g' $WORKDIR/service/json.h
sed -i 's/int a=0/size_t a=0/g' $WORKDIR/service/json.h
sed -i 's/int newline_pos =/size_t newline_pos =/g' $WORKDIR/service/json.h
sed -i 's/int\* parse_start_str_pos/size_t* parse_start_str_pos/g' $WORKDIR/service/json.h
sed -i 's/parse_start_str_pos = new int;/parse_start_str_pos = new size_t;/g' $WORKDIR/service/json.h
sed -i 's/operator\[\] (int indx)/operator[] (size_t indx)/g' $WORKDIR/service/json.h

cat > $WORKDIR/service/service.cpp <<EOF
#include <iostream>
#include <string>
#include "httplib.h"
#include "json.h"

using namespace httplib;

JSONresource *json_decode(std::string);
std::string json_encode(JSONresource);

int main(int argc, char **argv) {
    JSONresource *data = json_decode("{'RSJ': 'string data', 'keyName': [2,3,5,7]}");
    if (data != NULL) {
        std::cout << json_encode(*data) << std::endl;
    } else {
        std::cout << "Error parse JSON" << std::endl;
    }
    Server svr;
    svr.Get("/", [](const Request& req, Response& res) {
        res.set_content("Hello World!", "text/plain");
    });
    svr.listen("127.0.0.1", 9600);
    return 0;
}

JSONresource *json_decode(std::string str) {
    return new JSONresource(str);
}
std::string json_encode(JSONresource src) {
    return src.as_str(false, false);
}
EOF

cd $WORKDIR/service
g++ -std=c++11 -Wall service.cpp -o service -lpthread
./service
