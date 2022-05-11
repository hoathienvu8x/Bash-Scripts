---
title: how can i make a simple wep key generator in javascript?
link: https://stackoverflow.com/questions/5398737/how-can-i-make-a-simple-wep-key-generator-in-javascript
---

```Javascript
function generateHexString(length) {
  // Use crypto.getRandomValues if available
  if (
    typeof crypto !== 'undefined' 
    && typeof crypto.getRandomValues === 'function'
  ) {
    var tmp = new Uint8Array(Math.max((~~length)/2));
    crypto.getRandomValues(tmp);
    return Array.from(tmp)
      .map(n => ('0'+n.toString(16)).substr(-2))
      .join('')
      .substr(0,length);
  }

  // fallback to Math.getRandomValues
  var ret = "";
  while (ret.length < length) {
    ret += Math.random().toString(16).substring(2);
  }
  return ret.substring(0,length);
}

// 40-/64-bit WEP: 10 digit key
alert("40-bit:" + generateHexString(10));

// 104-/128-bit WEP: 26 digit key
alert("104-bit:" + generateHexString(26))

// 256-bit WEP: 58 digit key
alert("256-bit:" + generateHexString(58));
```

If you wanted to generate something based on a fixed string input, there
are methods for doing that as well... this should give you what you are
looking for in terms of just a straight random hex string of the correct length.

I'm not sure if there is a standard passphrase to WEP generator, but most
limit the input to printable characters, and the algorythms are generally
weak.. best bet is to simply use WPA2PSK if you can.
