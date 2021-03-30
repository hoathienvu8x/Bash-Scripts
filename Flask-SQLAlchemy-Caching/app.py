# file: app.py
# Full article: http://www.debrice.com/flask-sqlalchemy-caching/

import random

from flask import Flask
from flask.ext.sqlalchemy import SQLAlchemy
from caching import CacheableMixin, regions, query_callable


app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:////tmp/test.db'
app.debug = True
db = SQLAlchemy(app)

# To generate names and email in the DB
FIRST_NAMES = (
"JAMES", "JOHN", "ROBERT", "MICHAEL", "WILLIAM", "DAVID", "RICHARD", "CHARLES", "JOSEPH",
"THOMAS", "CHRISTOPHER", "DANIEL", "PAUL", "MARK", "DONALD", "GEORGE", "KENNETH",
"STEVEN", "EDWARD", "BRIAN", "RONALD", "ANTHONY", "KEVIN", "JASON", "MATTHEW", "GARY",
"TIMOTHY", "JOSE", "LARRY", "JEFFREY", "FRANK", "SCOTT", "ERIC", "STEPHEN", "ANDREW",
"RAYMOND", "GREGORY", "JOSHUA", "JERRY", "DENNIS", "WALTER", "PATRICK", "PETER", "HAROLD")

LAST_NAMES = (
"SMITH", "JOHNSON", "WILLIAMS", "JONES", "BROWN", "DAVIS", "MILLER", "WILSON", "MOORE",
"TAYLOR", "ANDERSON", "THOMAS", "JACKSON", "WHITE", "HARRIS", "MARTIN", "THOMPSON",
"GARCIA", "MARTINEZ", "ROBINSON", "CLARK", "RODRIGUEZ", "LEWIS", "LEE", "WALKER", "HALL",
"ALLEN", "YOUNG", "HERNANDEZ", "KING", "WRIGHT", "LOPEZ", "HILL", "SCOTT", "GREEN")

DOMAINS = ['gmail.com', 'yahoo.com', 'msn.com', 'facebook.com', 'aol.com', 'att.com']


class User(CacheableMixin, db.Model):
    cache_label = "default"
    cache_regions = regions
    #cache_pk = "username" # for custom pk
    query_class = query_callable(regions)

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80))
    email = db.Column(db.String(120))
    views = db.Column(db.Integer, default=0)

    def __init__(self, username, email):
        self.username = username
        self.email = email

    def __repr__(self):
        return '<User %r>' % self.username


@app.route('/views/<int:views>/')
def user_with_x_views(views):
    html_lines = []
    for user in User.cache.filter(views=views):
        html_lines.append(
          """<td>%s</td>
             <td>%s</td>
             <td>%s</td>
             <td><a href="/update/%s/">update</a></td>
             <td><a href="/%s/">view (%s)</a></td>""" % \
            (user.id, user.username, user.email, user.id, user.id, user.views))
    return '<table><tr>%s</tr></table>' % '</tr><tr>'.join(html_lines)


@app.route('/')
def all_user():
  html_lines = []
  # Cache alternative to User.query.filter()
  # We could also use User.query.options(User.cache.from_cache("my cache")).filter()
  # and we would manually invalidate "my_cache":
  # User.cache.flush("my_cache")
  for user in User.cache.filter():
      html_lines.append("""
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
        <td><a href="/update/%s/">update</a></td>
        <td><a href="/%s/">view (%s)</a></td>""" % \
        (user.id, user.username, user.email, user.id, user.id, user.views))
  return '<table><tr>%s</tr></table>' % '</tr><tr>'.join(html_lines)


@app.route('/update/<int:user_id>/')
def update_user(user_id):
    # alternative from User.query.get(user_id)
    user = User.cache.get(user_id)
    # updating views count will clear listing related to the previous
    # views value, the new views value, the "all" unfiltered listing
    # and the object cache itself
    user.views = user.views + 1
    db.session.add(user)
    db.session.commit()
    return '<h1>%s</h1><p>email: %s<br>views: %s</p><a href="/">back</a>' % \
        (user.username, user.email, user.views)


@app.route('/<int:user_id>/')
def view_user(user_id):
    # alternative from User.query.get(user_id)
    user = User.cache.get(user_id)
    return '<h1>%s</h1><p>email: %s<br>views: %s</p><a href="/">back</a>' % \
        (user.username, user.email, user.views)


def random_user():
    first_name = random.choice(FIRST_NAMES)
    last_name = random.choice(LAST_NAMES)
    email = "%s.%s@%s" % (first_name, last_name, random.choice(DOMAINS))
    return User(username="%s_%s" % (first_name, last_name), email=email)


@app.route('/init_db/')
def init_db():
    db.drop_all()
    db.create_all()
    for i in range(50):
        db.session.add(random_user())
    db.session.commit()
    return 'DB initialized'


if __name__ == '__main__':
    app.run()