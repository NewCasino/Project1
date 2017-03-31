typeof window.localStorage == 'undefined' && ~function () {

    var localStorage = window.localStorage = {},
                prefix = 'data-userdata',
                doc = document,
                attrSrc = doc.head || doc.getElementsByTagName('head')[0],
                html = doc.documentElement,

    // save attributeNames to <html>'s
    // data-userdata attribute
                mark = function (key, isRemove, temp, reg) {
                    html.load(prefix);
                    temp = html.getAttribute(prefix) || '';
                    reg = RegExp('\\b' + key + '\\b,?', 'i');
                    hasKey = reg.test(temp) ? 1 : 0;

                    if (isRemove) {
                        temp = temp.replace(reg, '').replace(',', '');
                    }
                    else if (!hasKey) {
                        temp = temp === '' ? key : temp.split(',').concat(key).join(',');
                        //                        if (temp === '')
                        //                            temp = key;
                        //                        else
                        //                            temp = temp.split(',').concat(key).join(',');
                    }

                    html.setAttribute(prefix, temp);

                    html.save(prefix);
                };

    // add IE behavior support
    attrSrc.addBehavior('#default#userData');
    html.addBehavior('#default#userData');

    localStorage.getItem = function (key) {
        attrSrc.load(key);
        return attrSrc.getAttribute(key);
    };

    localStorage.setItem = function (key, value) {
        attrSrc.setAttribute(key, value);
        attrSrc.save(key);
        mark(key);
    };

    localStorage.removeItem = function (key) {
        attrSrc.removeAttribute(key);
        attrSrc.save(key);
        mark(key, 1);
    };


    localStorage.clear = function () {

        html.load(prefix);

        var attrs = html.getAttribute(prefix).split(','),
                    len = attrs.length;

        for (var i = 0; i < len; i++) {
            attrSrc.removeAttribute(attrs[i]);
            attrSrc.save(attrs[i]);
        };

        html.setAttribute(prefix, '');
        html.save(prefix);

    };

} ();