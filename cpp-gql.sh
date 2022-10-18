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
--- NLDatabase.h	2022-10-18 15:09:42.648241239 +0700
+++ NLDatabase.h	2022-10-18 15:25:30.037454787 +0700
@@ -3,14 +3,20 @@
 
 #include <string>
 #include <sstream>
+#include <cstring>
 #include <sqlite3.h>
-
+#include <stdexcept>
 
 
 namespace NL {
 
 namespace DB {
     
+inline void verify(int rc, int expected = SQLITE_OK) {
+  if (rc != expected) {
+    throw std::exception();
+  }
+}
 
 class Query {
 protected:
@@ -22,7 +28,7 @@
     
     virtual ~Query() {
         if ( finalize ) {
-            sqlite3_finalize( stmt );
+            verify(sqlite3_finalize( stmt ));
         }
     }
     
@@ -63,19 +69,31 @@
     }
     
     std::string column_string( int index ) const {
-        return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        if (stmt) {
+            return std::string( (char*)sqlite3_column_text( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        return std::string();
     }
     
     int column_int( int index ) const {
-        return sqlite3_column_int( stmt, index );
+        if (stmt) {
+            return sqlite3_column_int( stmt, index );
+        }
+        return -1;
     }
     
     double column_double( int index ) const {
-        return sqlite3_column_double( stmt, index );
+        if (stmt) {
+            return sqlite3_column_double( stmt, index );
+        }
+        return 0;
     }
     
     TransientBlob column_blob( int index ) const {
-        return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        if (stmt) {
+            return TransientBlob( sqlite3_column_blob( stmt, index ), sqlite3_column_bytes( stmt, index ) );
+        }
+        return TransientBlob((char*)nullptr, 0);
     }
 };
 
@@ -83,7 +101,11 @@
 class Cursor {
 public:
     Cursor( sqlite3_stmt *stmt, int pos ) : stmt( stmt ), row( stmt ), pos( pos ) {
-        if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
+        if(stmt) {
+            if ( pos != -1 && sqlite3_step( stmt ) != SQLITE_ROW ) {
+                pos = -1;
+            }
+        } else {
             pos = -1;
         }
     }
@@ -97,10 +119,17 @@
     }
     
     const Cursor & operator++ () {
-        if ( sqlite3_step( stmt ) == SQLITE_ROW ) {
-            pos++;
+        if (stmt) {
+            int rc = sqlite3_step( stmt );
+            if ( rc == SQLITE_ROW ) {
+                pos++;
+            } else if (rc == SQLITE_DONE) {
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
@@ -181,7 +210,7 @@
         std::ostringstream stream;
         stream << value;
         std::string text( stream.str() );
-        sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT );
+        verify(sqlite3_bind_text( stmt, index, text.c_str(), (int)text.length(), SQLITE_TRANSIENT ));
     }
     
     template<typename T, typename... Args>
@@ -196,27 +225,27 @@
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, int value) {
-    sqlite3_bind_int( stmt, index, value );
+    verify(sqlite3_bind_int( stmt, index, value ));
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, double value) {
-    sqlite3_bind_double( stmt, index, value );
+    verify(sqlite3_bind_double( stmt, index, value ));
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, float value) {
-    sqlite3_bind_double( stmt, index, (double) value );
+    verify(sqlite3_bind_double( stmt, index, (double) value ));
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, std::string value) {
-    sqlite3_bind_text( stmt, index, value.c_str(), (int) value.length(), SQLITE_TRANSIENT );
+    verify(sqlite3_bind_text( stmt, index, value.c_str(), (int) value.length(), SQLITE_TRANSIENT ));
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, const char * value) {
-    sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT );
+    verify(sqlite3_bind_text( stmt, index, value, (int) strlen( value ), SQLITE_TRANSIENT ));
 }
 
 template <>
@@ -226,12 +255,12 @@
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, StaticBlob value) {
-    sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_STATIC );
+    verify(sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_STATIC ));
 }
 
 template <>
 void Database::set(sqlite3_stmt *stmt, int index, TransientBlob value) {
-    sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_TRANSIENT );
+    verify(sqlite3_bind_blob( stmt, index, value.data, value.length, SQLITE_TRANSIENT ));
 }
 
 
EOF

patch NLDatabase.h < /tmp/NLDatabase.patch

rm -rf /tmp/NLDatabase.patch
