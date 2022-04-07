---
title: JavaScript template engine in just 20 lines
link: https://krasimirtsonev.com/blog/article/Javascript-template-engine-in-just-20-line
author: Krasimir Tsonev
---

I'm still working on my JavaScript based preprocessor - AbsurdJS. It started
as a CSS preprocessor, but later it was expanded to CSS/HTML preprocessor.
Shortly, it allows JavaScript to CSS/HTML conversion. Of course, because
it generates HTML it was normal to act as a template engine. I.e. somehow
to fill the markup with data.

So, I wanted to write a simple template engine logic, which work nicely
with my current implementation. AbsurdJS is mainly distributed as a NodeJS
module, but it is also ported for a client-side usage. Having this in mind,
I knew that I can't really get some of the existing engines. That's because
most of the them are only NodeJS based and it will be difficult to replicate
them in the browser. I needed something small, written in pure JavaScript.
I landed on this blog post by John Resig. It looks like the thing which I
needed. I change it a bit and it fits into 20 lines. I think that it is
quite interesting how the script works. In this article I'll recreate the
engine step by step so you could see the wonderful idea which originally
came from John.

Here is what we could have in the beginning:

```javascript
var TemplateEngine = function(tpl, data) {
    // magic here ...
}
var template = 'Hello, my name is <%name%>. I\\'m <%age%> years old.';
console.log(TemplateEngine(template, {
    name: "Krasimir",
    age: 29
}));
```

A simple function, which takes our template and a data object. As you may
guess, the result which we want to achieve at the end is:

```bash
Hello, my name is Krasimir. I'm 29 years old.
```

The very first thing which we have to do is to take the dynamic blocks inside
the template. Later we will replace them with the real data passed to the
engine. I decided to use regular expression to achieve this. That's not my
strongest part, so feel free to comment and suggest a better RegExp.

```javascript
var re = /<%([^%>]+)?%>/g;
```

We will catch all the pieces which start with `<%` and end with `%>`. The
flag g (global) means that we will get not one, but all the matches. There
are a lot of methods which accept regular expressions. However, what we
need is an array containing the strings. That's what `exec` does.

```javascript
var re = /<%([^%>]+)?%>/g;
var match = re.exec(tpl);
```

If we `console.log` the match variable we will get:

```javascript
[
    "<%name%>",
    " name ", 
    index: 21,
    input: 
    "Hello, my name is <%name%>. I\\'m <%age%> years old."
]
```

So, we got the data, but as you can see the returned array has only one
element. And we need to process all the matches. To do this we should wrap
our logic into `while` loop.

```javascript
var re = /<%([^%>]+)?%>/g, match;
while(match = re.exec(tpl)) {
    console.log(match);
}
```

If you run the code above you will see that the both `<%name%>` and `<%age%>` are shown.

Now it gets interesting. We have to replace placeholders with the real data
passed to the function. The most simple thing which we can use is to use
`.replace` method against the template. We could write something like this:

```javascript
var TemplateEngine = function(tpl, data) {
    var re = /<%([^%>]+)?%>/g, match;
    while(match = re.exec(tpl)) {
        tpl = tpl.replace(match[0], data[match[1]])
    }
    return tpl;
}
```

Ok, this works, but of course it is not enough. We have really simple object
and it is easy to use `data["property"]`. But in practice we may have complex
nested objects. Let's for example change our data to

```javascript
{
    name: "Krasimir Tsonev",
    profile: { age: 29 }
}
```

This doesn't work because when we type `<%profile.age%>` we will get `data["profile.age"]`
which is actually `undefined`. So, we need something else. The `.replace` method
will not work our case. The very best thing will be to put real JavaScript
code between `<%` and `%>`. It will be nice if it is evaluated against the passed
data. For example:

```javascript
var template = 'Hello, my name is <%this.name%>. I\\'m <%this.profile.age%> years old.';
```

