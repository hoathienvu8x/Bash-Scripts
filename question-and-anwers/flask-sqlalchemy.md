# Using multiple databases with single sqlalchemy model

I want to use multiple database engines with a single sqlalchemy database model.

Following situation: I have a photo album software (python) and the different albums are stored in different folders. In each folder is a separate sqlite database with additional information about the photos. I don't want to use a single global database because with this way I can simply move, delete and copy albums on a folder base. Opening a single album is fairly straightforward:

Creating a db session:

```python
maker = sessionmaker(autoflush=True, autocommit=False,
                 extension=ZopeTransactionExtension())
DBSession = scoped_session(maker)
```


Base class and metadata for db model:

```python
DeclarativeBase = declarative_base()
metadata = DeclarativeBase.metadata
```


Defining database model (shortened):

```python
pic_tag_table = Table('pic_tag', metadata,
                      Column('pic_id', Integer,
                             ForeignKey('pic.pic_id'),
                             primary_key=True),
                      Column('tag_id', Integer,
                             ForeignKey('tag.tag_id'),
                             primary_key=True))


class Picture(DeclarativeBase):
    __tablename__ = 'pic'

    pic_id = Column (Integer, autoincrement = True, primary_key=True)
    ...


class Tags(DeckarativeBase):
    __tablename__ = 'tag'

    tag_id = Column (Integer, autoincrement = True, primary_key=True)
    ...

    pictures = relation('Picture', secondary=pic_tag_table, backref='tags')
```


And finally open the connection:

```python
engine = engine_from_config(config, '...')
DBSession.configure(bind=engine)
metadata.bind = engine
```


This works well for opening one album. Now I want to open multiple albums (and db connections) the same time. Every album has the same database model so my hope is that I can reuse it. My problem is that the model class definition is inheritet from the declarative base which is connected to the metadata and the database engine. I want to connect the classes to different metadata with different enginges. Is this possible?

P.S.: I also want to query the databases via the ORM, e.g. DBSession.query(Picture).all() (or DBSession[0], ... for multiple sessions on different databases - so not one query for all pictures in all databases but one ORM style query for querying one database)

