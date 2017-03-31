<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%=this.GetMetadata(".CSS") %>
<ui:InputField ID="fldRegisterCaptcha" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left" >
	<LabelPart><%= this.GetMetadata("/Components/_Captcha_ascx.Captcha_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <img id="imgRegisterCaptcha" onclick="__changeCaptcha()" src="/Views/Shared/Components/_captcha.ashx" />
        <br />
        <%: Html.TextBox("registerCaptcha", "", new
            {
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata("/Components/_Captcha_ascx.Captcha_Empty"))
                    .Server(this.Url.RouteUrl("Register", new { @action = "VerifyRegisterCaptcha", @message = this.GetMetadata("/Components/_Captcha_ascx.Captcha_Invalid") }))
            })%>           
	</ControlPart>
    <HintPart>
        <a href="#" onclick="__changeCaptcha(); return false;"><%= this.GetMetadata("/Components/_Captcha_ascx.Captcha_Hint").HtmlEncodeSpecialCharactors() %></a>
    </HintPart>
</ui:InputField>
<script language="javascript" type="text/javascript">
    function __changeCaptcha() {
        var $img = $('#fldRegisterCaptcha img');
        $img.attr('src', '/Views/Shared/Components/_captcha.ashx?_t=' + (new Date()).toString());
    }

    $(function() {
        $("#fldRegisterCaptcha .hide_default > div").hide();
    });
</script>
<%=this.GetMetadata(".Script") %>