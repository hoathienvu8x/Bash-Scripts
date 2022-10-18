#!/bin/bash

if [ ! -d "/tmp/graphql" ]; then
    mkdir /tmp/graphql
fi

cd /tmp/graphql

wget -q https://raw.githubusercontent.com/pcslara/fluxy/master/fluxy.h -O fluxy.h
wget -q https://raw.githubusercontent.com/raven-ie/NLDatabase/master/NLDatabase.h -O NLDatabase.h
wget -q https://raw.githubusercontent.com/vivkin/gason/master/src/gason.cpp -O gason.cpp
wget -q https://raw.githubusercontent.com/vivkin/gason/master/src/gason.h -O gason.h
wget -q https://raw.githubusercontent.com/DavidUser/GraphQL-Cpp/master/main.cpp -O main.cpp
wget -q https://raw.githubusercontent.com/DavidUser/GraphQL-Cpp/master/purchase.h -O purchase.h
wget -q https://raw.githubusercontent.com/DavidUser/GraphQL-Cpp/master/graphql.h -O graphql.h
wget -q https://raw.githubusercontent.com/DavidUser/GraphQL-Cpp/master/custumer.h -O custumer.h

