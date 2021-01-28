javascript: (function() {
    var id = (function(h) {
        if (/v=/i.test(h) == false) return null;
        return h.split('v=').pop().split('&').shift();
    })(document.location.href);
    if (id == null) {
        alert('Invalid url');
    } else {
        var url = 'https://www.youtube.com/get_video_info?video_id=' + id;
        var xhttp = new XMLHttpRequest();
        xhttp.onreadystatechange = function() {
            if (this.readyState == 4 && this.status == 200) {
                var url = 'https://www.youtube.com/get_video_info?video_id=' + id;
                var xhttp = new XMLHttpRequest();
                xhttp.onreadystatechange = function() {
                    if (this.readyState == 4 && this.status == 200) {
                        var a = this.responseText.split('&');
                        var obj = {};
                        for (var i in a) {
                            var m = a[i].split('=');
                            if (m.length != 2) continue;
                            obj[m[0]] = decodeURIComponent(m[1]);
                        }
                        if (obj.hasOwnProperty('player_response') == true) {
                            try {
                                var o = JSON.parse(obj.player_response);
                                if (o.hasOwnProperty('streamingData') == true && o.streamingData.hasOwnProperty('adaptiveFormats') == true) {
                                    var div = null;
                                    if ((div = document.getElementById('yt_downloader')) == null) {
                                        div = document.createElement('div');
                                        div.id = 'yt_downloader';
                                        var css = {
                                            position: 'fixed',
                                            width: '250px',
                                            height: '100%',
                                            padding: '2%',
                                            top: 0,
                                            right: 0,
                                            zIndex: (new Date()).getFullYear() + 100,
                                            backgroundColor: '#eee'
                                        };
                                        for (var k in css) {
                                            div.style[k] = css[k];
                                        }
                                        document.body.appendChild(div);
                                    } else {
                                        div.innerHTML = '';
                                    }
                                    var vid = id;
                                    var html = '';
                                    for (var i in o.streamingData.adaptiveFormats) {
                                        if (o.streamingData.adaptiveFormats[i].mimeType.indexOf('audio/') == -1) {
                                            html += '<a href="' + o.streamingData.adaptiveFormats[i].url + '" target="' + vid + '" style="display:block;margin:10px 0;text-decoration:none;font-weight:bold;text-align:center;">(' + o.streamingData.adaptiveFormats[i].mimeType.split(';').shift() + ')' + o.streamingData.adaptiveFormats[i].width + 'x' + o.streamingData.adaptiveFormats[i].height + '</a>';
                                        } else {
                                            html += '<a href="' + o.streamingData.adaptiveFormats[i].url + '" target="' + vid + '" style="display:block;margin:10px 0;text-decoration:none;font-weight:bold;text-align:center;">(' + o.streamingData.adaptiveFormats[i].mimeType.split(';').shift() + ')' + o.streamingData.adaptiveFormats[i].bitrate + '</a>';
                                        }
                                    }
                                    div.innerHTML = html;
                                } else {
                                    alert('No data');
                                }
                            } catch (ex) {
                                alert(ex.message);
                            }
                        }
                    }
                };
                xhttp.open("GET", url, true);
                xhttp.send();
            }
        };
        xhttp.open("GET", url, true);
        xhttp.send();
    }
})();
