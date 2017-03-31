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
<li class="FormItem FormItem_Captcha">
	<label class="FormLabel" for="captcha"><%= this.GetMetadata(".Captcha_Label").SafeHtmlEncode()%></label>
	<p><img id="captchaImg" onclick="__changeCaptcha()" src="<%= InitCaptcha ? CaptchaUrl : string.Empty %>" /></p>
	<%: Html.TextBox("captcha", "", new Dictionary<string, object>()
	{
		{ "class", "FormInput" },
		{ "id", "captcha" },
		{ "autocomplete", "off" },
		{ "maxlength", "6" },
		{ "placeholder", this.GetMetadata(".Captcha_Label") },
		{ "required", "required" },
		{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".Captcha_Empty"))}                    
	}) %>
	<span class="FormStatus">Status</span>
	<span class="FormHelp"></span>
	<span class="FormAdditional"><a class="FormHit" href="#" onclick="__changeCaptcha(); return false;"><%= this.GetMetadata(".Captcha_Hint").SafeHtmlEncode() %></a></span>
</li>

<script language="javascript" type="text/javascript">
    function __changeCaptcha() {
        var $img = $('#captchaImg');
        $img.attr('src', '<%= CaptchaUrl.SafeJavascriptStringEncode() %>?_t=' + (new Date()).toString());
    }
</script>
