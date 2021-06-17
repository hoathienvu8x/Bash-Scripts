javascript: (function() {
    if (/stackoverflow\.com\/questions/.test(document.location.href) == true) {
        function hQ(s) {
            return document.querySelector(s);
        }

        function hQa(s) {
            return document.querySelectorAll(s);
        }
        Element.prototype.hQ = function(s) {
            return this.querySelector(s);
        };
        Element.prototype.hQa = function(s) {
            return this.querySelectorAll(s);
        };
        Element.prototype.swap = function(node) {
            var m_parent = this.parentNode;
            var m_sibling = this.nextSibling === node ? this : this.nextSibling;
            node.parentNode.insertBefore(this, node);
            m_parent.insertBefore(node, m_sibling);
        };
        Element.prototype.remove = function() {
            this.parentElement.removeChild(this);
        };
        NodeList.prototype.remove = HTMLCollection.prototype.remove = function() {
            for (var i = this.length - 1; i >= 0; i--) {
                if (this[i] && this[i].parentElement) {
                    this[i].parentElement.removeChild(this[i]);
                }
            }
        };
        Element.prototype.After = function(newNode) {
            this.parentElement.insertBefore(newNode, this.nextSibling);
        };
        Element.prototype.Before = function(newNode) {
            this.parentElement.insertBefore(newNode, this);
        };
        var st = document.createElement('style');
        st.innerText = '#left-sidebar,#sidebar { display:none!important; } .js-post-body,#question-header,#question-header h1 a,a.post-tag{ cursor: cell!important; } #i-md { transition:width .4s; background-color:#fff; width:400px; height:100%; position:fixed; top:0; right:0; z-index:9999; overflow: auto; padding: 0; text-align:right; box-shadow:0 1px 2px rgba(0,0,0,0.05),0 1px 4px rgba(0,0,0,0.05),0 2px 8px rgba(0,0,0,0.05); } #i-md.i-md-exp{ width:80%; } #i-md-bar { box-shadow:0 1px 2px rgba(0,0,0,0.05),0 1px 4px rgba(0,0,0,0.05),0 2px 8px rgba(0,0,0,0.05); padding:2% 4%; text-align:left; } #i-md button { outline: none; } #i-md-exp { border-color: transparent; border-radius: 3px; padding: 2px 10px; font-size: 16px; font-weight: normal; color: #999; background: transparent; } #i-mdc,#i-md-tags,#i-md-p{ padding:2%; line-height: 25px; font-size: 16px; text-align:left; } #i-mdc p, #i-mdc pre,#i-md-p p, #i-md-p pre { padding:2%; } #i-mdc pre { white-space: pre-wrap; word-break: break-word; } .i-md-header { padding: 2%; border-bottom: 1px solid #e4e6e8; } #i-md-tags .i-md-tag{ display: inline-block; padding: .4em .5em; margin: 2px 2px 2px 0; line-height: 1; white-space: nowrap; text-decoration: none; text-align: center; border:1px solid transparent; color: #39739d; background: #e1ecf4; border-radius: 3px; } #i-mdg{ background-color:#0095ff; color:#fff; font-size:13px; border:1px solid transparent; border-radius:3px; padding:5px 10px; font-weight:bold; margin-right:4%; } #i-md-p { display:none; } #i-md-p ul, #i-md-p ol { list-style: none; } #i-mdc, #i-md-tags, #i-md-p{ margin-bottom:4%; } #i-md-p.i-md-a { display:block; } .md-drag { cursor: row-resize; } .i-md-exp #i-md-bar, .i-md-exp #i-mdc, .i-md-exp #i-md-tags { padding: 2%; } .i-md-exp #i-mdg { margin-right: 2%; }';
        document.head.appendChild(st);
        var div = document.createElement('div');
        div.id = 'i-md';
        div.innerHTML = '<div id="i-md-bar"><button id="i-md-exp">&#8644;</button></div><div id="i-md-p"></div><div id="i-mdc"></div><div id="i-md-tags"></div><button id="i-mdg">&#8675; MD</button>';
        div.addEventListener('dragover', function(e) {
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";
        });
        div.addEventListener('drop', function(e) {
            e.preventDefault();
            hQ('div#i-md-p').className = "";
            const data = e.dataTransfer.getData("text/plain");
            if (data.trim().length > 0) {
                var el = document.createElement('div');
                if (data.indexOf('md-item-') == 0) {
                    return false;
                }
                if (data.charAt(0) == '{') {
                    try {
                        var obj = JSON.parse(data);
                        if (hQa('[data-of="of-' + obj.item + '"]').length > 0) {
                            return false;
                        }
                        el.setAttribute('id', 'of-' + obj.item);
                        el.innerHTML = obj.html;
                    } catch (err) {
                        throw err.message;
                    }
                } else {
                    el.innerHTML = data;
                }
                el.querySelectorAll('aside,div,hr,ins,header,footer').remove();
                var md = hQ('div#i-mdc');
                while (el.firstChild) {
                    var cls = (el.firstChild.className || '').trim() + ' md-editabled';
                    el.firstChild.className = cls.trim();
                    if (cls.indexOf('i-md-header') != -1) {
                        if (md.firstChild) {
                            var s1 = md.firstChild.innerText.trim();
                            var s2 = el.firstChild.innerText.trim();
                            if (s1 != s2) {
                                md.firstChild.Before(el.firstChild);
                            }
                        } else {
                            md.appendChild(el.firstChild);
                        }
                    } else if (cls.indexOf('i-md-tag') != -1) {
                        var t = el.firstChild.innerText.trim().replace(/"/g, '&quot;');
                        if (!hQ('div#i-md-tags span[data-tag="' + t + '"]')) {
                            hQ('div#i-md-tags').appendChild(el.firstChild);
                        }
                    } else {
                        var id = 'md-item-' + (md.children.length + 1).toString();
                        if (typeof el.firstChild.setAttribute == 'function') {
                            el.firstChild.setAttribute('draggable', true);
                            el.firstChild.setAttribute('id', id);
                            el.firstChild.setAttribute('data-of', el.id);
                        } else {
                            el.firstChild.draggable = true;
                            el.firstChild.id = id;
                            el.firstChild.dataset = el.firstChild.dataset || {};
                            el.firstChild.dataset["dataOf"] = el.id;
                        }
                        el.firstChild.className = ((el.firstChild.className || '') + ' md-drag').trim();
                        md.appendChild(el.firstChild);
                    }
                }
            }
        });
        document.body.appendChild(div);
        document.addEventListener("dragover", function(e) {
            e.preventDefault();
            if (e.target.className && e.target.className.indexOf('md-drag') != -1) {
                e.target.style.backgroundColor = '#ddd';
            }
        }, false);
        document.addEventListener("dragleave", function(e) {
            e.preventDefault();
            if (e.target.className && e.target.className.indexOf('md-drag') != -1) {
                e.target.style.backgroundColor = '';
            }
        }, false);
        document.addEventListener("drop", function(e) {
            e.preventDefault();
            if (e.target.className && e.target.className.indexOf('md-drag') != -1) {
                const data = e.dataTransfer.getData("text");
                if (data.length > 0 && data.indexOf('<') == -1) {
                    var node = hQ('#i-mdc #' + data);
                    if (node) {
                        e.target.swap(node)
                    }
                }
                e.target.style.backgroundColor = '';
            }
        }, false);
        document.addEventListener('dragstart', function(e) {
            if (e.target.className && e.target.className.indexOf('md-drag') != -1) {
                e.dataTransfer.setData("text", e.target.id.trim());
            }
        }, false);
        hQ('button#i-md-exp').addEventListener('click', function(e) {
            e.preventDefault();
            var imd = hQ('div#i-md');
            var cls = (imd.className || '').trim();
            if (cls == 'i-md-exp') {
                cls = '';
            } else {
                cls = 'i-md-exp';
            }
            imd.className = cls;
            return false;
        });
        hQ('button#i-mdg').addEventListener('click', function(e) {
            e.preventDefault();
            var mdp = hQ('div#i-md-p');
            mdp.className = 'i-md-a';
            mdp.innerHTML = hQ('div#i-mdc').innerHTML;
            var a = mdp.hQa('*');
            for (var i = 0; i < a.length; i++) {
                a[i].removeAttribute('style');
                a[i].removeAttribute('draggable');
                a[i].removeAttribute('id');
                a[i].removeAttribute('class');
                a[i].removeAttribute('data-of');
            }
            a = mdp.hQa('h1,h2,h3,h4,h5,h6');
            for (var i = 0; i < a.length; i++) {
                var text = a[i].innerHTML.trim();
                var n = Number(a[i].nodeName.replace('H', ''));
                a[i].innerHTML = '#'.repeat(n) + ' ' + text;
            }
            a = mdp.hQa('pre');
            for (var i = 0; i < a.length; i++) {
                var code = a[i].innerText.trim();
                var lang = (function(c) {
                    c = c.replace(/ {2,}/g, ' ').split(' ').map(function(v) {
                        v = v.trim();
                        if (v.indexOf('lang-') == 0) {
                            return v.replace('lang-', '').trim();
                        }
                        return '';
                    }).join('');
                    return c;
                })((a[i].className || '').trim());
                a[i].innerHTML = '';
                a[i].appendChild(document.createTextNode('```' + lang + '\n' + code + '\n```\n'));
            }
            a = mdp.hQa('code');
            for (var i = 0; i < a.length; i++) {
                var code = a[i].innerText.trim();
                a[i].innerText = '`' + code + '`';
            }
            a = mdp.hQa('strong,b');
            for (var i = 0; i < a.length; i++) {
                var code = a[i].innerHTML;
                a[i].innerHTML = '**' + code + '**';
            }
            a = mdp.hQa('em,i');
            for (var i = 0; i < a.length; i++) {
                var code = a[i].innerHTML;
                a[i].innerHTML = '*' + code + '*';
            }
            a = mdp.hQa('a');
            for (var i = 0; i < a.length; i++) {
                var text = a[i].innerHTML;
                var href = a[i].getAttribute('href');
                a[i].innerHTML = '[' + text + '](' + href + ')';
            }
            a = mdp.hQa('ul li');
            for (var i = 0; i < a.length; i++) {
                var text = a[i].innerHTML.trim();
                a[i].innerHTML = '* ' + text;
            }
            a = mdp.hQa('ol li');
            for (var i = 0; i < a.length; i++) {
                var text = a[i].innerHTML.trim();
                a[i].innerHTML = (i + 1).toString() + '. ' + text;
            }
            a = mdp.hQa('p sup');
            for (var i = 0; i < a.length; i++) {
                var text = a[i].innerHTML.trim();
                text = text.replace(/<br[^>]*/ig, '  ').trim();
                a[i].parentElement.innerHTML = '> ' + text;
            }
            return false;
        });
        var a = hQa('#question-header,.js-post-body,.comment-copy');
        for (var i = 0; i < a.length; i++) {
            a[i].setAttribute('draggable', true);
            if (a[i].id.trim() == "") {
                a[i].setAttribute('id', 'from-item-' + i.toString());
            }
            a[i].addEventListener('dragstart', function(e) {
                if (e.target.id == 'question-header') {
                    var text = e.target.querySelector('h1 a').innerText.trim();
                    e.dataTransfer.setData("text/plain", '<h1 class="i-md-header">' + text + '</h1>');
                } else {
                    if (e.target.parentElement.parentElement && e.target.parentElement.parentElement.id == 'question-header') {
                        var text = e.target.innerText.trim();
                        e.dataTransfer.setData("text/plain", '<h1 class="i-md-header">' + text + '</h1>');
                    } else if (e.target.parentElement && e.target.parentElement.id == 'question-header') {
                        var text = e.target.querySelector('a').innerText.trim();
                        e.dataTransfer.setData("text/plain", '<h1 class="i-md-header">' + text + '</h1>');
                    } else {
                        if ((e.target.className || "").trim().indexOf('comment-copy') != -1) {
                            var obj = {
                                item: e.target.id,
                                html: '<p>' + e.target.innerHTML.trim() + '</p>'
                            };
                            e.dataTransfer.setData("text/plain", JSON.stringify(obj));
                        } else {
                            var obj = {
                                item: e.target.id,
                                html: e.target.innerHTML.trim()
                            };
                            e.dataTransfer.setData("text/plain", JSON.stringify(obj));
                        }
                    }
                }
            });
        }
        a = hQa('a.post-tag');
        for (var i = 0; i < a.length; i++) {
            a[i].setAttribute('draggable', true);
            a[i].addEventListener('click', function(e) {
                e.preventDefault();
                return false;
            });
            a[i].addEventListener('dragstart', function(e) {
                var text = e.target.innerText.trim();
                e.dataTransfer.setData("text/plain", '<span class="i-md-tag" data-tag="' + text.replace(/"/g, '&quot;') + '">' + text + '</span>');
            });
        }
    }
})();
