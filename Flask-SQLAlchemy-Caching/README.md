# Flask-SQLAlchemy Caching

The following gist is an extract of the article [Flask-SQLAlchemy Caching](http://www.debrice.com/flask-sqlalchemy-caching/). It allows automated simple cache query and invalidation of cache relations through event among other features.

## Usage

### retrieve one object

    # pulling one User object
    user = User.query.get(1)
    # pulling one User object from cache
    user = User.cache.get(1)

### retrieve a list of object

    # user is the object we pulled earlier (either from cache or not)
    # Using the standard query (database hit)
    email_addresses = EmailAddress.query.filter(user_id=1)
    # pulling the same results from cache
    email_addresses = EmailAddress.cache.filter(user_id=1)

## Install on your model

    from caching import CacheableMixin, query_callable, regions
    
    class User(db.Model, CacheableMixin):
        cache_label = "default" # region's label to use
        cache_regions = regions # regions to store cache
        # Query handeling dogpile caching
        query_class = query_callable(regions)
        
        id = db.Column(db.Integer, primary_key=True)
        username = db.Column(db.String(80), unique=True)
        email = db.Column(db.String(120), unique=True)