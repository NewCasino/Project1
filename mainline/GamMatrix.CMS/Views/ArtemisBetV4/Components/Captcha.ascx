<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<div class="captcha-container">
<label for="captcha" class="inputfield_Label"><%= this.GetMetadata(".Captcha_Label").SafeHtmlEncode()%></label>
<ui:InputField ID="fldCaptcha" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left" >
<LabelPart></LabelPart>
<ControlPart>
   <%: Html.TextBox("captcha", "", new
            {
                @placeholder = this.GetMetadata(".captchaPlaceholder"),
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Captcha_Empty"))
            })%>   
        <img onclick="__changeCaptcha()" src="/Views/Shared/Components/_captcha.ashx" />
             
</ControlPart>
    <HintPart>
        <a class="SwitchThemeButton refresh" href="#" onclick="__changeCaptcha(); return false;"><%= this.GetMetadata(".Captcha_Hint").HtmlEncodeSpecialCharactors() %></a>
    </HintPart>
</ui:InputField></div>
<script language="javascript" type="text/javascript">
    function __changeCaptcha() {
        var $img = $('#fldCaptcha img');
        $img.attr('src', '/Views/Shared/Components/_captcha.ashx?_t=' + (new Date()).toString());
    }

    $(function() {
        $("#fldCaptcha .hide_default > div").hide();
    });
</script>