<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<GamMatrixAPI.RgSessionLimitInfoRec>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script language="C#" type="text/C#" runat="server">
    private string GetExpirationDate()
    {
        if (this.Model != null)
        {
            if(this.Model.ExpiryDate.Date == DateTime.MaxValue.Date)
                return this.GetMetadata(".No_Expiration");

            return this.Model.ExpiryDate.ToString("dd/MM/yyyy");
        }
        return string.Empty;
    }

    private bool IsRemoved()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdateAmount <= 0;
    }

    private bool IsScheduled()
    {
        if (this.Model == null)
            return false;
        return this.Model.UpdateFlag && this.Model.UpdateAmount > 0;
    }

    protected override void OnPreRender(EventArgs e)
    {
        base.OnPreRender(e);

        fldExpirationDate.Visible = this.Model != null;
        if (this.Model != null)
        {
            btnSubmitSessionLimit.Style["display"] = "none";
        }
        btnChangeSessionLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
        btnRemoveSessionLimit.Visible = this.Model != null && !this.Model.UpdateFlag;
    }
</script>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="limit-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnLimit">



<form action="/Limit/SetSessionLimit<%=Request.Url.Query.SafeHtmlEncode() %>" id="formSessionTimeLimit" target="_self" method="post" enctype="application/x-www-form-urlencoded">

<div id="session-limit">
<p><%= this.GetMetadata(".Introduction").SafeHtmlEncode() %></p>

<br />
<%------------------------------------------
    Minutes
 -------------------------------------------%>
<ui:InputField ID="fldSessionLimitMinutes" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".Minutes_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("minutes"
            , ((this.Model == null) ? string.Empty : (this.Model.Amount / 60).ToString())
            , (new Dictionary<string, object>()  
		    { 
			    { "id", "txtSessionLimitMinutes" },
			    { "dir", "ltr" },
                { "maxlength", "5" },
                { "style", "text-align:right" },
			    { "validator", ClientValidators.Create().Required(this.GetMetadata(".Minutes_Empty")).Min( 1, "validateSessionMinutes") }
		    }).SetReadOnly(this.Model!= null)
            )%>
	</ControlPart>
</ui:InputField>


<%------------------------------------------
    Expiration date
 -------------------------------------------%>
<ui:InputField ID="fldExpirationDate" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	<LabelPart><%= this.GetMetadata(".ExpirationDate_Label").SafeHtmlEncode()%></LabelPart>
	<ControlPart>
        <%: Html.TextBox("expirationDate" , GetExpirationDate() , new { @readonly = "readonly" })%>
	</ControlPart>
</ui:InputField>


<center>

<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Back) %>" id="btnLimitBack" CssClass="BackButton button" onclick="self.location='/Limit'" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Submit) %>" id="btnSubmitSessionLimit" CssClass="ContinueButton button" type="submit"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Change) %>" id="btnChangeSessionLimit" CssClass="ContinueButton button" type="button"></ui:Button>
<ui:Button runat="server" Text="<%$ Metadata:value(.Button_Remove) %>" id="btnRemoveSessionLimit" CssClass="ContinueButton button" type="submit"></ui:Button>

</center>





</div>

</form>
</ui:Panel>

</div>


<ui:MinifiedJavascriptControl runat="server" AppendToPageEnd="true" Enabled="true">
<script type="text/javascript">
    $(document).ready(function () {

        $('#txtSessionLimitMinutes').allowNumberOnly();
        $('#formSessionTimeLimit').initializeForm();

        $('#btnSubmitSessionLimit').click(function (e) {
            if (!$('#formSessionTimeLimit').valid()) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
        });

        $('#btnChangeSessionLimit').click(function (e) {
            e.preventDefault();
            $(this).hide();
            $('#btnSubmitSessionLimit').show();
            $('#btnRemoveSessionLimit').hide();
            $('#txtSessionLimitMinutes').attr('readonly', false);
        });

        $('#btnRemoveSessionLimit').click(function (e) {
            if (window.confirm('<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>') != true) {
                e.preventDefault();
                return;
            }
            $(this).toggleLoadingSpin(true);
            $('#formSessionTimeLimit').attr('action', '/Limit/RemoveSessionLimit');
        });
    });
</script>
</ui:MinifiedJavascriptControl>

</asp:Content>

