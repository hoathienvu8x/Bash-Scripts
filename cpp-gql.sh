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
+++ NLDatabase.h	2022-10-18 16:55:27.344113361 +0700
@@ -1,16 +1,19 @@
-#pragma once
-
-
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
@@ -18,11 +21,14 @@
     bool finalize;
 public:
     Query( sqlite3_stmt *stmt, bool finalize = true ) : stmt( stmt ), finalize( finalize ) {
+        if ( ! stmt ) {
+            throw std::exception();
+        }
     }
     
-    virtual ~Query() {
+    virtual ~Query( ) {
         if ( finalize ) {
-            sqlite3_finalize( stmt );
+            verify( sqlite3_finalize( stmt ) );
         }
     }
     
@@ -35,8 +41,7 @@
     void *data;
     int length;
     
-    Blob( void *data, int length ) : data( data ), length( length ) {
-    }
+    Blob( void *data, int length ) : data( data ), length( length ) { }
 };
 
 
@@ -59,23 +64,47 @@
 private:
     sqlite3_stmt* stmt;
 public:
-    Row( sqlite3_stmt *stmt ) : stmt( stmt ) {
+    Row( sqlite3_stmt *stmt ) : stmt( stmt ) { }
+    
+    std::string getName( int index ) const {
+        if ( stmt ) {
+            return std::string ( sqlite3_column_name( stmt, index ) );
+        }
+        throw std::exception();
     }
     
-    std::string column_string( int index ) const {
-        return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+    std::string getText( int index ) const {
+        if ( stmt ) {
+            return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        throw std::exception();
     }
     
-    int column_int( int index ) const {
-        return sqlite3_column_int( stmt, index );
+    int getInt( int index ) const {
+        if ( stmt ) {
+            return sqlite3_column_int( stmt, index );
+        }
+        throw std::exception();
     }
     
-    double column_double( int index ) const {
-        return sqlite3_column_double( stmt, index );
+    double getDouble( int index ) const {
+        if ( stmt ) {
+            return sqlite3_column_double( stmt, index );
+        }
+        throw std::exception();
     }
     
-    TransientBlob column_blob( int index ) const {
-        return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+    TransientBlob getBlob( int index ) const {
+        if ( stmt ) {
+            return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        throw std::exception();
+    }
+    bool operator ! () const {
+        if ( stmt ) {
+            return sqlite3_column_count( stmt ) > 0;
+        }
+        throw std::exception();
     }
 };
 
@@ -83,8 +112,12 @@
 class Cursor {
 public:
     Cursor( sqlite3_stmt *stmt, int pos ) : stmt( stmt ), row( stmt ), pos( pos ) {
-        if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
-            pos = -1;
+        if( stmt ) {
+            if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
+                pos = -1;
+            }
+        } else {
+            throw std::exception();
         }
     }
     
@@ -97,10 +130,17 @@
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
@@ -114,15 +154,12 @@
 
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
@@ -133,47 +170,107 @@
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
+            throw std::exception();
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
+        if ( db == nullptr ) throw std::exception();
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
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
+        if ( db == nullptr ) throw std::exception();
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
+        verify( sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 ) );
         return Results( stmt, true );
     }
     
     template <typename T, typename... Args>
     Results query( const std::string & query, T t, Args... args ) {
+        if ( db == nullptr ) throw std::exception();
         sqlite3_stmt *stmt = 0;
-        sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 );
+        verify( sqlite3_prepare_v2( db, query.c_str(), (int)query.length(), &stmt, 0 ) );
         set( stmt, 1, t, args... );
         return Results( stmt, true );
     }
+
+    Row querySingle( Query & qry ) {
+        Results result = query( qry );
+        auto iter = result.begin();
+        return *iter;
+    }
+    
+    template <typename T, typename... Args>
+    Row querySingle( Query & qry, T t, Args... args ) {
+        Results result = query( qry, args... );
+        auto iter = result.begin();
+        return *iter;
+    }
+    
+    Row querySingle( const std::string & qry ) {
+        Results result = query( qry );
+        auto iter = result.begin();
+        return *iter;
+    }
+    
+    template <typename T, typename... Args>
+    Row querySingle( const std::string & qry, T t, Args... args ) {
+        Results result = query( qry, args... );
+        auto iter = result.begin();
+        return *iter;
+    }
+
+    int changes ( ) const {
+        if ( db == nullptr ) throw std::exception();
+        return sqlite3_changes ( db );
+    }
+    int lastInsertRowID ( ) const {
+        if ( db == nullptr ) throw std::exception();
+        return static_cast<int>( sqlite3_last_insert_rowid ( db ) );
+    }
+    int lastErrorCode ( ) const {
+        if ( db == nullptr ) throw std::exception();
+        return sqlite3_errcode( db );
+    }
+    std::string lastErrorMsg ( ) const {
+        if ( db == nullptr ) throw std::exception();
+        return std::string ( sqlite3_errmsg ( db ) );
+    }
+    void busyTimeout( int ms ) {
+        if ( db == nullptr ) throw std::exception();
+        verify( sqlite3_busy_timeout( db, ms ) );
+    }
         
 private:
     template <typename T>
@@ -181,7 +278,7 @@
         std::ostringstream stream;
         stream << value;
         std::string text( stream.str() );
-        sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT );
+        verify( sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT ) );
     }
     
     template<typename T, typename... Args>
@@ -196,42 +293,42 @@
 
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
