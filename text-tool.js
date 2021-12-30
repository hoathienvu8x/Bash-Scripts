String.prototype.hashCode = function() {
    var hash = 0, i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
        chr = this.charCodeAt(i);
        hash = ((hash << 5) - hash) + chr;
        hash |= 0;
    }
    return hash;
};
var str = []
var s = document.querySelector('h1').textContent.trim();
if (s.length > 0) {
    str.push(s);
}
s = document.querySelector('h2').textContent.trim();
if (s.length > 0) {
    str.push(s);
}
var article = document.querySelector('article');
var dom = article.cloneNode(true);
dom.querySelectorAll('ins,style,script').forEach(function(el) {
    el.remove();
});
for(var i = 0; i < dom.childNodes.length; i++) {
    s = dom.childNodes[i].textContent.trim();
    if (s.length > 0) {
        str.push(s);
    }
}
var doc = str.join(' ').replace(/([\.,;:\/\(\)\[\]"'])/g,' $1 ').replace(/\s+/g,' ').replace(/ \. \. \. /g,' [...] ').trim()
var tokens = doc.split(/\s+/).map(function(v) { return v.trim(); }).filter(function(v) { return v.length > 0; })
var sentences = doc.replace(/("[^"]*")/g,function(a, b) {
    return b.replace(/([\.\?!])/g,'[$1]');
}).replace(/([\?!])/g,'$1.').split(/\.\s+/).map(function(v) {
    v = v.trim();
    if (v[v.length - 1] == '!' || v[v.length - 1] == '?') return v.replace(/\[\.{3}\]/g,'...').replace(/\[([\.\?!])\]/g,'$1');
    return (v + '.').replace(/\[\.{3}\]/g,'...').replace(/\[([\.\?!])\]/g,'$1');
}).filter(function(v) { return v.length > 1; });
var wordnet = {};
for(var i = 0; i < tokens.length; i++) {
    if ("@`#$%&~|[]<>'(){}*+-=;,?.!:\"/".indexOf(tokens[i]) != -1) continue;
    if (/^[0-9]+$/.test(tokens[i]) == true) continue;
    var token = tokens[i].toLowerCase();
    var hash = token.hashCode();
    wordnet[hash] = [token];
}
for(var i = 0; i < tokens.length; i++) {
    if ("@`#$%&~|[]<>'(){}*+-=;,?.!:\"/".indexOf(tokens[i]) != -1) continue;
    if (/^[0-9]+$/.test(tokens[i]) == true) continue;
    var token = tokens[i].toLowerCase();
    var j = i + 1;
    if (j < tokens.length) {
        var hash = token.hashCode();
        var word = tokens[j].toLowerCase();
        if ("@`#$%&~|[]<>'(){}*+-=;,?.!:\"/".indexOf(word) != -1) continue;
        if (/^[0-9]+$/.test(word) == true) continue;
        if (wordnet[hash].includes(word) == false) {
            wordnet[hash].push(word);
        }
    }
}
