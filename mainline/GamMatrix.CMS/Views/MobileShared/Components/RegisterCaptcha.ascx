<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="CM.Web.UI" %>
<script type="text/C#" runat="server">
    public bool InitCaptcha
    {
        get {
            if (this.ViewData["InitCaptcha"] != null)
            {
                bool _value = true;
                if (bool.TryParse(this.ViewData["InitCaptcha"].ToString(), out _value))
                    return _value;
                
                return true;
            }
            return true;
        }
    }
    public string CaptchaUrl {
        get {
            return "/Views/MobileShared/Components/_captcha.ashx";
        }
    }
</script>
<%=this.GetMetadata(".CSS") %>
<li class="FormItem FormItem_Captcha">
	<label class="FormLabel" for="captcha"><%= this.GetMetadata("/Components/_Captcha_ascx.Captcha_Label").SafeHtmlEncode()%></label>
	<p><img id="imgRegisterCaptcha" onclick="__changeCaptcha()" src="<%= InitCaptcha ? CaptchaUrl : string.Empty %>" /></p>
	<%: Html.TextBox("registerCaptcha", "", new Dictionary<string, object>()
    {
        { "class", "FormInput" },
        { "id", "registerCaptcha" },
        { "autocomplete", "off" },
        { "maxlength", "6" },
        { "placeholder", this.GetMetadata("/Components/_Captcha_ascx.Captcha_Label") },
        { "required", "required" },
        { "data-validator", ClientValidators.Create().Required(this.GetMetadata("/Components/_Captcha_ascx.Captcha_Empty"))
        .Server(this.Url.RouteUrl("Register", new { @action = "VerifyRegisterCaptcha", @message = this.GetMetadata("/Components/_Captcha_ascx.Captcha_Invalid") }))}
    }) %>
	<span class="FormStatus">Status</span>
	<span class="FormHelp"></span>
	<span class="FormAdditional"><a class="FormHit" href="#" onclick="__changeCaptcha(); return false;"><%= this.GetMetadata("/Components/_Captcha_ascx.Captcha_Hint").SafeHtmlEncode() %></a></span>
</li>

<script language="javascript" type="text/javascript">
    function __changeCaptcha() {
        var $img = $('#imgRegisterCaptcha');
        $img.attr('src', '<%= CaptchaUrl.SafeJavascriptStringEncode() %>?_t=' + (new Date()).toString());
    }
</script>
<%=this.GetMetadata(".Script") %>