You can achieve this with multiple engines and sessions (you don't need multiple metadata):

```python
engine1 = create_engine("sqlite:///tmp1.db")
engine2 = create_engine("sqlite:///tmp2.db")
Base.metadata.create_all(bind=engine1)
Base.metadata.create_all(bind=engine2)
session1 = Session(bind=engine1)
session2 = Session(bind=engine2)
print(session1.query(Picture).all())  # []
print(session2.query(Picture).all())  # []
session1.add(Picture())
session1.commit()
print(session1.query(Picture).all())  # [Picture]
print(session2.query(Picture).all())  # []
session2.add(Picture())
session2.commit()
print(session1.query(Picture).all())  # [Picture]
print(session2.query(Picture).all())  # [Picture]
session1.close()
session2.close()
```


For `scoped_session`, you can create multiple of those as well.

```python
engine1 = create_engine("sqlite:///tmp1.db")
engine2 = create_engine("sqlite:///tmp2.db")
Base.metadata.create_all(bind=engine1)
Base.metadata.create_all(bind=engine2)
Session1 = scoped_session(sessionmaker(bind=engine1))
Session2 = scoped_session(sessionmaker(bind=engine2))
session1 = Session1()
session2 = Session2()
...
```


If you have a variable number of databases you need to have open, `scoped_session` might be a little cumbersome. You'll need some way to keep track of them.

# SQLAlchemy transparent access to same table accross databases

I'm using MySQL and SQLAlchemy, and I have two databases with identical tables, but different data. Database db1 is used for "hot" data, therefore has much better performance, and db2 for archival. I won't ever need to perform joins across databases, since all related data is moved accordingly.

Whenever I insert or update new data, it goes into db1, and db2 is basically read only, so it's simple for me to have two engines and use a db1 session whenever I commit. However, is there any simple way for SQLAlchemy to transparently query data from both and consolidate the results? For instance, when I add a new row, it always goes into db1, but when I query one with the primary key, I'd like it to search the tables in both db1 and db2 without having to refactor all queries in my code.

You are looking for the [Horizontal Sharding](http://sqlalchemy.readthedocs.org/en/rel_0_9/orm/extensions/horizontal_shard.html) extension, an example usage of which is provided in the [documentation](http://sqlalchemy.readthedocs.org/en/rel_0_9/_modules/examples/sharding/attribute_shard.html). This allows you to use a special ShardedSession which uses various dispatch functions to decide which database to talk to.

```python
def shard_chooser(mapper, instance, clause=None):
    """return a shard key based on the instance being handled"""

def id_chooser(query, ident):
    """return a shard key based on primary key"""

def query_chooser(query):
    """return a shard key based on the query"""

create_session = sessionmaker(class_=ShardedSession)
create_session.configure(
    shards={
        # map keys to engines
    },
    shard_chooser=shard_chooser,
    id_chooser=id_chooser,
    query_chooser=query_chooser
)
```

# Dynamically setting __tablename__ for sharding in SQLAlchemy?

In order to handle a growing database table, we are sharding on table name. So we could have database tables that are named like this:

```
table_md5one
table_md5two
table_md5three
```


All tables have the exact same schema.

How do we use SQLAlchemy and dynamically specify the **tablename** for the class that corresponds to this? Looks like the declarative_base() classes need to have **tablename** pre-specified.

There will eventually be too many tables to manually specify derived classes from a parent/base class. We want to be able to build a class that can have the tablename set up dynamically (maybe passed as a parameter to a function.)

OK, we went with the custom SQLAlchemy declaration rather than the declarative one.

So we create a dynamic table object like this:

```python
from sqlalchemy import MetaData, Table, Column

def get_table_object(self, md5hash):
    metadata = MetaData()
    table_name = 'table_' + md5hash
    table_object = Table(table_name, metadata,
        Column('Column1', DATE, nullable=False),
        Column('Column2', DATE, nullable=False)
    )
    clear_mappers()
    mapper(ActualTableObject, table_object)
    return ActualTableObject
```


Where ActualTableObject is the class mapping to the table.

In [Augmenting the Base](https://docs.sqlalchemy.org/en/13/orm/extensions/declarative/mixins.html#augmenting-the-base) you find a way of using a custom `Base` class that can, for example, calculate the `__tablename__` attribure dynamically:

```python
class Base(object):
    @declared_attr
    def __tablename__(cls):
        return cls.__name__.lower()
```


The only problem here is that I don't know where your hash comes from, but this should give a good starting point.

If you require this algorithm not for all your tables but only for one you could just use the `declared_attr` on the table you are interested in sharding.

Because I insist to use declarative classes with their `__tablename__` dynamically specified by given parameter, after days of failing with other solutions and hours of studying SQLAlchemy internals, I come up with the following solution that I believe is simple, elegant and race-condition free.

```python
def get_model(suffix):
    DynamicBase = declarative_base(class_registry=dict())

    class MyModel(DynamicBase):
        __tablename__ = 'table_{suffix}'.format(suffix=suffix)

        id = Column(Integer, primary_key=True)
        name = Column(String)
        ...

    return MyModel
```


Since they have their own `class_registry`, you will not get that warning saying:

This declarative base already contains a class with the same class name and module name as mypackage.models.MyModel, and will be replaced in the string-lookup table.

Hence, you will not be able to reference them from other models with string lookup. However, it works perfectly fine to use these on-the-fly declared models for foreign keys as well:

```python
ParentModel1 = get_model(123)
ParentModel2 = get_model(456)

class MyChildModel(BaseModel):
    __tablename__ = 'table_child'

    id = Column(Integer, primary_key=True)
    name = Column(String)
    parent_1_id = Column(Integer, ForeignKey(ParentModel1.id))
    parent_2_id = Column(Integer, ForeignKey(ParentModel2.id))
    parent_1 = relationship(ParentModel1)
    parent_2 = relationship(ParentModel2)
```


If you only use them to query/insert/update/delete without any reference left such as foreign key reference from another table, they, their base classes and also their class_registry will be garbage collected, so no trace will be left.

you can write a function with tablename parameter and send back the class with setting appropriate attributes.

```python
def get_class(table_name):

   class GenericTable(Base):

       __tablename__ = table_name

       ID= Column(types.Integer, primary_key=True)
       def funcation(self):
        ......
   return GenericTable
```


Then you can create a table using:

```python
get_class("test").__table__.create(bind=engine)  # See sqlachemy.engine
```


Try this

```python
import zlib

from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, Integer, BigInteger, DateTime, String

from datetime import datetime

BASE = declarative_base()
ENTITY_CLASS_DICT = {}


class AbsShardingClass(BASE):

    __abstract__ = True

def get_class_name_and_table_name(hashid):
    return 'ShardingClass%s' % hashid, 'sharding_class_%s' % hashid

def get_sharding_entity_class(hashid):
    """
    @param hashid: hashid
    @type hashid: int
    @rtype AbsClientUserAuth
    """

    if hashid not in ENTITY_CLASS_DICT:
        class_name, table_name = get_class_name_and_table_name(hashid)
        cls = type(class_name, (AbsShardingClass,),
                   {'__tablename__': table_name})
        ENTITY_CLASS_DICT[hashid] = cls

    return ENTITY_CLASS_DICT[hashid]

cls = get_sharding_entity_class(1)
print session.query(cls).get(100)
```


Instead of using imperative creating Table object, you can use usual declarative_base and make a closure to set a table name as the following:

```python
def make_class(Base, table_name):
    class User(Base):
        __tablename__ = table_name
        id = Column(Integer, primary_key=True)
        name= Column(String)

    return User

Base = declarative_base()
engine = make_engine()
custom_named_usertable = make_class(Base, 'custom_name')
Base.metadata.create_all(engine)

session = make_session(engine)
new_user = custom_named_usertable(name='Adam')
session.add(new_user)
session.commit()
session.close()
engine.dispose()
```

# SQLAlchemy - Multiple Database Issues

We are making a game server using SQLAlchemy.

because game servers must be very fast, we have decided to separate databases depending on user ID(integer).

so for example I did it successfully like the following.

```python
from threading import Thread
from sqlalchemy import Column, Integer, String, DateTime, create_engine
from sqlalchemy.ext.declarative import declarative_base, DeferredReflection
from sqlalchemy.orm import sessionmaker

DeferredBase = declarative_base(cls=DeferredReflection)
class BuddyModel(DeferredBase):
    __tablename__ = 'test_x'

    id = Column(Integer(), primary_key=True, autoincrement=True)
    value = Column(String(50), nullable=False)
```


and the next code will create multiple databases.

There will be test1 ~ test10 databases.

```python
for i in range(10):
    url = 'mysql://user@localhost/'
    engine = create_engine(url, encoding='UTF-8', pool_recycle=300)
    con = engine.connect()
    con.execute('create database test%d' % i)
```


the following code will create 10 separate engines.

the get_engine() function will give you an engine depending on the user ID.

(User ID is integer)

```python
engines = []
for i in range(10):
    url = 'mysql://user@localhost/test%d'% i

    engine = create_engine(url, encoding='UTF-8', pool_recycle=300)

    DeferredBase.metadata.bind = engine
    DeferredBase.metadata.create_all()
    engines.append(engine)

def get_engine(user_id):
    index = user_id%10
    return engines[index]
```


by running prepare function, the BuddyModel class will be prepared, and mapped to the engine.

```python
def prepare(user_id):
    engine = get_engine(user_id)
    DeferredBase.prepare(engine)
```


** The next code will do what I want to do exactly **

```python
for user_id in range(100):
    prepare(user_id)

    engine = get_engine(user_id)
    session = sessionmaker(engine)()
    buddy = BuddyModel()
    buddy.value = 'user_id: %d' % user_id
    session.add(buddy)
    session.commit()
```


But the problem is that when I do it in multiple threads, it just raise errors

```python
class MetalMultidatabaseThread(Thread):

    def run(self):
        for user_id in range(100):
            prepare(user_id)

            engine = get_engine(user_id)
            session = sessionmaker(engine)()
            buddy = BuddyModel()
            buddy.value = 'user_id: %d' % user_id
            session.add(buddy)
            session.commit()
threads = []
for i in range(100):
    t = MetalMultidatabaseThread()
    t.setDaemon(True)
    t.start()
    threads.append(t)

for t in threads:
    t.join()
```


the error message is ...

```python
ArgumentError: Class '<class '__main__.BuddyModel'>' already has a primary mapper defined. Use non_primary=True to create a non primary Mapper.  clear_mappers() will remove *all* current mappers from all classes.
```


so.. my question is that How CAN I DO MULTIPLE-DATABASE like the above architecture using SQLAlchemy?

this is called horizontal sharding and is a bit of a tricky use case. The version you have, make a session based on getting the engine first, will work fine. There are two variants of this which you may like.

One is to use the [horizontal sharding extension](http://docs.sqlalchemy.org/en/rel_0_9/orm/examples.html#examples-sharding). This extension allows you to create a Session to automatically select the correct node.

The other is more or less what you have, but less verbose. Build a Session class that has a [routing function](http://techspot.zzzeek.org/2012/01/11/django-style-database-routers-in-sqlalchemy/), so you at least could share a single session and say, `session.using_bind('engine1')` for a query instead of making a whole new session.

I have found an answer for my question.

For building up multiple-databases depending on USER ID (integer) just use session.

Before explain this, I want to expound on the database architecture more.

For example if the user ID 114 connects to the server, the server will determine where to retrieve the user's information by using something like this.

```
user_id%10 # <-- 4th database
```


Architecture

```
DATABASES 
  - DB0 <-- save all user data whose ID ends with 0 
  - DB1 <-- save all user data whose ID ends with 1
  .
  .
  .
  - DB8 <-- save all user data whose ID ends with 9
```


Here is the answer

First do not use bind parameter.. simply make it empty.

```python
Base = declarative_base()
```


Declare Model..

```python
class BuddyModel(Base):
    __tablename__ = 'test_x'

    id = Column(Integer(), primary_key=True, autoincrement=True)
    value = Column(String(50), nullable=False)
```


When you want to do CRUD ,make a session

```python
engine = get_engine_by_user_id(user_id)
session = sessionmaker(bind=engine)()

buddy = BuddyModel()
buddy.value = 'This is Sparta!! %d' % user_id
session.add(buddy)
session.commit()
```


engine should be the one matched with the user ID.

# Automap multiple databases with Flask-SQLAlchemy

I have an app currently working fine Automapping one database, but I need to access another database now as well. I tried to follow the Flask-SQLAlchemy documentation here: [http://flask-sqlalchemy.pocoo.org/2.1/binds/](http://flask-sqlalchemy.pocoo.org/2.1/binds/), but it doesn't seem to work with the automap_base.

The only changes I made were creating `SQLALCHEMY_BINDS` and adding the `__bind_key__` in **models.py**. The error I get is

```
sqlalchemy.exc.ArgumentError: Mapper Mapper|Table2|table2 could not assemble any primary key columns for mapped table 'table2'
```


However, both tables have a primary key column, and if I get rid of `SQLALCHEMY_BINDS`, set the URI to that of `db2`, and only have `table2` in **models.py**, everything works fine.

I'm clearly doing something wrong, but I have no idea what it is. It looks like Flask is still looking for `table2` in `db1`. I think my problem is that some change needs to be made to **__init__.py** as well, but I don't know what that would be.

**config.py**

```python
SQLALCHEMY_DATABASE_URI = 'mysql://user@host/db1'
SQLALCHEMY_BINDS = {
    'otherDB':        'mysql://user@host/db2',
}
```


**__init__.py**

```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.ext.automap import automap_base

app = Flask(__name__)
app.config.from_object('config')

db = SQLAlchemy(app)
db.Model = automap_base(db.Model)
from app import models
db.Model.prepare(db.engine, reflect=True)
```


**models.py**

```python
class Table1(db.Model):
    __tablename__ = 'table1'

class Table2(db.Model):
    __bind_key__ = 'otherDB'
    __tablename__ = 'table2'
```


`Automap` is a extension of **sqlalchemy** to reflect an existing database into a new model. It has not been baked into `flask-sqlalchemy`. Plz see the issue [here](https://github.com/mitsuhiko/flask-sqlalchemy/issues/398). You can connect to multiple databases with `Flask-SQLAlchemy` like this:

**__init__.py**

```python
from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config.from_object('config')

db = SQLAlchemy(app)

from app import models  

if __name__ == "__main__":
    # show the table schema
    print m3.Table1.__table__.c
    print m3.Table2.__table__.c
```


**models.py**

```
db.reflect() # reflection to get table meta


class Table1(db.Model):
    __tablename__ = 'table1'


class Table2(db.Model):
    __tablename__ = 'table2'
    __bind_key__ = 'otherDB'
```

# SQLAlchemy: Creating vs. Reusing a Session

Just a quick question: SQLAlchemy [talks about](http://docs.sqlalchemy.org/en/rel_0_7/orm/session.html#session-frequently-asked-questions) calling `sessionmaker()` once but calling the resulting `Session()` class each time you need to talk to your DB. For me that means the second I would do my first `session.add(x)` or something similar, I would first do

```py
from project import Session
session = Session()
```

What I did until now was to make the call `session = Session()` in my model *once* and then always import the same session anywhere in my application. Since this is a web-applications this would *usually* mean the same (as one view is executed).

But where is the difference? What is the disadvantage of using one session all the time against using it for my database stuff until my function is done and then creating a new one the next time I want to talk to my DB?

I get that if I use multiple threads, each one should get their own session. But using `scoped_session()`, I already make sure that problem doesn't exist, do I?

Please clarify if any of my assumptions are wrong.

`sessionmaker()` is a factory, it's there to encourage placing configuration options for creating new `Session` objects in just one place. It is optional, in that you could just as easily call `Session(bind=engine, expire_on_commit=False)` anytime you needed a new `Session`, except that its verbose and redundant, and I wanted to stop the proliferation of small-scale "helpers" that each approached the issue of this redundancy in some new and more confusing way.

So `sessionmaker()` is just a tool to help you create `Session` objects when you need them.

Next part. I think the question is, what's the difference between making a new `Session()` at various points versus just using one all the way through. The answer, not very much. `Session` is a container for all the objects you put into it, and then it also keeps track of an open transaction. At the moment you call `rollback()` or `commit()`, the transaction is over, and the `Session` has no connection to the database until it is called upon to emit SQL again. The links it holds to your mapped objects are weak referencing, provided the objects are clean of pending changes, so even in that regard the `Session` will empty itself out back to a brand new state when your application loses all references to mapped objects. If you leave it with its default `"expire_on_commit"` setting, then all the objects are expired after a commit. If that `Session` hangs around for five or twenty minutes, and all kinds of things have changed in the database the next time you use it, it will load all brand new state the next time you access those objects even though they've been sitting in memory for twenty minutes.

In web applications, we usually say, hey why don't you make a brand new `Session` on each request, rather than using the same one over and over again. This practice ensures that the new request begins "clean". If some objects from the previous request haven't been garbage collected yet, and if maybe you've turned off `"expire_on_commit"`, maybe some state from the previous request is still hanging around, and that state might even be pretty old. If you're careful to leave `expire_on_commit` turned on and to definitely call `commit()` or `rollback()` at request end, then it's fine, but if you start with a brand new `Session`, then there's not even any question that you're starting clean. So the idea to start each request with a new `Session` is really just the simplest way to make sure you're starting fresh, and to make the usage of `expire_on_commit` pretty much optional, as this flag can incur a lot of extra SQL for an operation that calls `commit()` in the middle of a series of operations. Not sure if this answers your question.

The next round is what you mention about threading. If your app is multithreaded, we recommend making sure the `Session` in use is local to...something. `scoped_session()` by default makes it local to the current thread. In a web app, local to the request is in fact even better. Flask-SQLAlchemy actually sends a custom "scope function" to `scoped_session()` so that you get a request-scoped session. The average Pyramid application sticks the Session into the "request" registry. When using schemes like these, the "create new Session on request start" idea continues to look like the most straightforward way to keep things straight.

In addition to the excellent zzzeek's answer, here's a simple recipe to quickly create throwaway, self-enclosed sessions:

```py
from contextlib import contextmanager

from sqlalchemy import create_engine
from sqlalchemy.orm import scoped_session, sessionmaker

@contextmanager
def db_session(db_url):
    """ Creates a context with an open SQLAlchemy session.
    """
    engine = create_engine(db_url, convert_unicode=True)
    connection = engine.connect()
    db_session = scoped_session(sessionmaker(autocommit=False, autoflush=True, bind=engine))
    yield db_session
    db_session.close()
    connection.close()
```

Usage:

```py
from mymodels import Foo

with db_session("sqlite://") as db:
    foos = db.query(Foo).all()
```
