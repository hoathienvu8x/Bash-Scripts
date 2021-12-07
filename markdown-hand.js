var d = document.createElement('div')
d.id ='acc';
document.body.appendChild(d)
var vv = document.querySelector('#mc')
for(var i = 0; i < vv.childNodes.length; i++) {
	d.appendChild(vv.childNodes[i].cloneNode(true))
}
d.querySelectorAll('figcaption').forEach(function(el) {
	var t = el.textContent.trim();
	el.textContent = '\n> '+t
})
d.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(function(el) {
	var t = el.textContent.trim();
    var num = Number(el.nodeName.substr(1))
    var pp = '#'.repeat(num);
	el.textContent = '\n'+pp + ' '+t+'\n'
})
d.querySelectorAll('ul > li').forEach(function(el) {
    var t = el.innerHTML;
    el.innerHTML = '- ' + t
});
d.querySelectorAll('ol').forEach(function(el) {
    el.querySelectorAll('li').forEach(function(vl,i) {
        var t = vl.innerHTML;
        vl.innerHTML = (i+1).toString()+'. ' + t
    });
});
d.querySelectorAll('img').forEach(function(el) {
	var alt = (el.getAttribute('alt') || '').trim();
    var src = el.src;
    var title = (el.getAttribute('title') || '').trim()
    if (title.length > 0) {
        title = ' "'+title+'"'
    }
    var p = document.createElement('p');
    p.textContent = '!['+alt+']('+src+title+')';
	el.parentNode.insertBefore(p, el)
})
d.querySelectorAll('em').forEach(function(el) {
	var t = el.textContent;
	el.textContent = ' *'+t+'*'
})
d.querySelectorAll('strong').forEach(function(el) {
	var t = el.textContent;
	el.textContent = ' **'+t+'**'
})
d.querySelectorAll('a').forEach(function(el) {
	var t = el.textContent;
	var h = el.href;
	el.textContent = '['+t+']('+h+')'
})
d.querySelectorAll('pre').forEach(function(el) {
    var t = el.innerText;
    var a = (el.className || '').trim();
    var m = /language-(.*)? /.exec(' '+a+' ');
    var l = '';
    if (m && m[1]) {
        l = m[1].trim()
    }
    el.textContent = '```'+l+'\n'+t+'\n```'
});
d.querySelectorAll('code').forEach(function(el) {
	var t = el.textContent;
	el.textContent = ' `'+t+'` '
})
d.querySelectorAll('blockquote').forEach(function(el) {
	var t = el.textContent.trim().split('\n').map(function(v) {
        return '> '+v.trim();
    }).join('\n');
	el.textContent = t
})
