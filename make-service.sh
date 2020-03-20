#!/bin/bash

WORKDIR="/tmp/repos"

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

mkdir -p $WORKDIR/service

cp -rf $WORKDIR/cpp-httplib/httplib.h $WORKDIR/service/
cat $WORKDIR/RSJp-cpp/RSJparser.tcc > $WORKDIR/service/json.h

sed -i 's/RSJ/JSON/g' $WORKDIR/service/json.h

cat > $WORKDIR/service/service.cpp <<EOF
#include <iostream>
#include <string>
#include "httplib.h"
#include "json.h"

JSONresource *json_decode(std::string);
std::string json_encode(JSONresource);

int main(int argc, char **argv) {
    return 0;
}

JSONresource *json_decode(std::string str) {
    return new JSONresource(str);
}
std::string json_encode(JSONresource src) {
    return src.as_str(true, true);
}
EOF
