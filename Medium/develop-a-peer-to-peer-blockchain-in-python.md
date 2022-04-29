---
title: Develop a Peer to Peer Blockchain in Python
link: https://skolo-online.medium.com/develop-a-peer-to-peer-blockchain-in-python-f7c9bdbefcda
author: Skolo Online Learning
---

![](https://miro.medium.com/max/1182/1*DtY_cF2x-D9YrgO0Wt9upw.jpeg)

Let us go through the process to develop a peer to peer blockchain in python.
Our development environment will be a Virtual Private Server running in Ubuntu.
You can purchase a droplet from Digital Ocean for $5, cancel it when you
are done.

## Set-up VPS remote repository

This is a crucial step, we will be writing the code on out personal computers
but pushing it to the VPS via ssh. The code will be run on the VPS, which
is already now set up with Python virtual environment. Follow the steps below
to create the repo and link it to personal computer:

**In the VPS (Virtual Server)** — Create two directories, call one `blockchain`
and the other `repo`.

```bash
mkdir blockchain repo
```

Then cd in to the blockchain folder and create empty git repo

```bash
cd blockchain
git init
cd ..
```

Then cd in to repo and create bare git repo

```bash
cd repo
git init --bare
```

Add the following file in to the `hooks/post-receive`

```bash
sudo nano hooks/post-receive
#!/bin/bash
git --work-tree=/path/to/blockchain/folder/ --git-dir=/path/to/repo/folder/repo checkout -f
sudo chmod +x hooks/post-receive
```

Then you need to run the following — in your **personal computer**, ensure
you have ssh sign in to root of the VPS set-up and you have the password
or ssh keys in your computer

This code must be run in the file directory where you are building the code
from on your personal computer.

```bash
git init
git add .
git commit -m "initial commit -- or anything you want to call the commit"
git remote add origin root@41.xx.xx.xx:/path/to/the/repo/folder/repo
```

Now we have created a git repo, committed changes and added remote repo
we need to push the changed across.

```bash
git push origin master
```

Every time you make a change — you will need to push changes before running
the code.

## Peer to Peer Blockchain in Python code:

The files will be nested in a flask application for a reason, for now just
work with the standard Flask set-up, plus some additional classes:

```text
|
|__ static (empty for now, we will use bootsrap CDN)
|__ templates
|     |__ index.html 
|     |__ 404.html
|
|__ app.py
|__ config.py
|__ blockchain.py
|__ account.py
|__ peerServer.py
```

## `Blockchain.py` file

Makes more sense to start with this file. In here we will write code that
deals with the blockchain itself. A blockchain is a series of blocks — each
block contains the following: (1) index, (2) hash of previous block, (3)
nonce, (4) the data, (5) timestamp and (6) the hash of this block.

The index represents the number the block has in the chain of blocks. The
previous hash — connects this block to he previous one, by recording its
hash — which is then used to calculate the hash of this block. A nonce is
a random number calculated when we get the hash of the current block. The
data — which can be anything, even a legally binding contract. The hash is
the data signature of everything in the block.

***Genesis block*** — is the first block in the chain, the values are easier
to estimate.

![](https://miro.medium.com/max/1400/1*PuThxDXQkfOkcrv5wkwUcA.png)

In this file we will include functions for:

- Adding transactions to the blockchain
- Mining — proof of work
- Verifying transaction signatures

### _Adding transactions to the pool:_

In our blockchain transactions will come from two different sources: the
front-end application (hence we needed Flask) and broadcasts from other nodes.
When we receive these transactions, we will add then to our own transaction
pool. Our transaction pool is currently an SQL database — hosted on the
same server.

### _Proof of work — mining:_

The type of blockchain created here is — Proof of Work. This means, in order
to add new blocks to the chain, a computation must be carried out. We will
be calculating the nonce value, a random number required to give us a data
signature that meets certain requirements.

Difficulty is introduced to manage how fast blocks can be created, to make
it a process that takes time. The computer once it has the data that must
fit in the block — must now hash that data as many times as required to find
that hash that meets the requirements set.

The harder we make the requirements, the longer it will take this computer
to find the correct nonce. Therefore the difficulty is determined by setting
of the requirements, which can be anything. In our blockchain — we want all
the hashes to have 00009 at the beginning. There is some difficulty — but
not too much, we are a private blockchain.

### _Verifying transaction signatures:_

This function is written to ensure the signatures in the pool are valid before
adding the data to the blockchain to be mined. Our signatures are created
using Eliptic Curve Cryptography methods — from the private key of the account
and the data itself.

No two types of data will have the same signature and if we have the signature
and the data, we can use the public key of the account to verify the validity
of the signature. We do this to make sure the person who sent the data is
the owner of the account associated with the data.

### Client Facing Flask Application

We created a Flask application to enable us to communicate with a peer in
the blockchain — the endpoints include:

- Home page for submitting applications
- End-point to view the transactions currently in the transaction pool
- End-point to view the chain and its data
- Point to connect a new node to the network — a new node would need to send
a post request to this end-point, to be able to be added to the network of nodes.

## MYSQL Database

The database is required to store data for the node. Each node connected
will have a separate database and manage its own database.

The database is created outside of the flask application, with the tables
etc. The data in the database can be added and removed via the flask application.

## Other files

We have account.py file and peer2peer files as well, all the code is available
on github. It would take too long to go through all these files — review
on [Github](https://github.com/tatiblockchain/python-blockchain)
