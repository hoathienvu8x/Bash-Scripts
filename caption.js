var all_cap = [];
var all_ti = [];
var all_ei = [];
ytplayer = document.getElementById("movie_player");
var lid = 0;
var mxid = setInterval(function() {
    var sp = document.querySelector('.captions-text');
    if (sp) {
        var cp = sp.innerText.trim();
        if (all_cap.indexOf(cp) == -1) {
            if(cp.indexOf('(') == -1) {
                all_cap.push(cp);
                var ci = ytplayer.getCurrentTime();
                all_ti.push(ci);
                lid = all_cap.length;
                console.log(cp,ci);
            }
        }
    } else {
        var ci = ytplayer.getCurrentTime();
        if (all_ei.length < lid) all_ei.push(ci);
    }
}, 500);

function xy(n) {
    return n < 10 ? '0'+n.toString() : n.toString();
}
function xt(v) {
    var c = v.toString().split('.');
    var t = c[0];
    if (c.length > 1) {
        var n = c[1].substr(0,3);
    } else {
        n = '000';
    }
    var t = Number(t);
    if (t > 59) {
        var s = t % 60;
        var m = Math.round(t / 60);
        t = '00:'+xy(m)+':'+xy(s);
    } else {
        t = '00:00:'+xy(t);
    }
    return t+','+n;
}

var c = []
for(var i = 0; i < all_cap.length; i++) {
    if (all_cap[i].indexOf('(') != -1) continue;
    c.push({
        s : xt(all_ti[i]),
        e : xt(all_ei[i]),
        c : all_cap[i]
    });
}
var m = [];
for(var i = 0; i < c.length; i++) {
    var j = i+1;
    m.push(j.toString()+'\n'+c[i].t+' --> '+c[i].e+'\n'+c[i].c);
}
m.join('\n\n');
