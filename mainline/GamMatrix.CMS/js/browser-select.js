var browser_selector = function(u) {
        var ua = u.toLowerCase(), 
            is = function (t) {
                return ua.indexOf(t) > -1
            },
            //      [ 0         1           2       3         4          5          6          7          8           9         10           11         12        13       14  ]
            list = ['gecko', 'webkit', 'safari', 'opera', 'mobile' , "chrome", "firefox", "android", "blackberry", "kindle", "konqueror" ,"symbos", "maxthon", "hpwOS" , "msie"],
            h = document.documentElement,
            b = [(!(/opera|webtv/i.test(ua)) && /msie\s(\d+)/.test(ua)) ? ('ie ie' + RegExp.$1) :
            is("firefox") ? list[6] + (/firefox\/(\d+)/.test(ua) ? " " + list[6] + RegExp.$1 : /firefox(\s|\/)(\d+)/.test(ua) ? " " + list[6] + RegExp.$2 : "") : 
            is("maxthon") ? list[12] + (/maxthon\/(\d+)/.test(ua) ? " " + list[12] + RegExp.$1 : /maxthon(\s|\/)(\d+)/.test(ua) ? " " + list[12] + RegExp.$2 : "") :
            is('gecko/') ? list[0] : 
            is('opera mobi') ? list[3] + (/opera\/(\d+)/.test(ua) ? " " + list[3] + RegExp.$1 : /opera(\s|\/)(\d+)/.test(ua) ? " " + list[3] + RegExp.$2 : "") + " android mobile":
            is('opera') ? list[3] + (/version\/(\d+)/.test(ua) ? ' ' + list[3] + RegExp.$1 : (/opera(\s|\/)(\d+)/.test(ua) ? ' ' + list[3] + RegExp.$2 : '')) : 
            is('konqueror') ? list[10] + (/konqueror\/(\d+)/.test(ua) ? " " + list[10] + RegExp.$1 : /konqueror(\s|\/)(\d+)/.test(ua) ? " " + list[10] + RegExp.$2 : "") : 
            is('blackberry') ? list[8] + " "+ list[8] + (/blackberry(\d+)/.test(ua) ? " " + list[8] + RegExp.$1 : /blackberry(\s|\/)(\d+)/.test(ua) ? " " : i + " " +list[4]) : 
            is("kindle") ? list[9] + (/kindle\/(\d+)/.test(ua) ? " " + list[9] + RegExp.$1 : /kindle(\s|\/)(\d+)/.test(ua) ? " " + list[9] + RegExp.$2 : "") +" "+ list[4] :
            is('android') ? list[7] + (/android\/(\d+)/.test(ua) ? " " + list[7] + RegExp.$1 : /android(\s|\/)(\d+)/.test(ua) ? " " + list[7] + RegExp.$2 : "") +" "+ list[4] : 
            is('chrome') ? list[5] + (/chrome\/(\d+)/.test(ua) ? " " + list[5] + RegExp.$1 : /chrome(\s|\/)(\d+)/.test(ua) ? " " + list[5] + RegExp.$2 : "") : is('iron') ? list[1] + ' iron' : 
            is('applewebkit/') ? list[2] + (/version\/(\d+)/.test(ua) ? ' ' + list[2] + RegExp.$1 : '') +" "+ list[1] : 
            is('mozilla/') ? list[0] : '', 
            is("sonyericsson") ? list[4] + " j2me SE" :
            is('j2me') ? 'j2me ' + list[4] : 
            is('iphone') ? 'iphone ' + list[4] : 
            is('ipod') ? 'ipod' + list[4]  : 
            is('ipad') ? 'ipad ' + list[4]  : 
            is('iemobile') ? list[4] + ' iemobile' :
            is('hp-tablet') ? list[13] +(/hpwOS\/(\d+)/.test(ua) ? " " + list[13] + RegExp.$1 : /hpwOS(\s|\/)(\d+)/.test(ua) ? " " + list[13] + RegExp.$2 : "") +' tablet':
            is('mac') ? 'mac' : 
            is('darwin') ? 'mac' : 
            is('webtv') ? 'webtv' : 
            is("win") ? "win" + (is("windows nt 6.0") ? "_vista" : is("windows nt 6.1") ? "_7" : is("windows nt 6.2") ? "_8" : is("windows nt 5.1") ? "_XP" : "") :
            is('freebsd') ? 'freebsd' : 
            is("symb") ? list[11] + (/symbianos\/(\d+)/.test(ua) ? " " + list[11] + RegExp.$1 : /symbianos(\s|\/)(\d+)/.test(ua) ? " " + list[11] + RegExp.$2 : "") :
            (is('x11') || is('linux')) ? 'linux' : ''];
        var UIFull = b.join(' ');
        h.className = h.className + " " + UIFull;
        return UIFull;
 }
browser_selector(navigator.userAgent); 