How is this possible? John used the `new Function` syntax. I.e. creating a
function from strings. Let's see a simple example.

```javascript
var fn = new Function("arg", "console.log(arg + 1);");
fn(2); // outputs 3
```

`fn` is a real function which takes one argument. It's body is `console.log(arg + 1);`.
In other words the above code is equal to:

```javascript
var fn = function(arg) {
    console.log(arg + 1);
}
fn(2); // outputs 3
```

We are able to define a function, its arguments and its body from simple
strings. That's exactly what we need. But before to create such a function
we need to construct its body. The method should return the final compiled
template. Let's get the string used so far and try to imagine how it will
look like.

```javascript
return 
"Hello, my name is " + 
this.name + 
". I\\'m " + 
this.profile.age + 
" years old.";
```

For sure, we will split the template into text and meaningful JavaScript.
As you can see above we may use a simple concatenation and produce the wanted
result. However, this approach doesn't align on 100% with our needs. Because
we are passing working JavaScript sooner or later we will want to make a loop.
For example:

```javascript
var template = 
'My skills:' + 
'<%for(var index in this.skills) {%>' + 
'<%this.skills[index]%>' +
'<%}%>';
```

If we use concatenation the result will be:

```javascript
return
'My skills:' + 
for(var index in this.skills) { +
'' + 
this.skills[index] +
'' +
}
```

Of course this will produce an error. That's why I decided to follow the
logic used in the John's article. I.e. put all the strings in an array and
join its elements at the end.

```javascript
var r = [];
r.push('My skills:'); 
for(var index in this.skills) {
r.push('');
r.push(this.skills[index]);
r.push('');
}
return r.join('');
```

The next logical step is to collect the different lines of for custom generated
function. We already have some information extracted from the template.
We know the content of the placeholders and their position. So, by using
a helper variable (cursor) we are able to produce the desire result.

```javascript
var TemplateEngine = function(tpl, data) {
    var re = /<%([^%>]+)?%>/g,
        code = 'var r=[];\\n',
        cursor = 0, match;
    var add = function(line) {
        code += 'r.push("' + line.replace(/"/g, '\\\\"') + '");\\n';
    }
    while(match = re.exec(tpl)) {
        add(tpl.slice(cursor, match.index));
        add(match[1]);
        cursor = match.index + match[0].length;
    }
    add(tpl.substr(cursor, tpl.length - cursor));
    code += 'return r.join("");'; // <-- return the result
    console.log(code);
    return tpl;
}
var template = 'Hello, my name is <%this.name%>. I\\'m <%this.profile.age%> years old.';
console.log(TemplateEngine(template, {
    name: "Krasimir Tsonev",
    profile: { age: 29 }
}));
```

The code variable holds the body of the function. It starts with definition
of the array. As I said, cursor shows us where in the template we are. We
need such a variable to go through the whole string and skip the data blocks.
An additional add function is created. It's job is to append lines to the
code variable. And here is something tricky. We need to escape the double
quotes, because otherwise the generated script will not be valid. If we run
that example and check the console we will see:

```javascript
var r=[];
r.push(<p>Hello, my name is ");
r.push("this.name");
r.push(". I'm ");
r.push("this.profile.age");
return r.join("");
```

Hm ... not what we wanted. this.name and this.profile.age should not be
quoted. A little improvement of the add method solves the problem.

```javascript
var add = function(line, js) {
    js? code += 'r.push(' + line + ');\\n' :
        code += 'r.push("' + line.replace(/"/g, '\\\\"') + '");\\n';
}
var match;
while(match = re.exec(tpl)) {
    add(tpl.slice(cursor, match.index));
    add(match[1], true); // <-- say that this is actually valid js
    cursor = match.index + match[0].length;
}
```

The placeholders' content is passed along with a boolean variable. Now this
generates the correct body.

```javascript
var r=[];
r.push("<p>Hello, my name is ");
r.push(this.name);
r.push(". I'm ");
r.push(this.profile.age);
return r.join("");
```

