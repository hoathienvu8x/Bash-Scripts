---
title: "Chrome Extensions and a Local Database(IndexedDB)"
description: "Store tons of data on the local hard-drive."
author: "An Object Is A"
link: "https://javascript.plainenglish.io/chrome-extensions-and-local-database-indexeddb-3c92e12c436"
publish: "Jul 25, 2020"
---

If you want to know the basics of Google Chrome Extensions, check out my
write-up here:

To demonstrate IndexedDB in the context of a Chrome Extension, we're going
to use a simple HTML page with 2 forms.

One form for adding records. One form for searching and editing records.

![](https://miro.medium.com/max/700/1*bZhOHY1dJm_lW9GIF0RsEA.png)

We'll use this form through the pop-up page of our Chrome Extension.

## Let's begin

Our manifest file

```json
// manifest.json
{
    "name": "chrome ext with localDB",
    "description": "chrome ext interacting with IndexedDB",
    "version": "0.1.0",
    "manifest_version": 2,
    "icons": {
        "16": "./obj-16x16.png",
        "32": "./obj-32x32.png",
        "48": "./obj-48x48.png",
        "128": "./obj-128x128.png"
    },
    "background": {
        "scripts": [
            "./background.js"
        ]
    },
    "options_page": "./options.html",
    "browser_action": {
        "default_popup": "popup.html"
    },
    "permissions": []
}
```

Note: We don't need any special permissions; we don't need the `storage`
permission to use IndexedDB.

Let's take a look at that background script! When our Chrome Extension first
installs, we create a database

```javascript
// background.js
let db = null;function create_database() {
    const request = window.indexedDB.open('MyTestDB');
    request.onerror = function (event) {
        console.log("Problem opening DB.");
    }
    request.onupgradeneeded = function (event) {
        db = event.target.result;
        let objectStore = db.createObjectStore('roster', {
            keyPath: 'email'
        });
        objectStore.transaction.oncomplete = function (event) {
            console.log("ObjectStore Created.");
        }
    }
    request.onsuccess = function (event) {
        db = event.target.result;
        console.log("DB OPENED.");
        insert_records(roster);
        db.onerror = function (event) {
            console.log("FAILED TO OPEN DB.")
        }
    }
}
```

Then populate that database.

```javascript
// background.js
function insert_records(records) {
    if (db) {
        const insert_transaction = db.transaction("roster", "readwrite");
        const objectStore = insert_transaction.objectStore("roster");
        return new Promise((resolve, reject) => {
            insert_transaction.oncomplete = function () {
                console.log("ALL INSERT TRANSACTIONS COMPLETE.");
                resolve(true);
            }
            insert_transaction.onerror = function () {
                console.log("PROBLEM INSERTING RECORDS.")
                resolve(false);
            }
            records.forEach(person => {
                let request = objectStore.add(person);
                request.onsuccess = function () {
                    console.log("Added: ", person);
                }
            });
        });
    }
}
```

When we get messages to add, get, update, or delete from the foreground:

```javascript
// background.js
function get_record(email) {
    if (db) {
        const get_transaction = db.transaction("roster", "readonly");
        const objectStore = get_transaction.objectStore("roster");
        return new Promise((resolve, reject) => {
            get_transaction.oncomplete = function () {
                console.log("ALL GET TRANSACTIONS COMPLETE.");
            }
            get_transaction.onerror = function () {
                console.log("PROBLEM GETTING RECORDS.")
            }
            let request = objectStore.get(email);
            request.onsuccess = function (event) {
                resolve(event.target.result);
            }
        });
    }
}
function update_record(record) {
    if (db) {
        const put_transaction = db.transaction("roster", "readwrite");
        const objectStore = put_transaction.objectStore("roster");
        return new Promise((resolve, reject) => {
                put_transaction.oncomplete = function () {
                console.log("ALL PUT TRANSACTIONS COMPLETE.");
                resolve(true);
            }
            put_transaction.onerror = function () {
                console.log("PROBLEM UPDATING RECORDS.")
                resolve(false);
            }
            objectStore.put(record);
        });
    }
}
function delete_record(email) {
    if (db) {
        const delete_transaction = db.transaction("roster", "readwrite");
        const objectStore = delete_transaction.objectStore("roster");
        return new Promise((resolve, reject) => {
            delete_transaction.oncomplete = function () {
                console.log("ALL DELETE TRANSACTIONS COMPLETE.");
                resolve(true);
            }
            delete_transaction.onerror = function () {
                console.log("PROBLEM DELETE RECORDS.")
                resolve(false);
            }
            objectStore.delete(email);
        });
    }
}
```

...we can respond with getting, updating, and deleting records... Let's take
a look at the pop-up page and its accompanying script. The popup page is
basic html page. Two forms with buttons...

```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
    <style>
        #container {
            width: 500px;
            height: fit-content;
            display: flex;
        }

        #add {
            width: fit-content;
            height: 200px;
            padding-right: 25px;
            margin-right: 25px;
            border-right: 2px solid black;
        }

        #search {
            width: fit-content;
            height: 200px;
        }

        .search-label {
            font-weight: bold;
        }

        .details {
            font-weight: normal;
            font-size: 1.5em;
        }

        .updated-details {
            font-weight: normal;
            font-size: 1.2em;
        }
    </style>
</head>

<body>
    <div id="container">
        <div id="add">
            <form id="add_form">
                <input class="add_rec_input" type="text" name="name" id="name" placeholder="Name">
                <br>
                <input class="add_rec_input" type="text" name="dob" id="dob" placeholder="dd/mm/yy">
                <br>
                <input class="add_rec_input" type="text" name="email" id="email" placeholder="Email">
                <br>
                <br>
                <button type="submit">Add</button>
            </form>
        </div>
        <div id="search">
            <form id="search_form">
                <input type="text" id="search_term" placeholder="Search by email...">
                <button id="search_for_record">Search</button>
                <br>
                <br>
                <span class="search-label">Name:
                    <span class="details" id="details-name"></span>
                    <input class="updated-details" type="text" id="update-name">
                </span>
                <br>
                <span class="search-label">Date of Birth:
                    <span class="details" id="details-dob"></span>
                    <input class="updated-details" type="text" id="update-dob">
                </span>
                <br>
                <span class="search-label">Email:
                    <span class="details" id="details-email"></span>
                </span>
                <br>
                <br>
                <button type="submit" id="edit-record">Edit Record</button>
                <button id="delete-record">Delete Record</button>
            </form>
        </div>
    </div>

    <script src="./popup-script.js"></script>
</body>

</html>
```

... and of course our `popup-script.js` attached so we can capture and manipulate
the DOM. It's in the `popup-script.js` that we capture form information and
send messages to the background script, so the background script can execute
all of the IndexedDB commands ...

```javascript
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
    if (request.message === 'insert_success') {
        if (request.payload) {
            document.querySelectorAll('.add_rec_input').forEach(el => el.value = '');
        }
    } else if (request.message === 'get_success') {
        if (request.payload) {
            document.querySelectorAll('.updated-details').forEach(el => {
                el.style.display = 'none'
            });
            document.querySelectorAll('.search-label').forEach(el => {
                el.style.display = ''
            });
            document.querySelectorAll('.details').forEach(el => {
                el.style.display = ''
            });
            document.getElementById('delete-record').style.display = '';
            document.getElementById('edit-record').style.display = '';

            // change "Save Changes" to "Edit Record"
            document.getElementById('edit-record').innerText = "Edit Record";

            document.getElementById('details-name').innerText = request.payload.name;
            document.getElementById('details-dob').innerText = request.payload.dob;
            document.getElementById('details-email').innerText = request.payload.email;
        } else {
            console.log("No record found.");
        }
    } else if (request.message === 'update_success') {
        if (request.payload) {
            document.getElementById('edit-record').innerText = "Changes saved...";
            setTimeout(() => {
                // enable button
                document.getElementById('edit-record').disabled = false;
                // change "Save Changes" to "Edit Record"
                document.getElementById('edit-record').innerText = "Edit Record";
                // show 'delete record' button
                document.getElementById('delete-record').style.display = '';
            }, 1500);

            // hide input details elements
            document.querySelectorAll('.updated-details').forEach(el => {
                el.style.display = 'none'
            });

            // show span details elements
            document.querySelectorAll('.details').forEach(el => {
                el.style.display = ''
            });
            document.getElementById('details-name').innerText = document.getElementById('update-name').value;
            document.getElementById('details-dob').innerText = document.getElementById('update-dob').value;
        }
    } else if (request.message === 'delete_success') {
        if (request.payload) {
            document.querySelectorAll('.search-label').forEach(el => {
                el.style.display = 'none'
            });
            document.querySelectorAll('.updated-details').forEach(el => {
                el.style.display = 'none'
            });
            document.querySelectorAll('.details').forEach(el => {
                el.style.display = 'none'
            });
            document.getElementById('delete-record').style.display = 'none';
            document.getElementById('edit-record').style.display = 'none';
        }
    }
});

// hide details of search results, delete button, edit text fields
document.querySelectorAll('.search-label').forEach(el => {
    el.style.display = 'none'
});
document.querySelectorAll('.updated-details').forEach(el => {
    el.style.display = 'none'
});
document.querySelectorAll('.details').forEach(el => {
    el.style.display = 'none'
});
document.getElementById('delete-record').style.display = 'none';
document.getElementById('edit-record').style.display = 'none';

// ADD A RECORD
document.getElementById('add_form').addEventListener('submit', event => {
    event.preventDefault();
    const form_data = new FormData(document.getElementById('add_form'));
    chrome.runtime.sendMessage({
        message: 'insert',
        payload: [{
            "name": form_data.get('name'),
            "dob": form_data.get('dob'),
            "email": form_data.get('email'),
        }]
    });
});

// SEARCH FOR A RECORD
document.getElementById('search_for_record').addEventListener('click', event => {
    event.preventDefault();
    let search_term = document.getElementById('search_term').value;
    chrome.runtime.sendMessage({
        message: 'get',
        payload: search_term
    });
});

// EDIT AND SAVE A RECORD
document.getElementById('edit-record').addEventListener('click', event => {
    event.preventDefault();
    if (document.getElementById('edit-record').innerText === "Edit Record") {
        // hide span details elements
        document.querySelectorAll('.details').forEach((el, i) => {
            i != 2 ? el.style.display = 'none' : null
        });

        // show input details elements
        document.querySelectorAll('.updated-details').forEach(el => {
            el.style.display = ''
        });

        document.getElementById('update-name').value = document.getElementById('details-name').innerText;
        document.getElementById('update-dob').value = document.getElementById('details-dob').innerText;

        // change edit button text
        document.getElementById('edit-record').innerText = "Save Changes";
        // hide 'delete record' button
        document.getElementById('delete-record').style.display = 'none';
    } else if (document.getElementById('edit-record').innerText === "Save Changes") {
        // disable save button
        document.getElementById('edit-record').disabled = true;

        chrome.runtime.sendMessage({
            message: 'update',
            payload: {
                "name": document.getElementById('update-name').value,
                "dob": document.getElementById('update-dob').value,
                "email": document.getElementById('details-email').innerText
            }
        });
    }
});

// DELETE A RECORD
document.getElementById('delete-record').addEventListener('click', event => {
    event.preventDefault();
    chrome.runtime.sendMessage({
        message: 'delete',
        payload: document.getElementById('details-email').innerText
    });
});
```

... and once we receive the IndexedDB data from our background, we go ahead
and show the user some visual feedback on the HTML popup page !

![](https://miro.medium.com/max/700/1*SZUPgGdO5G_sTnZYm1b2yg.png)

If you want to check out a more in-depth guide, check out my full video tutorial
on YouTube, An Object Is A. Be sure to follow us on Instagram and Twitter
to keep up with our latest Web Development tutorials.

## Creating and Opening a Database

Before you can use a database or create tables within the database, you must first
open a connection to the database. When you open a database, an empty database
is automatically created if the database you request does not exist. Thus, the
processes for opening and creating a database are identical.

To open a database, you must obtain a database object with the `openDatabase`
method as follows:

**Creating and opening a database**

```javascript
try {
    if (!window.openDatabase) {
        alert('not supported');
    } else {
        var shortName = 'mydatabase';
        var version = '1.0';
        var displayName = 'My Important Database';
        var maxSize = 65536; // in bytes
        var db = openDatabase(shortName, version, displayName, maxSize);
 
        // You should have a database instance in db.
    }
} catch(e) {
    // Error handling code goes here.
    if (e == 2) {
        // Version number mismatch.
        alert("Invalid database version.");
    } else {
        alert("Unknown error "+e+".");
    }
    return;
}
 
alert("Database is: "+db);
```

For now you should set the version number field to 1.0; database versioning
is described in more detail in
[Working With Database Versions](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/UsingtheJavascriptDatabase/UsingtheJavascriptDatabase.html).

The short name is the name for your database as stored on disk (usually
in `~/Library/Safari/Databases/`). This argument controls which database
you are accessing.

The display name field contains a name to be used by the browser if it needs
to describe your database in any user interaction, such as asking permission
to enlarge the database.

The maximum size field tells the browser the size to which you expect your
database to grow. The browser normally prevents a runaway web application
from using excessive local resources by setting limits on the size of each
site’s database. When a database change would cause the database to exceed
that limit, the user is notified and asked for permission to allow the
database to grow further.

If you know that you are going to be filling the database with a lot of
content, you should specify an ample size here. By so doing, the user is
only asked for permission once when creating the database instead of every
few megabytes as the database grows.

The browser may set limits on how large a value you can specify for this
field, but the details of these limits are not yet fully defined.

## Creating Tables

The remainder of this chapter assumes a database that contains a single
table with the following schema:

```javascript
CREATE TABLE people(
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL DEFAULT "John Doe",
    shirt TEXT NOT NULL DEFAULT "Purple"
);
```

> **Note**: For more information about schemas, see
> [Relational Database Basics](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/RelationalDatabases/RelationalDatabases.html).

You can create this table and insert a few initial values with the following
functions:

**Creating a SQL table**

```javascript
function nullDataHandler(transaction, results) { }
 
function createTables(db)
{
    db.transaction(
        function (transaction) {
 
            /* The first query causes the transaction to (intentionally) fail if the table exists. */
            transaction.executeSql('CREATE TABLE people(id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL DEFAULT "John Doe", shirt TEXT NOT NULL DEFAULT "Purple");', [], nullDataHandler, errorHandler);
            /* These insertions will be skipped if the table already exists. */
            transaction.executeSql('insert into people (name, shirt) VALUES ("Joe", "Green");', [], nullDataHandler, errorHandler);
            transaction.executeSql('insert into people (name, shirt) VALUES ("Mark", "Blue");', [], nullDataHandler, errorHandler);
            transaction.executeSql('insert into people (name, shirt) VALUES ("Phil", "Orange");', [], nullDataHandler, errorHandler);
            transaction.executeSql('insert into people (name, shirt) VALUES ("jdoe", "Purple");', [], nullDataHandler, errorHandler);
        }
    );
}
```

The `errorHandler` function is shown and explained in
[Per-Query Error Callbacks](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/UsingtheJavascriptDatabase/UsingtheJavascriptDatabase.html).

## Executing a Query

Executing a SQL query is fairly straightforward. All queries must be part
of a transaction (though the transaction may contain only a single query
if desired). You could then modify the value as follows:

**Changing values in a table**

```javascript
var name = 'jdoe';
var shirt = 'fuschia';
 
db.transaction(
    function (transaction) {
        transaction.executeSql("UPDATE people set shirt=? where name=?;",
            [ shirt, name ]); // array of values for the ? placeholders
    }
);
```

Notice that this transaction provides no data or error handlers. These
handlers are entirely optional, and may be omitted if you don’t care about
finding out whether an error occurs in a particular statement. (You can
still detect a failure of the entire transaction, as described in [Transaction
Callbacks](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/UsingtheJavascriptDatabase/UsingtheJavascriptDatabase.html).)

However, if you want to execute a query that returns data (a `SELECT` query,
for example), you must use a data callback to process the results. This
process is described in
[Handling Result Data](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/UsingtheJavascriptDatabase/UsingtheJavascriptDatabase.html).

## Handling Result Data

The examples in the previous section did not return any data. Queries that
return data are a little bit more complicated. As noted in previous sections,
every query must be part of a transaction. You must provide a callback
routine to handle the data returned by that transaction—store it, display
it, or send it to remote server, for example. The following code prints a
list of names where the value of the shirt field is “Green”:

**SQL query result and error handlers**

```javascript
function errorHandler(transaction, error)
{
    // error.message is a human-readable string.
    // error.code is a numeric error code
    alert('Oops.  Error was '+error.message+' (Code '+error.code+')');
 
    // Handle errors here
    var we_think_this_error_is_fatal = true;
    if (we_think_this_error_is_fatal) return true;
    return false;
}
 
function dataHandler(transaction, results)
{
    // Handle the results
    var string = "Green shirt list contains the following people:\n\n";
    for (var i=0; i<results.rows.length; i++) {
        // Each row is a standard JavaScript array indexed by
        // column names.
        var row = results.rows.item(i);
        string = string + row['name'] + " (ID "+row['id']+")\n";
    }
    alert(string);
}
 
db.transaction(
    function (transaction) {
        transaction.executeSql("SELECT * from people where shirt='Green';",
            [], // array of values for the ? placeholders
            dataHandler, errorHandler);
    }
);
```

> **Note**: The `errorHandler` callback may be omitted in the call to `executeSql`
> if you don’t want to capture errors.

This is, of course, a fairly simple example. Things get slightly more
complicated when you are performing dependent queries, such as creating a
new row in one table and inserting that row’s ID into a field in another
table to create a relationship between those rows. For more complex examples,
see the appendix.

To obtain the number of rows modified by a query, check the `rowsAffected`
field of the result set object. To obtain the ID of the last row inserted,
check the `insertId` field of the result set object, then perform the second
query from within the data callback of the first query. For example:

**SQL insert query example**

```javascript
db.transaction(
    function (transaction) {
        transaction.executeSql('INSERT into tbl_a (name) VALUES ( ? );',
            [ document.getElementById('nameElt').innerHTML ],
            function (transaction, resultSet) {
                if (!resultSet.rowsAffected) {
                    // Previous insert failed. Bail.
                    alert('No rows affected!');
                    return false;
                }
                alert('insert ID was '+resultSet.insertId);
                transaction.executeSql('INSERT into tbl_b (name_id, color) VALUES (?, ?);',
                    [ resultSet.insertId,
                      document.getElementById('colorElt').innerHTML ],
                    nullDataHandler, errorHandler);
            }, errorHandler);
    }, transactionErrorCallback, proveIt);
}
```

One more issue that you may run into is multiple tables that contain columns
with the same name. Because result rows are indexed by column name, you
must alias any such columns to unique names if you want to access them.
For example, the following query:

```sql
SELECT * FROM tbl_a,tbl_b ...
```

does not usefully allow access to `tbl_a.id` and `tbl_b.id`, but:

```sql
SELECT tbl_a.id AS tbl_a_id, tbl_b.id AS tbl_b_id, * FROM tbl_a, tbl_b ...
```

provides unique names for the `id` fields so that you can access them. The
following snippet is an example of this query in actual use:

**SQL query with aliased field names**

```javascript
function testAliases(){
        var db = getDB();
 
        if (!db) {
                alert('Could not open database connection.');
        }
 
db.transaction(
    function (transaction) {
        var query="SELECT tbl_a.id AS tbl_a_id, tbl_b.id AS tbl_b_id, * FROM tbl_a, tbl_b where tbl_b.name_id = tbl_a
.id;";
 
        transaction.executeSql(query, [],
                function (transaction, resultSet) {
                        var string = "";
                        for (var i=0; i<resultSet.rows.length; i++) {
                                var row = resultSet.rows.item(i);
                                alert('Alias test: Name: '+row['name']+' ('+row['tbl_a_id']+') Color: '+row['color']+' ('+row['tbl_b_id']+')');
                                // string = string + "ID: "+row['id']+" A_ID: "+row['tbl_a_id']+" B_ID: "+row['tbl_b_id']+"\n";
                        }
                        // alert("Alias test:\n"+string);
                }, errorHandler);
    }, transactionErrorCallback);
}
```

## Handling Errors

You can handle errors at two levels: at the query level and at the transaction level.

**Per-Query Error Callbacks**

The per-query error-handling callback is rather straightforward. If the
callback returns true, the entire transaction is rolled back. If the callback
returns false, the transaction continues as if nothing had gone wrong.

Thus, if you are executing a query that is optional—if a failure of that
particular query should not cause the transaction to fail—you should pass
in a callback that returns `false`. If a failure of the query should cause
the entire transaction to fail, you should pass in a callback that returns `true`.

Of course, you can also pass in a callback that decides whether to return
`true` or `false` depending on the nature of the error.

If you do not provide an error callback at all, the error is treated as
fatal and causes the transaction to roll back.

For a sample snippet, see `errorHandler` in Listing 4-4.

For a list of possible error codes that can appear in the `error.code` field,
see Error Codes.

## Transaction Error Callbacks

In addition to handling errors on a per-query basis (as described in Per-Query
Error Callbacks), you can also check for success or failure of the entire
transaction. For example:

**Sample transaction error callback**

```javascript
function myTransactionErrorCallback(error)
{
    alert('Oops.  Error was '+error.message+' (Code '+error.code+')');
}
 
function myTransactionSuccessCallback()
{
    alert("J. Doe's shirt is Mauve.");
}
 
var name = 'jdoe';
var shirt = 'mauve';
 
db.transaction(
    function (transaction) {
        transaction.executeSql("UPDATE people set shirt=? where name=?;",
            [ shirt, name ]); // array of values for the ? placeholders
    }, myTransactionErrorCallback, myTransactionSuccessCallback
);
```

Upon successful completion of the transaction, the success callback is called.
If the transaction fails because any portion thereof fails, the error
callback is called instead.

As with the error callback for individual queries, the transaction error
callback takes an error object parameter. For a list of possible error
codes that can appear in the `error.code` field, see [Error Codes](https://developer.apple.com/library/archive/documentation/iPhone/Conceptual/SafariJSDatabaseGuide/UsingtheJavascriptDatabase/UsingtheJavascriptDatabase.html).

## Error Codes

The error codes currently defined are as follows:

- `0` Other non-database-related error.
- `1` Other database-related error.
- `2` The version of the database is not the version that you requested.
- `3` Data set too large. There are limits in place on the maximum result
size that can be returned by a single query. If you see this error, you
should either use the `LIMIT` and `OFFSET` constraints in the query to reduce
the number of results returned or rewrite the query to return a more specific
subset of the results.
- `4` Storage limit exceeded. Either the space available for storage is
exhausted or the user declined to allow the database to grow beyond the
existing limit.
- `5` Lock contention error. If the first query in a transaction does not
modify data, the transaction takes a read-write lock for reading. It then
upgrades that lock to a writer lock if a subsequent query attempts to modify
data. If another query takes a writer lock ahead of it, any reads prior
to that point are untrustworthy, so the entire transaction must be repeated.
If you receive this error, you should retry the transaction.
- `6` Constraint failure. This occurs when an `INSERT`, `UPDATE`, or `REPLACE`
query results in an empty set because a constraint on a table could not be
met. For example, you might receive this error if it would cause two rows
to contain the same non-null value in a column marked as the primary key
or marked with the `UNIQUE` constraint.

Additional error codes may be added in the future as the need arises.

## Working With Database Versions

To make it easier for you to enhance your application without breaking
compatibility with earlier versions of your databases, the JavaScript
database supports versioning. With this support, you can modify the schema
atomically, making changes in the process of doing so.

When you open a database, if the existing version matches the version you
specify, the database is opened. Otherwise, the `openDatabase` call throws
an exception with a value of `2`. See Error Codes for more possible exception values.

If you specify an empty string for the version, the database is opened
regardless of the database version. You can then query the version by examining
the database object’s version property. For example:

**Obtaining the current database version**

```javascript
var db = openDatabase(shortName, "", displayName, maxSize);
var version = db.version; // For example, "1.0"
```

Once you know what version you are dealing with, you can atomically update
the database to a new version (optionally with a modified schema or modified
data) by calling the `changeVersion` method. For example:

**Changing database versions**

```javascript
function cv_1_0_2_0(transaction)
{
        transaction.executeSql('alter table people rename to person', [], nullDataHandler, errorHandler);
}
 
function oops_1_0_2_0(error)
{
    alert('oops in 1.0 -> 2.0 conversion.  Error was '+error.message);
    alert('DB Version: '+db.version);
    return true; // treat all errors as fatal
}
 
function success_1_0_2_0()
{
    alert("Database changed from version 1.0 to version 2.0.");
}
 
function testVersionChange()
{
    var db = getDB();
 
    if (!db) {
        alert('Could not open database connection.');
    }
 
    if (db.changeVersion) {
        alert('cv possible.');
    } else {
        alert('version changes not possible in this browser version.');
    }
    if (db.version == "1.0") {
        try {
            // comment out for crash recovery.
            db.changeVersion("1.0", "2.0", cv_1_0_2_0, oops_1_0_2_0, success_1_0_2_0);
        } catch(e) {
            alert('changeversion 1.0 -> 2.0 failed');
            alert('DB Version: '+db.version);
        }
    }
}
```

> **Note**: Calling the above function renames the table `people` to `person`.
> If you create a page containing the examples from this chapter, the other
> code will recreate the `people` table on the next page load, and a second
> rename will fail because the `person` table will already exist from the
> previous rename. Thus, to test this function more than once, you would
> have to execute the query `DROP TABLE person;` prior to renaming the `people` table.

In some versions of Safari, the database version field does not change
after a `changeVersion` call until you reload the page. Usually, this is not
a problem. However, it is a problem if you call the `changeVersion` method
more than once.

Unfortunately, the only way for your code to see the new version number is
by closing the browser window. If you get an error code `2` (see Error Codes)
and the database version you passed in for the old version matches the version
in `db.version`, you should either assume that the version change already
happened or display an alert instructing the user to close and reopen the
browser window.
