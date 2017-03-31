var DeviceChecker = {
    IsMobile: false,
    PCSiteUrl: $("body").data("desktop") || $("body").attr("data-desktop"),
    MobileSiteUrl: $("body").data("mobile") || $("body").attr("data-mobile"),
    CookieDomain: $("body").data("cookiedomain") || $("body").attr("data-cookiedomain"),
    Cookie_key_device: "device_select_user_selected",
    Cookie_key_remind: "device_select_remind",

    Redirect: function (reverseUrl) {
        window.setTimeout(window.location = reverseUrl, 500);
    },

    SaveSetting: function (isPermanent, device, rememberDevice, keepRemind) {
        if (rememberDevice)
            $.cookie(this.Cookie_key_device, device, { "path": "/", "domain": this.CookieDomain, "expires": 999 });
        if (!keepRemind)
            $.cookie(this.Cookie_key_remind, "true", { "path": "/", "domain": this.CookieDomain, "expires": (isPermanent ? 999 : 1) });
    },

    RemoveDeviceSetting: function()
    {
        $.cookie(this.Cookie_key_device, "", { "path": "/", "domain": this.CookieDomain, "expires": -999 });
    },

    Init: function () {
        var isM = $("body").data("ismobile") || $("body").attr("data-ismobile");
        if (isM == 0)
            this.IsMobile = false;
        else
            this.IsMobile = true;
        if ($.cookie(this.Cookie_key_device) != null) {
            if ($.cookie(this.Cookie_key_device) == "mobile") {
                if (!this.IsMobile)
                    this.Redirect(this.MobileSiteUrl);
            }
            else {
                if (this.IsMobile)
                    this.Redirect(this.PCSiteUrl);
            }
        }
    }
};


DeviceChecker.Switcher = {
    Init: function () {
        if (window.top != window.self) {
            $(".device-switcher").hide();
            return;
        }
        $(".device-switcher .device-switcher-mobile").click(function () {
            DeviceChecker.SaveSetting(false, "mobile", true, true);
            DeviceChecker.Redirect(this.MobileSiteUrl);
            return false;
        });

        $(".device-switcher .device-switcher-pc").click(function () {
            DeviceChecker.SaveSetting(false, "desktop", true, true);
            DeviceChecker.Redirect(this.PCSiteUrl);
            return false;
        });
    },
    Custom: function (isMobile, isRemember, redirect) {
        if (isMobile) {
            if (isRemember)
                DeviceChecker.SaveSetting(false, "mobile", true, true);
            else
                DeviceChecker.RemoveDeviceSetting();
            if (redirect)
                DeviceChecker.Redirect(DeviceChecker.MobileSiteUrl);
        }
        else {
            if(isRemember)
                DeviceChecker.SaveSetting(false, "desktop", true, true);
            else
                DeviceChecker.RemoveDeviceSetting();
            if (redirect)
                DeviceChecker.Redirect(DeviceChecker.PCSiteUrl);
        }
    }
};

DeviceChecker.Promoting = {
    options: {},
    promoting: null,

    Init: function (options) {
        this.options = options;
        this.promoting = $("#switch-promot");

        if (window.top != window.self)
            return;
        if (this.promoting == null || this.promoting.length == 0)
            return;

        this.IncludeCss();

        this.PrevCheck();

        this.BindEvent();
    },
    PrevCheck: function () {
        if ($.cookie(DeviceChecker.Cookie_key_remind) == null) {            
            if (DeviceChecker.IsMobile) {
                if (!$.browser.mobile)
                    this.promoting.show();
            }
            else {
                if ($.browser.mobile)
                    this.promoting.show();
            }
        }
    },

    BindEvent: function () {
        $("#switch-promot-btnYes").click(function () {
            DeviceChecker.Promoting.Resolved(true, true, false);
            return false;
        });

        $("#switch-promot-btnClose").click(function () {
            DeviceChecker.Promoting.Resolved(false, false, false);
            return false;
        });

        $("#switch-promot-btnDonotRemind").click(function () {
            DeviceChecker.Promoting.Resolved(false, false, true);
            return false;
        })
    },
    Resolved: function (redirect, rememberDevice, isPermanent) {
        this.promoting.hide();
        var device = "desktop";
        if (redirect) {
            if (!DeviceChecker.IsMobile)
                device = "mobile";
        }
        else {
            if (DeviceChecker.IsMobile)
                device = "mobile";
        }
        DeviceChecker.SaveSetting(isPermanent, device, rememberDevice);
        if (redirect)
            this.Redirect();
    },
    Redirect: function () {
        DeviceChecker.Redirect(DeviceChecker.IsMobile ? DeviceChecker.PCSiteUrl : DeviceChecker.MobileSiteUrl);
    },
    IncludeCss: function () {
        if ($("link[href*='/css/promoting/promoting.css']").length > 0) {
            return;
        }
        var el = self.document.createElement("link");
        el.setAttribute('rel', 'stylesheet');
        el.setAttribute('type', 'text/css');
        el.setAttribute('media', 'screen');
        el.setAttribute('href', self.location.protocol + '//' + self.location.hostname + ':' + self.location.port + '/js/css/promoting/promoting.css');
        self.document.getElementsByTagName('head')[0].appendChild(el);
    }
};


DeviceChecker.Init();