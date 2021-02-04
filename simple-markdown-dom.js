var mdc = document.createElement('div');
mdc.id = 'md-content';

mdc.style.position = 'fixed';
mdc.style.width = '100%';
mdc.style.height = '100%';
mdc.style.overflowX = 'hidden';
mdc.style.overflowY = 'auto';
mdc.style.padding = '5%';
mdc.style.backgroundColor = '#fff';
mdc.style.top = '0';
mdc.style.left = '0';
mdc.zIndex = 9999;

var t = '<h1>'+document.querySelector('h1.content-title').innerText.trim()+'</h1>';

t += document.querySelector('div.content-body').innerHTML.trim();

mdc.innerHTML = t;

document.body.appendChild(mdc);

var a = mdc.querySelectorAll('h1,h2,h3,h4,h5,h6');
for(var i = 0; i < a.length;i++) {
    var text = a[i].innerHTML.trim();
    var n = Number(a[i].nodeName.replace('H',''));
    a[i].innerHTML = '#'.repeat(n)+' '+text;
}
a = mdc.querySelectorAll('pre');
for(var i = 0; i < a.length;i++) {
    var code = a[i].innerText.trim();
    var lang = (function(c) {
        c = c.replace(/ {2,}/g,' ').split(' ').map(function(v) {
            v = v.trim();
            if (v.indexOf('lang-') == 0) {
                return v.replace('lang-','').trim();
            }
            return '';
        }).join('');
        return c;
    })((a[i].className || '').trim());
    a[i].innerHTML = '';
    a[i].appendChild(document.createTextNode('```'+lang+'\n'+code+'\n```'));
}
a = mdc.querySelectorAll('code');
for(var i = 0; i < a.length;i++) {
    var code = a[i].innerText.trim();
    a[i].innerText = '`'+code+'`';
}
a = mdc.querySelectorAll('strong,b');
for(var i = 0; i < a.length;i++) {
    var code = a[i].innerHTML;
    a[i].innerHTML = '**'+code+'**';
}
a = mdc.querySelectorAll('em,i');
for(var i = 0; i < a.length;i++) {
    var code = a[i].innerHTML;
    a[i].innerHTML = '*'+code+'*';
}
a = mdc.querySelectorAll('a');
for(var i = 0; i < a.length;i++) {
    var text = a[i].innerHTML;
    var href = a[i].getAttribute('href');
    if (href != null && text.trim().length != 0) {
        a[i].innerHTML = '['+text+']('+href+')';
    }
}
a = mdc.querySelectorAll('ul li');
for(var i = 0; i < a.length;i++) {
    var text = a[i].innerHTML.trim();
    a[i].innerHTML = '* '+text;
}
a = mdc.querySelectorAll('ol li');
for(var i = 0; i < a.length;i++) {
    var text = a[i].innerHTML.trim();
    a[i].innerHTML = (i+1).toString()+'. '+text;
}
a = mdc.querySelectorAll('p sup');
for(var i = 0; i < a.length;i++) {
    var text = a[i].innerHTML.trim();
    text = text.replace(/<br[^>]*/ig,'  ').trim();
    a[i].parentElement.innerHTML = '> '+text;
}
/* https://stackoverflow.com/a/4793630 */
a = mdc.querySelectorAll('img');
for(var i = 0; i < a.length;i++) {
    var alt = a[i].getAttribute('alt');
    var title = a[i].getAttribute('title');
    var src = a[i].getAttribute('src');
    if (src != null) {
        var p = document.createElement('p')
        p.innerText = '!['+(alt ? alt : '')+']('+src+''+(title ? '"'+title+'"' : '')+')';
        a[i].parentNode.insertBefore(p, a[i].nextSibling);
    }
}