All we need to do is to create the function and execute it. At the end of
our template engine, instead of returning `tpl`:

```javascript
return new Function(code.replace(/[\\r\\t\\n]/g, '')).apply(data);
```

We don't even need to send any arguments to the function. We use the `apply`
method to call it. It automatically sets the scope. That's the reason of
having `this.name` working. The this actually points to our data.

We are almost done. One last thing. We need to support more complex operations,
like `if/else` statements and loops. Let's get the same example from above
and try the code so far.

```javascript
var template = 
'My skills:' + 
'<%for(var index in this.skills) {%>' + 
'<%this.skills[index]%>' +
'<%}%>';
console.log(TemplateEngine(template, {
    skills: ["js", "html", "css"]
}));
```

The result is an error `Uncaught SyntaxError: Unexpected token for.` If we
debug a bit and print out the code variable we will see the problem.

```javascript
var r=[];
r.push("My skills:");
r.push(for(var index in this.skills) {);
r.push("<a href=\\"\\">");
r.push(this.skills[index]);
r.push("</a>");
r.push(});
r.push("");
return r.join("");
```

The line containing the `for` loop should not be pushed to the array. It should
be just placed inside the script. To achieve that we have to make one more
check before to attach something to code.

```javascript
var re = /<%([^%>]+)?%>/g,
    reExp = /(^( )?(if|for|else|switch|case|break|{|}))(.*)?/g,
    code = 'var r=[];\\n',
    cursor = 0;
var add = function(line, js) {
    js? code += line.match(reExp) ? line + '\\n' : 'r.push(' + line + ');\\n' :
        code += 'r.push("' + line.replace(/"/g, '\\\\"') + '");\\n';
}
```

A new regular expression is added. It tells us if the javascript code starts
with `if`, `for`, `else`, `switch`, `case`, `break`, `{` or `}`. If yes, then it simply adds
the line. Otherwise it wraps it in a push statement. The result is:

```javascript
var r=[];
r.push("My skills:");
for(var index in this.skills) {
r.push("<a href=\\"#\\">");
r.push(this.skills[index]);
r.push("</a>");
}
r.push("");
return r.join("");
```

And of course, everything is properly compiled.

```javascript
My skills:jshtmlcss
```

The latest fix gives us a lot of power actually. We may apply complex logic
directly into the template. For example:

```javascript
var template = 
'My skills:' + 
'<%if(this.showSkills) {%>' +
    '<%for(var index in this.skills) {%>' + 
    '<a href="#"><%this.skills[index]%></a>' +
    '<%}%>' +
'<%} else {%>' +
    '<p>none</p>' +
'<%}%>';
console.log(TemplateEngine(template, {
    skills: ["js", "html", "css"],
    showSkills: true
}));
```

To improve the things a bit I added a few minor optimizations and the [final version](https://github.com/krasimir/absurd/blob/master/lib/processors/html/helpers/TemplateEngine.js)
looks like that:

```javascript
var TemplateEngine = function(html, options) {
    var re = /<%([^%>]+)?%>/g, reExp = /(^( )?(if|for|else|switch|case|break|{|}))(.*)?/g, code = 'var r=[];\\n', cursor = 0, match;
    var add = function(line, js) {
        js? (code += line.match(reExp) ? line + '\\n' : 'r.push(' + line + ');\\n') :
            (code += line != '' ? 'r.push("' + line.replace(/"/g, '\\\\"') + '");\\n' : '');
        return add;
    }
    while(match = re.exec(html)) {
        add(html.slice(cursor, match.index))(match[1], true);
        cursor = match.index + match[0].length;
    }
    add(html.substr(cursor, html.length - cursor));
    code += 'return r.join("");';
    return new Function(code.replace(/[\\r\\t\\n]/g, '')).apply(options);
}
```

It's even less - 15 lines.
