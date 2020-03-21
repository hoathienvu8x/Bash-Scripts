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
#sed -i 's/int b=0/size_t b=0/g' $WORKDIR/service/include/json.h
#sed -i 's/int a=0/size_t a=0/g' $WORKDIR/service/include/json.h
#sed -i 's/int newline_pos =/size_t newline_pos =/g' $WORKDIR/service/include/json.h
#sed -i 's/int\* parse_start_str_pos/size_t* parse_start_str_pos/g' $WORKDIR/service/include/json.h
#sed -i 's/parse_start_str_pos = new int;/parse_start_str_pos = new size_t;/g' $WORKDIR/service/include/json.h
#sed -i 's/operator\[\] (int indx)/operator[] (size_t indx)/g' $WORKDIR/service/include/json.h

if [ ! -d "$WORKDIR/sqlite-amalgamation-3310100" ] || [ ! -f "$WORKDIR/sqlite-amalgamation-3310100/sqlite3.h" ] || [ ! -f "$WORKDIR/sqlite-amalgamation-3310100/sqlite3.c" ]
then
    wget https://www.sqlite.org/2020/sqlite-amalgamation-3310100.zip -O $WORKDIR/sqlite-amalgamation-3310100.zip
    cd $WORKDIR
    unzip sqlite-amalgamation-3310100.zip
    rm -rf $WORKDIR/sqlite-amalgamation-3310100.zip
fi
mkdir -p $WORKDIR/service/source

cat $WORKDIR/sqlite-amalgamation-3310100/sqlite3.h > $WORKDIR/service/include/sqlite3.h
cat $WORKDIR/sqlite-amalgamation-3310100/sqlite3.c > $WORKDIR/service/source/sqlite3.c

cat > $WORKDIR/service/source/service.cpp <<EOF
#include <iostream>
#include <string>
#include <httplib.h>
#include <unistd.h>
#include <json.h>
#include <sqlite3.h>

using httplib::Server;
using httplib::Request;
using httplib::Response;
using jsonlib::JSONresource;
sqlite3 *db;
char * current_path, *dbFile;

JSONresource *json_decode(std::string);
std::string json_encode(JSONresource);
char *get_current_dir();

int main(int argc, char **argv) {
    current_path = get_current_dir();
    char mdb[PATH_MAX];
    sprintf(mdb, "%s/database.db", current_path);
    size_t len = strlen(mdb);
    if (len == (unsigned)-1) {
        len = 0;
    }
    mdb[len] = '\0';
    dbFile = strdup(mdb);
    
    /* Init database */
    int rc;
    rc = sqlite3_open(dbFile, &db);
    if( rc != SQLITE_OK ){
        printf("Error connect sqlite database: %s\n",sqlite3_errmsg(db));
        sqlite3_close(db);
        return 1;
    }
    char *zErrMsg = 0;
    const char *sql = "CREATE TABLE IF NOT EXISTS users (user_id INTEGER PRIMARY KEY AUTOINCREMENT, user_fullname TEXT NOT NULL, user_email TEXT NOT NULL, user_password TEXT NOT NULL, user_status INTEGER NOT NULL DEFAULT 0)";
    rc = sqlite3_exec(db, sql, NULL, 0, &zErrMsg);
    if ( rc != SQLITE_OK ) {
        printf("Error create table: %s\n", zErrMsg);
        sqlite3_close(db);
        return 1;
    }
    Server svr;
    svr.Get("/", [](const Request& req, Response& res) {
	JSONresource *data = json_decode("{'RSJ': 'string data', 'keyName': [2,3,5,7]}");
	if (data != NULL) {
            res.set_content(json_encode(*data), "text/plain");
        } else {
            res.set_content("{}", "text/plain");
        }
    });
    svr.Get(R"(/user/(\d+))", [&](const Request& req, Response& res) {
        auto uid = req.matches[1];
        res.set_content(uid, "text/plain");
    });
    svr.Get("/users", [](const Request& req, Response& res) {
        if (req.has_param("page")) {
            auto val = req.get_param_value("page");
            res.set_content(val, "text/plain");
        } else {
            res.set_content(req.body, "text/plain");
        }
    });
    svr.listen("127.0.0.1", 9600);
    return 0;
}

JSONresource *json_decode(std::string str) {
    return new jsonlib::JSONresource(str);
}
std::string json_encode(JSONresource src) {
    return src.as_str(false, true, false);
}
char *get_current_dir() {
    char exePath[PATH_MAX];
    ssize_t len = readlink("/proc/self/exe", exePath, sizeof(exePath));
    if (len == -1 || len == sizeof(exePath)) {
        len = 0;
    }
    while(len > 0) {
        if (exePath[len] == '/') {
            break;
        }
        len--;
    }
    exePath[len] = '\0';
    return strdup(exePath);
}
EOF

cat > $WORKDIR/service/Makefile <<EOF
CX = g++
CXX = gcc
LDFLAGS = -Wall -Werror -O3
CFLAGS = -std=c++11
INCDIR = \$(shell pwd)/include
INCLUDES = -I./ -I/usr/local/include -I\$(INCDIR) -lpthread -ldl

OBJECTS = source/service.o source/sqlite3.o

all: \$(OBJECTS)
	\$(CX) \$(LDFLAGS) \$(CFLAGS) \$(OBJECTS) -o service \$(INCLUDES)

%.o: %.cpp
	\$(CX) \$(LDFLAGS) \$(CFLAGS) -c \$< \$(INCLUDES) -o \$@

source/sqlite3.o: source/sqlite3.c
	\$(CXX) \$(LDFLAGS) -c \$< \$(INCLUDES) -o \$@

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
