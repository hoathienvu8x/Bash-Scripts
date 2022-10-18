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

cat > /tmp/NLDatabase.patch <<EOF
--- NLDatabase.h	2022-10-18 15:53:06.655824326 +0700
+++ NLDatabase.h	2022-10-18 16:08:43.795236638 +0700
@@ -3,26 +3,31 @@
 
 #include <string>
 #include <sstream>
+#include <cstring>
 #include <sqlite3.h>
-
+#include <stdexcept>
 
 
 namespace NL {
 
 namespace DB {
     
+inline void verify( int rc, int expected = SQLITE_OK ) {
+    if ( rc != expected ) {
+        throw std::exception();
+    }
+}
 
 class Query {
 protected:
     sqlite3_stmt *stmt;
     bool finalize;
 public:
-    Query( sqlite3_stmt *stmt, bool finalize = true ) : stmt( stmt ), finalize( finalize ) {
-    }
+    Query( sqlite3_stmt *stmt, bool finalize = true ) : stmt( stmt ), finalize( finalize ) { }
     
-    virtual ~Query() {
+    virtual ~Query( ) {
         if ( finalize ) {
-            sqlite3_finalize( stmt );
+            verify( sqlite3_finalize( stmt ) );
         }
     }
     
@@ -35,8 +40,7 @@
     void *data;
     int length;
     
-    Blob( void *data, int length ) : data( data ), length( length ) {
-    }
+    Blob( void *data, int length ) : data( data ), length( length ) { }
 };
 
 
@@ -59,23 +63,34 @@
 private:
     sqlite3_stmt* stmt;
 public:
-    Row( sqlite3_stmt *stmt ) : stmt( stmt ) {
-    }
+    Row( sqlite3_stmt *stmt ) : stmt( stmt ) { }
     
     std::string column_string( int index ) const {
-        return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        if ( stmt ) {
+            return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        return std::string();
     }
     
     int column_int( int index ) const {
-        return sqlite3_column_int( stmt, index );
+        if ( stmt ) {
+            return sqlite3_column_int( stmt, index );
+        }
+        return -1;
     }
     
     double column_double( int index ) const {
-        return sqlite3_column_double( stmt, index );
+        if ( stmt ) {
+            return sqlite3_column_double( stmt, index );
+        }
+        return 0;
     }
     
     TransientBlob column_blob( int index ) const {
-        return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        if ( stmt ) {
+            return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        return TransientBlob( (char*)nullptr, 0 );
     }
 };
 
@@ -83,7 +98,11 @@
 class Cursor {
 public:
     Cursor( sqlite3_stmt *stmt, int pos ) : stmt( stmt ), row( stmt ), pos( pos ) {
-        if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
+        if( stmt ) {
+            if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
+                pos = -1;
+            }
+        } else {
             pos = -1;
         }
     }
@@ -97,10 +116,17 @@
     }
     
     const Cursor & operator++ () {
-        if ( sqlite3_step( stmt ) == SQLITE_ROW ) {
-            pos++;
+        if ( stmt ) {
+            int rc = sqlite3_step( stmt );
+            if ( rc == SQLITE_ROW ) {
+                pos++;
+            } else if ( rc == SQLITE_DONE ) {
+                pos = -1;
+            } else {
+                throw std::exception();
+            }
         } else {
-            pos = -1;
+            throw std::exception();
         }
         return *this;
     }
@@ -114,15 +140,12 @@
 
 class Results : public Query {
 public:
-    Results( sqlite3_stmt *stmt, bool finalize ) : Query( stmt, finalize ) {
-    }
-    
-    
+    Results( sqlite3_stmt *stmt, bool finalize ) : Query( stmt, finalize ) { }
+
     Cursor begin() const {
         return Cursor( stmt, 0 );
     }
     
-    
     Cursor end() const {
         return Cursor( stmt, -1 );
     }
@@ -133,44 +156,56 @@
 private:
     sqlite3 *db;
 public:
+    Database( ) = delete;
+    Database( const Database & ) = delete;
     Database( const char *path ) {
-        sqlite3_open( path, &db );
+        db = nullptr;
+        auto rc = sqlite3_open( path, &db );
+        if ( rc ) {
+            sqlite3_close( db );
+            db = nullptr;
+        }
     }
-    
-    ~Database() {
-        sqlite3_close( db );
+    Database & operator=( const Database & ) = delete;
+    ~Database( ) {
+        if ( db ) {
+            sqlite3_close( db );
+        }
     }
     
     Query prepare( const std::string & query ) {
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
+        if ( db == nullptr ) return Query( stmt );
+        verify( sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 ) );
         return Query( stmt );
     }
     
     Results query( Query & query ) {
-        sqlite3_reset( query.stmt );
-        sqlite3_clear_bindings( query.stmt );
+        verify( sqlite3_reset( query.stmt ) );
+        verify( sqlite3_clear_bindings( query.stmt ) );
         return Results( query.stmt, false );
     }
     
     template <typename T, typename... Args>
     Results query( Query & query, T t, Args... args ) {
-        sqlite3_reset( query.stmt );
-        sqlite3_clear_bindings( query.stmt );
+        verify( sqlite3_reset( query.stmt ) );
+        verify( sqlite3_clear_bindings( query.stmt ) );
         set( query.stmt, 1, t, args... );
         return Results( query.stmt, false );
     }
     
     Results query( const std::string & query ) {
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
+        if ( db == nullptr ) return Results( stmt, true );
+        verify( sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 ) );
         return Results( stmt, true );
     }
     
     template <typename T, typename... Args>
     Results query( const std::string & query, T t, Args... args ) {
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
+        if ( db == nullptr ) return Results( stmt, true );
+        verify( sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 ) );
         set( stmt, 1, t, args... );
         return Results( stmt, true );
     }
@@ -181,7 +216,7 @@
         std::ostringstream stream;
         stream << value;
         std::string text( stream.str() );
-        sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT );
+        verify( sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT ) );
     }
     
     template<typename T, typename... Args>
@@ -196,42 +231,42 @@
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, int value) {
-    sqlite3_bind_int( stmt, index, value );
+    verify( sqlite3_bind_int( stmt, index, value ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, double value) {
-    sqlite3_bind_double( stmt, index, value );
+    verify( sqlite3_bind_double( stmt, index, value ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, float value) {
-    sqlite3_bind_double( stmt, index, (double) value );
+    verify( sqlite3_bind_double( stmt, index, (double) value ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, std::string value) {
-    sqlite3_bind_text( stmt, index, value.c_str(), (int) value.length(), SQLITE_TRANSIENT );
+    verify( sqlite3_bind_text( stmt, index, value.c_str(), (int) value.length(), SQLITE_TRANSIENT ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, const char * value) {
-    sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT );
+    verify( sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, char * value) {
-    sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT );
+    verify( sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, StaticBlob value) {
-    sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_STATIC );
+    verify( sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_STATIC ) );
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, TransientBlob value) {
-    sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_TRANSIENT );
+    verify( sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_TRANSIENT ) );
 }
 
 
EOF

patch NLDatabase.h < /tmp/NLDatabase.patch

rm -rf /tmp/NLDatabase.patch
