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
var sentences = doc.replace(/([\?!])/g,'$1.').split(/\.\s+/).map(function(v) {
    v = v.trim();
    if (v[v.length - 1] == '!' || v[v.length - 1] == '?') return v.replace(/\[\.{3}\]/g,'...');
    return (v + '.').replace(/\[\.{3}\]/g,'...');
}).filter(function(v) { return v.length > 1; })
