# [Convert SVG to PNG in Node.js using Sharp, no headless browser in sight](https://techsparx.com/nodejs/graphics/svg-to-png.html)

**SVG is an excellent portable, XML-based, graphics format that lets us show high fidelity graphics in modern browsers without requiring large image files. It works by using graphics operations written in XML tags. But, sometimes we need to convert an SVG to an image format (PNG, JPG, etc) in Node.js for use in non-browser contexts. Unlike most solutions to this problem, the Sharp library lets you do this without using a headless browser, decreasing the overhead of SVG image conversion.**

![](https://techsparx.com/nodejs/img/nodejs-dark.png)

Nowadays, SVG is nearly universal because it is widely supported in modern web browsers, and today we can fairly freely use them. But, since SVG is only "nearly universal", SVG's cannot be used in every circumstance. While it's supported by modern browsers, but not by older browsers, and there exist non-browser contexts that do not yet support SVG. What is the best way to convert SVG's to an image format, that does not require the overhead of a headless web browser?

Many JavaScript SVG manipulation libraries run in the browser. But what if you must do the SVG conversion on the server, rather than in a browser? Several Node.js for this purpose packages use a headless Chromium instance. While that lets us do SVG operations in Node.js, it's going to require a lot of overhead.

In these modern days shouldn't there be a light-weight choice?

The *Sharp* package is a general purpose image manipulation library for Node.js. With it we can read pretty much any image format, perform several kinds of manipulations, then render the image to pretty much any image format. As a side effect, Sharm makes it easy to do image format conversion, simply by specifying your preferred output format. Of interest here is that Sharp supports SVG on the input side, making it possible to convert an SVG file to other image formats.

In my case, I have written tools for rendering EPUB documents from Markdown files. I'm in the middle of writing a new book, and hope to use some icons (that happen to be SVG) to spice up the book. But, while EPUB v3 has support for SVG's, EPUB v2 does not, and some EPUB reader applications do not support using SVG. I suspect that Kindles probably do not support SVG, for that matter. Therefore, the book needs to use PNG icons instead.

The Sharp module, along with XML DOM manipulation, is the best solution to lightweight image format conversion including converting SVG to PNG.

That's what we'll explore in this article - using Sharp, along with an XML DOM library (for SVG manipulation), to convert SVG icons to PNG.

To do this we'll create a few Node.js scripts containing example code. To have some SVG files to play with, we'll use the Bootstrap Icons library. (

![(icons.getbootstrap.com)](https://www.google.com/s2/favicons?domain=icons.getbootstrap.com)

[https://icons.getbootstrap.com/](https://icons.getbootstrap.com/))

This is an SVG icon library from the makers of Bootstrap. They are general purpose SVG files that are not limited for use only in Bootstrap. Instead, what you get are is simply a directory full of SVG files that are easy to use in any contexts supporting SVG.

For example, here is the SVG icon for the Bootstrap logo:

```xml
<svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-bootstrap" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path fill-rule="evenodd" d="M12 1H4a3 3 0 0 0-3 3v8a3 3 0 0 0 3 3h8a3 3 0 0 0 3-3V4a3 3 0 0 0-3-3zM4 0a4 4 0 0 0-4 4v8a4 4 0 0 0 4 4h8a4 4 0 0 0 4-4V4a4 4 0 0 0-4-4H4z"/>
  <path fill-rule="evenodd" d="M8.537 12H5.062V3.545h3.399c1.587 0 2.543.809 2.543 2.11 0 .884-.65 1.675-1.483 1.816v.1c1.143.117 1.904.931 1.904 2.033 0 1.488-1.084 2.396-2.888 2.396zM6.375 4.658v2.467h1.558c1.16 0 1.764-.428 1.764-1.23 0-.78-.569-1.237-1.541-1.237H6.375zm1.898 6.229H6.375V8.162h1.822c1.236 0 1.887.463 1.887 1.348 0 .896-.627 1.377-1.811 1.377z"/>
</svg>
```

Rendered, it looks like this:

```xml
<svg width="10em" height="10em" viewBox="0 0 16 16" class="bi bi-bootstrap" fill="black" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" d="M12 1H4a3 3 0 0 0-3 3v8a3 3 0 0 0 3 3h8a3 3 0 0 0 3-3V4a3 3 0 0 0-3-3zM4 0a4 4 0 0 0-4 4v8a4 4 0 0 0 4 4h8a4 4 0 0 0 4-4V4a4 4 0 0 0-4-4H4z"></path>
<path fill-rule="evenodd" d="M8.537 12H5.062V3.545h3.399c1.587 0 2.543.809 2.543 2.11 0 .884-.65 1.675-1.483 1.816v.1c1.143.117 1.904.931 1.904 2.033 0 1.488-1.084 2.396-2.888 2.396zM6.375 4.658v2.467h1.558c1.16 0 1.764-.428 1.764-1.23 0-.78-.569-1.237-1.541-1.237H6.375zm1.898 6.229H6.375V8.162h1.822c1.236 0 1.887.463 1.887 1.348 0 .896-.627 1.377-1.811 1.377z"></path>
</svg>
```
If you saw a `B` within a box with rounded corners, then congratulations, your browser directly supports SVG. If you do not see such a thing, then please consider upgrading your web browser.

A little detail is that to make this icon have a reasonable size, I made a slight modification. You'll notice the `<svg>` element has the attributes `width="1em" height="1em"` , which means the default size is pretty small. To make it large enough to readily see the icon, I modified height and width to `10em` , and I modified `fill="currentColor"` to be `fill="black"` . By default the image is approximately the size of a normal character, or this large:

```xml
<svg width="1em" height="1em" viewBox="0 0 16 16" class="bi bi-bootstrap" fill="black" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" d="M12 1H4a3 3 0 0 0-3 3v8a3 3 0 0 0 3 3h8a3 3 0 0 0 3-3V4a3 3 0 0 0-3-3zM4 0a4 4 0 0 0-4 4v8a4 4 0 0 0 4 4h8a4 4 0 0 0 4-4V4a4 4 0 0 0-4-4H4z"></path>
<path fill-rule="evenodd" d="M8.537 12H5.062V3.545h3.399c1.587 0 2.543.809 2.543 2.11 0 .884-.65 1.675-1.483 1.816v.1c1.143.117 1.904.931 1.904 2.033 0 1.488-1.084 2.396-2.888 2.396zM6.375 4.658v2.467h1.558c1.16 0 1.764-.428 1.764-1.23 0-.78-.569-1.237-1.541-1.237H6.375zm1.898 6.229H6.375V8.162h1.822c1.236 0 1.887.463 1.887 1.348 0 .896-.627 1.377-1.811 1.377z"></path>
</svg>
```

That little detail will become important shortly.

# Project setup

The code for this tutorial is very straight-forward. We'll write a few small scripts using ES6 the top-level async/await feature which was added to Node.js in version 14.8. (See [Node.js Script writers: Top-level async/await now available](https://techsparx.com/nodejs/async/top-level-async.html))

```
$ mkdir svg-image-resize
$ cd svg-image-resize
$ npm init -y
$ npm install sharp bootstrap-icons --save
```

Start by creating a directory, setting up a blank `package.json` , and install the required packages. That's the Sharp library, and Bootstrap Icons.

At the Bootstrap Icons website you'll see the icons, and their code names. Let's familiarize ourselves with how to get the SVG file using the code name. You might like bicycles, and want to use this icon:

```xml
<svg width="10em" height="10em" viewBox="0 0 16 16" class="bi bi-bicycle" fill="black" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" d="M4 4.5a.5.5 0 0 1 .5-.5H6a.5.5 0 0 1 0 1v.5h4.14l.386-1.158A.5.5 0 0 1 11 4h1a.5.5 0 0 1 0 1h-.64l-.311.935.807 1.29a3 3 0 1 1-.848.53l-.508-.812-2.076 3.322A.5.5 0 0 1 8 10.5H5.959a3 3 0 1 1-1.815-3.274L5 5.856V5h-.5a.5.5 0 0 1-.5-.5zm1.5 2.443l-.508.814c.5.444.85 1.054.967 1.743h1.139L5.5 6.943zM8 9.057L9.598 6.5H6.402L8 9.057zM4.937 9.5a1.997 1.997 0 0 0-.487-.877l-.548.877h1.035zM3.603 8.092A2 2 0 1 0 4.937 10.5H3a.5.5 0 0 1-.424-.765l1.027-1.643zm7.947.53a2 2 0 1 0 .848-.53l1.026 1.643a.5.5 0 1 1-.848.53L11.55 8.623z"></path>
</svg>
```

The code for this icon is `bicycle` and the file name is therefore `node_modules/bootstrap-icons/icons/bicycle.svg` . Hurm, who drew that bicycle? That's not the typical geometry for bicycles, but is the *feet first* geometry that I prefer. Anyway... let's not get distracted.

# Simplistic SVG to PNG conversion using Sharp

Reading the Sharp documentation is a little frustrating due to the lack of specificity. In any case, the following is a simple recipe for converting an image from one format to another, while resizing the image.

Create a file named `cvt1.mjs` containing this:

```javascript
import sharp from 'sharp';

let srcfile = 'node_modules/bootstrap-icons/icons/bicycle.svg';
let resizewidth = 128;
let resizedest = 'bicycle.png';

let img = await sharp(srcfile);
let resized = await img.resize(resizewidth);
await resized.toFile(resizedest);
```

Running `sharp(fileName)` opens that file, constructing a Sharp object from whatever that file contains. It is able to read JPEG, PNG, WebP, GIF, SVG or TIFF image file formats. That pretty much covers all bases, yes? Most importantly for our task, it supports reading SVG files.

The `resize` method does what it suggests, resizes the image to N pixels wide.

The `toFile` method does what it suggests, which is to write the image to a file. The image format will be inferred from the pathname, and it supports writing to PNG, JPEG, WebP, etc.

We are requesting an image 128 pixels wide to give us an image of a useful size that we can readily view.

![](https://techsparx.com/nodejs/graphics/img/bicycle-bad.png)

Unfortunately the bicycle did not convert very well. Hurm.

# Scaling the SVG before resizing the converted image

Why did the image come out so badly? It's related to the `width="1em" height="1em"` attributes mentioned earlier. With those attributes the SVG specifies a smallish image approximately one character unit in height and width. That means we scaled up the image to 128x128 pixels. Upscaling images rarely produces a good result, and it's much better to scale down a large image instead.

But, we did partly accomplish our goal. We've converted SVG to PNG with a very light-weight solution. It's unfortunate that the image came out so bad.

What we need is an effective method for changing the width and height attributes so the image has a larger base size.

Create a file named `cvt2.mjs` containing this:

```javascript
import { promises as fs } from 'fs';
import sharp from 'sharp';

let srcfile = 'node_modules/bootstrap-icons/icons/bicycle.svg';
let resizewidth = 128;
let resizedest = 'bicycle.png';

let svgdata = await fs.readFile(srcfile, 'utf-8');
let img = await sharp(Buffer.from(
    svgdata.replace('1em', '100em').replace('1em', '100em')
));

let resized = await img.resize(resizewidth);
await resized.toFile(resizedest);
```

The `sharp()` function can also receive a *Buffer* containing raw image data. Since one of its input image formats is SVG, we can generate a Buffer containing modified SVG from the source file. What we've done is to read the text of the SVG file into a String, then modify some values, and convert the modified string into a Buffer. That gives `sharp()` a Buffer containing SVG code, which it can then render and convert to an image.

This isn't the best method for modifying XML, but we can start with this and prove the concept.

The key here is to use `String.replace` to change the `1em` attributes to `100em` . We have to call `replace` twice because `1em` appears twice in the source string. The best method for converting a JavaScript String to a Buffer is to use `Buffer.from` as shown here.

This means we're modifying the SVG to have `width="100em" height="100em"` . That's surely a large enough image that we can resize it down to 128 pixels with relatively good fidelity.

![](https://techsparx.com/nodejs/graphics/img/bicycle-good.png)

That's much better. We've got a better proof of concept, that we can easily convert SVG to PNG, at low overhead, and get relatively good image fidelity.

Since the SVG format is XML, we can use XML tools to manipulate the SVG code the correct way.

# Using xmldom to manipulate SVG in Node.js

We determined we can use Sharp convert SVG's to PNG, but for the Bootstrap Icons we need to modify the SVG's to get good results.

The best method to manipulate the SVG file is to convert the SVG string to an XML DOM, then to use DOM API methods to change the XML structure. There are several DOM libraries available for Node.js. What I have the most familiarity with is `xmldom` .

Start with installing `xmldom` :

```
$ npm install xmldom --save
```

The `xmldom` package is an implementation of the W3C DOM API in pure JavaScript. This means we can use normal DOM methods on Node.js, again without requiring a headless browser.

Create a file named `cvt3.mjs` containing this:

```javascript
import { promises as fs } from 'fs';
import sharp from 'sharp';
import xmldom from 'xmldom';

let srcfile = 'node_modules/bootstrap-icons/icons/bicycle.svg';
let resizewidth = 128;
let resizedest = 'bicycle.png';

let svgdata = await fs.readFile(srcfile, 'utf-8');

let BICYCLE = new xmldom.DOMParser().parseFromString(svgdata, 'text/xml');
let svgList = BICYCLE.getElementsByTagName('svg');
if (!svgList) {
    throw new Error(`No SVG in ${svgdata}`);
}

let svg = svgList.item(0);
svg.setAttribute('width', '100em');
svg.setAttribute('height', '100em');
svg.setAttribute('fill', 'black');

let img = await sharp(Buffer.from(
    new xmldom.XMLSerializer().serializeToString(BICYCLE)
));

let resized = await img.resize(resizewidth);
await resized.toFile(resizedest);
```

After reading the file into a String, we use DOMParser to create a DOM. Since we just need to manipulate the `<svg>` element, we get that.

The `getElementsByTagName` function returns a NodeList. As the name implies, NodeList can contain multiple items. That means we must use the `item` method to retrieve the first one. We know that there will be only one `<svg>` element in these files, so this is the correct thing to do.

We then use `setAttribute` to change a few attributes. Notice that this is manipulating the DOM. That means all we need to do is call `setAttribute` and it will be changed in the DOM.

To convert it back to an XML string, we use XMLSerializer. Once that's done, we're back to the flow of operations we used before.

![](https://techsparx.com/nodejs/graphics/img/bicycle-cvt3.png)

And, this is what we end up with. A fairly good rendition of the SVG as a PNG file.

# Summary

In this article we've gotten a taste of what it takes to convert SVG files to PNG images using Node.js. Rather than requiring a browser instance to handle the conversion, we used a fully featured image manipulation toolkit.

With this learning it might be useful to convert these steps into a library. Obviously if we have 1 image to convert, we might have hundreds of similar images to convert.

But there's a wrinkle which may make it difficult to create a general purpose library. Namely, the SVG manipulation we did here might not be required for other icon libraries. The icons in other libraries might require different manipulations, or no manipulations. In other words, how do we generalize any required manipulation?
