(function ($) {
    var wndWidth = 0;
    var wndHeight = 0;
    var browser = null;


    function onDialogOpen(dialog) {
        $('.simplemodal-close', dialog.container).hide();
        dialog.data.css('padding', '0px');
        dialog.container.width(wndWidth).height(wndHeight).css({ "z-index": "999999" });
        dialog.overlay.css("z-index", "999998");
        dialog.overlay.fadeIn('slow', function () {
            dialog.data.fadeIn();
            $('.simplemodal-close').fadeIn();
            dialog.container.fadeIn();
            dialog.container.fadeIn('fast', function () {
                if (browser.opera) {
                    var overlay = parent.document.getElementById('simplemodal-overlay');
                    var container = parent.document.getElementById('simplemodal-container');

                    overlay.style.cssText = overlay.style.cssText + ";";
                    container.style.cssText = container.style.cssText + ";";

                    setTimeout(function () {
                        container.childNodes[0].style.cssText = container.childNodes[0].style.cssText + ';';
                    }, 1000);
                }
            });
        });
    };

    function onDialogClose(dialog) {
        $('.simplemodal-close').fadeOut();
        dialog.data.trigger("onClosing");
        dialog.container.fadeOut();

        dialog.data.fadeOut(0, function () {
            dialog.container.fadeOut(0, function () {
                $.modal.close();
            });
        });
    };

    closeModal = function () {
        try { $.modal.close(); } catch (e) { }
    };

    $.fn.modalex = function (w, h, closable, appendTo) {
        wndWidth = w;
        wndHeight = h;
        try {
            //	alert("b");
            return $.modal(this, { appendTo: (typeof (appendTo) == 'undefined' ? 'body' : appendTo)
            , minHeight: h
            , minWidth: w
            , width: w
            , height: h
            , persist: true
            , close: (closable == true)
            , escClose: (closable == true)
            , onOpen: onDialogOpen
            , onClose: onDialogClose
            , containerCss: { height: h
                            , width: w
                            , padding: '0px'
                            , backgroundColor: '#000000'
                            , border: 'solid 1px #999999'
            }

            , opacity: 80
            , overlayCss: { backgroundColor: "#000000" }
            });
        }
        catch (e) {
            alert("error");
            return $.modal(this, { appendTo: 'body'
            , minHeight: h
            , minWidth: w
            , width: w
            , height: h
            , persist: true
            , close: (closable == true)
            , escClose: (closable == true)
            , onOpen: onDialogOpen
            , onClose: onDialogClose
            , containerCss: { height: h
                            , width: w
                            , padding: '0px'
                            , backgroundColor: '#000000'
                            , border: 'solid 1px #999999'
            }

            , opacity: 80
            , overlayCss: { backgroundColor: "#000000" }
            });
        }

    };

    $.modal.impl.getDimensions = function () {
        var el = $(window);

        if (this.o.appendTo == 'body' || this.o.appendTo == document.body) {
            var h = document.documentElement.clientHeight;
            return [h, $(document.body).width()];
        }
        else {
            var h = el[0].parent.document.documentElement.clientHeight;
            return [h, $(el[0].parent.document.body).width()];
        }
    };

    var g_pfnCreate = $.modal.impl.create;
    $.modal.impl.create = function (data) {
        try {
            g_pfnCreate.call(this, data);
        }
        catch (e) {

        }

        s = this;

        if (self != top) {
            if (browser.chrome || browser.safari) {
                var newNode = parent.document.importNode(s.d.data[0], true);
                newNode.style.display = '';
                s.d.wrap[0].appendChild(newNode);
            }
        }
    };

    getBrowser = function () {
        var browserName = navigator.userAgent.toLowerCase();
        var myBrowser = {
            version: (browserName.match(/.+(?:rv|it|ra|ie)[\/: ]([\d.]+)/) || [0, '0'])[1],
            safari: /webkit/i.test(browserName) && !this.chrome,
            opera: /opera/i.test(browserName),
            firefox: /firefox/i.test(browserName),
            ie: /msie/i.test(browserName) && !/opera/.test(browserName),
            mozilla: /mozilla/i.test(browserName) && !/(compatible|webkit)/.test(browserName) && !this.chrome,
            chrome: /chrome/i.test(browserName) && /webkit/i.test(browserName) && /mozilla/i.test(browserName)
        };

        return myBrowser;
    };


    function includeCss(doc) {
        if ($("link[href*='jquery.simplemodal.css']").length > 0) {
            return;
        }
        var el = doc.createElement("link");
        el.setAttribute('rel', 'stylesheet');
        el.setAttribute('type', 'text/css');
        el.setAttribute('media', 'screen');
        el.setAttribute('href', self.location.protocol + '//' + self.location.hostname + ':' + self.location.port + '/js/jquery/css/jquery.simplemodal.css');
        doc.getElementsByTagName('head')[0].appendChild(el);
    }
    $(document).ready(function () {
        browser = getBrowser();
        try { includeCss(self.document); } catch (e) { }
        try { if (parent != self) includeCss(parent.document); } catch (e) { }
        try { if (top != self) includeCss(top.document); } catch (e) { }
    }
    );
})(jQuery);



