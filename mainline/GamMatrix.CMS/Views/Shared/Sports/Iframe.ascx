<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="OddsMatrix" %>
<script language="C#" type="text/C#" runat="server">
    protected override void OnInit(EventArgs e)
    {
        if (Settings.IsUKLicense && !Settings.IsOMAllowedonUKLicense)
        {
            string url;
            if (Request.IsHttps() && SiteManager.Current.HttpsPort > 0)
            {
                url = string.Format("https://{0}{1}"
                        , Request.Url.Host
                        , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                        );
            }
            else
            {
                url = string.Format("http://{0}{1}"
                        , Request.Url.Host
                        , (SiteManager.Current.HttpPort != 80) ? (":" + SiteManager.Current.HttpPort.ToString()) : string.Empty
                        );
            }
            Response.ClearHeaders();
            Response.Clear();
            Response.AddHeader("Location", url);
            Response.StatusCode = 302;
            Response.Flush();
            Response.End();
            return;
        }
        
        if (Profile.IsAuthenticated)
        {
            if (!Request.IsHttps() &&
                        string.Equals(Request.HttpMethod, "GET", StringComparison.InvariantCultureIgnoreCase) &&
                        SiteManager.Current.HttpsPort > 0)
            {
                string url = string.Format("https://{0}{1}{2}"
                    , Request.Url.Host
                    , (SiteManager.Current.HttpsPort != 443) ? (":" + SiteManager.Current.HttpsPort.ToString()) : string.Empty
                    , Request.RawUrl
                    );
                Response.Redirect(url);
                return;
            }
        }
        
        base.OnInit(e);
    }
    
    public string ConfigrationItemPath
    {
        get
        {
            return string.Format( "/Metadata/Settings.{0}"
                , (this.ViewData["ConfigrationItem"] as string).DefaultIfNullOrEmpty("OddsMatrix_HomePage")
                );
        }
    }

    private string GetDomain()
    {
        string host = HttpContext.Current.Request.Url.Host;
        if (host.EndsWith(".gammatrix-dev.net", StringComparison.InvariantCultureIgnoreCase))
        {
            //If the accessing domain name is under gammatrix-dev.net (i.e, www.jetbull.gammatrix-dev.net), 
            //the domain is set to jetbull.gammatrix-dev.net
            var fields = host.Split('.');
            string domain = string.Empty;
            for (var i = fields.Length - 3; i < fields.Length; i++)
                domain += fields[i] + ".";
            return domain.TrimStart('.').TrimEnd('.');
        }
        else
        {
            //Otherwise, the root domain name is set as the domain. 
            //For example, www.casino.jetbull.com and www.jetbull.com and jetbull.com all get the same cookie domain jetbull.com;
            //www.casino.jetbull.com.mx and www.jetbull.com.mx and jetbull.com.mx all get the same cookie domain jetbull.com.mx
            //Note: the same logic will be applied to domain XXX.net, XXX.org, XXX.co and XXX.net.XX, XXX.org.XX, XXX.co.XX
            var tlds = new[]
                {
                    ".com",
                    ".net",
                    ".org",
                    ".co",
                };//top-level domains

            foreach (var tld in tlds)
            {
                if (host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase) > 0)
                {
                    var temp = host.Substring(0, host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                    if (temp.LastIndexOf(".") >= 0)
                        temp = temp.Substring(temp.LastIndexOf(".") + 1);
                    var domain2 = temp + host.Substring(host.IndexOf(tld + ".", StringComparison.InvariantCultureIgnoreCase));
                    return domain2.TrimStart('.').TrimEnd('.');
                }
            }
            
            var fields = host.Split('.');
            if (fields.Length < 2)
                return host;
            string domain = string.Empty;
            for (var i = fields.Length - 2; i < fields.Length; i++)
                domain += fields[i] + ".";
            return domain.TrimStart('.').TrimEnd('.');
        }
    }
    
    private string GetIframeUrl()
    {
        if (!string.IsNullOrEmpty(this.ViewData["Url"] as string))
            return this.ViewData["Url"] as string;
        
        string path = this.GetMetadata(ConfigrationItemPath);
        string pageName = Request.QueryString["pageName"];
        if (!string.IsNullOrEmpty(pageName))
            path = path.Replace("fe_home", pageName);

        if (path.Contains("$DOMAIN$"))
            path = path.Replace("$DOMAIN$", GetDomain());
        
        StringBuilder sb = new StringBuilder();
        sb.Append( string.Format( "{0}://{1}"
            , Request.GetUrlScheme()
            , path
            )
        );

        if (sb.ToString().IndexOf('?') > 0)
            sb.Append(HttpUtility.HtmlEncode("&"));
        else
            sb.Append('?');

        sb.AppendFormat(CultureInfo.InvariantCulture, "lang={0}"
            , HttpUtility.UrlEncode( OddsMatrixProxy.MapLanguageCode(HttpContext.Current.GetLanguage()) )
        );

        sb.AppendFormat(CultureInfo.InvariantCulture, "{0}currentSession={1}"
            , HttpUtility.HtmlEncode("&")
            , HttpUtility.UrlEncode( Profile.SessionID )
            );
        foreach (string key in Request.QueryString.AllKeys)
        {
            if (string.Equals(key, "_sid", StringComparison.InvariantCultureIgnoreCase) ||
                string.Equals(key, "pageName", StringComparison.InvariantCultureIgnoreCase))
                continue;

            sb.AppendFormat(CultureInfo.InvariantCulture, "{0}{1}={2}", HttpUtility.HtmlEncode("&"), HttpUtility.UrlEncode(key), HttpUtility.UrlEncode(Request.QueryString[key]));
        }

        return sb.ToString();
    }

    private void SetWidth()
    { 
        string _width = null;
        if (this.ViewData["PercentageWidth"] != null)
        {
            _width = this.ViewData["PercentageWidth"] as string;
            if (!string.IsNullOrWhiteSpace(_width))
                _width = string.Format(CultureInfo.InvariantCulture, "{0}%", _width);
        }
        else if (this.ViewData["Width"] != null)
        {
            _width = this.ViewData["Width"] as string;
            if (!string.IsNullOrWhiteSpace(_width))
                _width = string.Format(CultureInfo.InvariantCulture, "{0}px", _width);
        }

        if (!string.IsNullOrWhiteSpace(_width))
        {
            ifmSportsbook.Style["width"] = _width;
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        if (Profile.IsAuthenticated && Profile.IsInRole("Withdraw only"))
        {
            ifmSportsbook.Visible = false;
            scriptSportsbook.Visible = false;
            panError.Visible = true;
            return;
        }
        SetWidth();
        ifmSportsbook.Attributes["src"] = GetIframeUrl();
        base.OnPreRender(e);
    }
</script>

<ui:MinifiedJavascriptControl ID="scriptSportsbook" runat="server" AppendToPageEnd="true">
<script type="text/javascript">
    if (window.location.toString().indexOf('.gammatrix-dev.net') > 0 || window.location.toString().indexOf('.everymatrix.com') > 0)
        document.domain = document.domain;
    else
        document.domain = '<%= SiteManager.Current.SessionCookieDomain.SafeJavascriptStringEncode() %>';

function IframeAutoFit(el) {
    this.iframe = $(el);
    this.getDocument = function () {
        var f = this.iframe[0];
        return f && typeof (f) == 'object' && f.contentDocument || f.contentWindow && f.contentWindow.document || f.document;
    };

    this.autoHeight = function () {
        try {
            var height = this.getDocument().body.scrollHeight;
            try { height = $(this.getDocument().body).height(); } catch (e) { }
            //var h1 = this.getDocument().documentElement.scrollHeight;
            //var h2 = this.getDocument().body.scrollHeight;
            //var height = Math.max(h1, h2);
            if (height > 0)
                this.iframe.css('height', height.toString(10) + 'px');
        }
        catch (e) {
            //if (typeof (console) != 'undefined' && console.log != null)
            //    console.log('%s', e);
        }
    };

    setInterval(
        (function (o) {
            return function () {
                o.autoHeight()
            };
        })(this)
        , 500
        );
}
$(function () { new IframeAutoFit('#ifmSportsbook') });
</script>
</ui:MinifiedJavascriptControl>



<iframe runat="server" ClientIDMode="Static" id="ifmSportsbook" scrolling="no" style="overflow:hidden;height:500px" allowTransparency="true" frameborder="0">
</iframe>

<ui:Panel runat="server" ID="panError" Visible="false">
<%: Html.ErrorMessage(this.GetMetadata(".Message_RestrictedCountry") ) %>
</ui:Panel>