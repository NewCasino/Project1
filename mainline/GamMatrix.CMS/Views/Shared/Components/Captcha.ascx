<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<ui:InputField ID="fldCaptcha" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left" >
	<LabelPart><%= this.GetMetadata(".Captcha_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <img onclick="__changeCaptcha()" src="/Views/Shared/Components/_captcha.ashx" />
        <br />
        <%: Html.TextBox("captcha", "", new
            {
                @validator = ClientValidators.Create()
                    .Required(this.GetMetadata(".Captcha_Empty"))
            })%>           
	</ControlPart>
    <HintPart>
        <a href="#" onclick="__changeCaptcha(); return false;"><%= this.GetMetadata(".Captcha_Hint").HtmlEncodeSpecialCharactors() %></a>
    </HintPart>
</ui:InputField>
<script language="javascript" type="text/javascript">
    function __changeCaptcha() {
        var $img = $('#fldCaptcha img');
        $img.attr('src', '/Views/Shared/Components/_captcha.ashx?_t=' + (new Date()).toString());
    }

    $(function() {
        $("#fldCaptcha .hide_default > div").hide();
    });
</script>