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
