---
title: How To Create A Template Engine Using JavaScript
link: https://hackernoon.com/how-to-create-new-template-engine-using-javascript-8f26313p
author: shadowtime2000
---

![](https://cdn.hackernoon.com/images/mInGmayyxOMvm3o6l2iN7KhHCib2-263334by.png)

Hi, it's me, @shadowtime2000, one of the maintainers of Eta, a fast embeddable
template engine. In this tutorial I will show to create an isomorphic
(browser/node) JavaScript template engine.

## The Design

The initial design of the template engine will be pretty simple. It will
simply interpolate values from a `data` object. It will use `{{valueName}}`
to interpolate values.

## Simple Rendering

First, lets create a simple rendering function which takes the template
and the data and it will render the value.

```javascript
var render = (template, data) => {
	return template.replace(/{{(.*?)}}/g, (match) => {
		return data[match.split(/{{|}}/).filter(Boolean)[0]]
	})
}
```

Basically, all that does is search for anything that is surrounded by the
brackets, and it replaces it with the name inside `data`. You can write your
templates like this and it will take it from the data object.

```bash
Hi, my name is {{name}}!
```

```javascript
render("Hi, my name is {{name}}!", {
    name: "shadowtime2000"
});
```

But there is a problem, you can't have spaces in the interpolations.

```javascript
render("Hi, my name is {{ name }}!", {
    name: "shadowtime2000"
})
/*
Hi, my name is undefined!
*/
```

This requires you to have spaces inside the data object, which isn't that
clean. We can make it allow spaces by trimming leading and ending whitespace
of the data name before interpolating.

```javascript
var render = (template, data) => {
	return template.replace(/{{(.*?)}}/g, (match) => {
		return data[match.split(/{{|}}/).filter(Boolean)[0].trim()]
	})
}
```

This is pretty good, but for larger templates it wouldn't be that fast
because it has to kind of parse it every time. That is why many template
engines support compilation, where the template is compiled into a faster
JS function which can take the data and interpolate it. Let's add compilation
to our template engine, but before we do, we need to add a special parsing function.

## Parsing

Since parsing can be a little boring, let's just reuse some code from another
JS template engine. I would have used the Eta parsing engine, but that has
been extremely optimized and can be pretty confusing to people. So, lets
use another popular JS template engine parsing code, mde/ejs. Do remember
to attribute them for the parsing engine.

```javascript
var parse = (template) => {
	let result = /{{(.*?)}}/g.exec(template);
	const arr = [];
	let firstPos;

	while (result) {
		firstPos = result.index;
		if (firstPos !== 0) {
			arr.push(template.substring(0, firstPos));
			template = template.slice(firstPos);
		}

		arr.push(result[0]);
		template = template.slice(result[0].length);
		result = /{{(.*?)}}/g.exec(template);
	}

	if (template) arr.push(template);
	return arr;
}
```

What this basically does is loop over executing the regex pattern on the
template and adding the stuff to a data structure. Here is what that data
structure would look like:

```javascript
["Hi my name is ", "{{ name }}", "!"]
```

Now that we have parsing done, lets move on to compilation.

## Compilation

Let's take a quick overview of what compilation would output. Imagine you
enter this template:

```
Hi my name is {{ name }}!
```

It will give you this function:

```javascript
function (data) {
	return "Hi my name is "+data.name+"!";
}
```

Let's first create a function to parse and then create a string that can
be used. We first have to parse the template.

```javascript
const compileToString = (template) => {
	const ast = template;
}
```

We also have to create a string which will be used as the function.

```javascript
const compileToString = (template) => {
	const ast = template;
	let fnStr = `""`;
}
```

The reason we are using quotation marks at start is because when it is
compiling the templates and such, they will all begin with a `+`. Now we
have to iterate over the AST.

```javascript
const compileToString = (template) => {
	const ast = template;
	let fnStr = `""`;

	ast.map(t => {
		// checking to see if it is an interpolation
		if (t.startsWith("{{") && t.endsWith("}}")) {
			// append it to fnStr
			fnStr += `+data.${t.split(/{{|}}/).filter(Boolean)[0].trim()}`;
		} else {
			// append the string to the fnStr
			fnStr += `+"${t}"`;
		}
	});
}
```

The final part of this function is to return the function string.

```javascript
const compileToString = (template) => {
	const ast = template;
	let fnStr = `""`;

	ast.map(t => {
		// checking to see if it is an interpolation
		if (t.startsWith("{{") && t.endsWith("}}")) {
			// append it to fnStr
			fnStr += `+data.${t.split(/{{|}}/).filter(Boolean)[0].trim()}`;
		} else {
			// append the string to the fnStr
			fnStr += `+"${t}"`;
		}
	});

	return fnStr;
}
```

So if it takes this template:

```bash
Hi my name is  {{ name }}!
```

It will return this:

```bash
""+"Hello my name is "+data.name+"!"
```

Now this is done, creating a compile function is relatively simple.

```javascript
const compile = (template) => {
	return new Function("data", "return " + compileToString(template))
}
```

Now we have completed compilation for our template engine.

## Wrapping Up

In this tutorial I showed how to:

1. Implement a simple rendering function
2. Understand a parsing engine adapted from EJS
3. Iterate over the AST to create fast compiled template functions
