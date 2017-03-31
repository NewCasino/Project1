<%@ Page Language="C#" PageTemplate="/ProfileMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>
<%@ Import Namespace="CM.db.Accessor" %>

<script language="C#" type="text/C#" runat="server">
    private GetTransInfoRequest GetTransactionInfo()
    {
        return this.ViewData["getTransInfoRequest"] as GetTransInfoRequest;
    }

    private PrepareTransRequest GetPrepareTransRequest()
    {
        return this.ViewData["prepareTransRequest"] as PrepareTransRequest;
    }

    private ProcessTransRequest GetProcessTransRequest()
    {
        return this.ViewData["processTransRequest"] as ProcessTransRequest;
    }
    
    private string GetDebitMessage()
    {
        return string.Format(this.GetMetadata(".DebitAccount")
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.DebitPayItemVendorID.ToString()))
           );
    }

    private string GetCreditMessage()
    {
        UserAccessor ua = UserAccessor.CreateInstance<UserAccessor>();
        cmUser user = ua.GetByID(GetProcessTransRequest().Record.ContraUserID);
        return string.Format(this.GetMetadata(".CreditAccount")
            , string.Format("{0} {1}({2})", user.FirstName, user.Surname, user.Username)
           , this.GetMetadata(string.Format("/Metadata/GammingAccount/{0}.Display_Name", GetProcessTransRequest().Record.CreditPayItemVendorID.ToString()))
           );
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div id="buddytransfer-wrapper" class="content-wrapper">
<%: Html.H1(this.GetMetadata(".HEAD_TEXT"))%>
<ui:Panel runat="server" ID="pnBuddyTransfer">

    <center>
        <%: Html.SuccessMessage( this.GetMetadata(".Message") ) %>
    </center>


    <%------------------------
        The confirmation table
      ------------------------%>
    <table cellpadding="0" cellspacing="0" border="1" rules="all" class="confirmation_table"> 
        <tr>
            <td class="name"><%= this.GetMetadata(".Transaction_ID").SafeHtmlEncode() %></td>
            <td class="value"><%= GetTransactionInfo().TransID.ToString() %></td>
        </tr>

        <tr>
            <td class="name"><%= GetDebitMessage().SafeHtmlEncode()%></td>
            <td class="value"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.DebitRealCurrency
                                                                    , GetProcessTransRequest().Record.DebitRealAmount)%></td>
        </tr>

        <tr>
            <td class="name"><%= GetCreditMessage().SafeHtmlEncode()%></td>
            <td class="value"><%= MoneyHelper.FormatWithCurrency(GetProcessTransRequest().Record.CreditRealCurrency
                                                                    , GetProcessTransRequest().Record.CreditRealAmount)%></td>
        </tr>

    </table>
    <br />
    <center>
        <%: Html.Button(this.GetMetadata(".Button_Print"), new { @onclick = "window.print(); return false;" }) %>
    </center>

</ui:Panel>
</div>


<script language="javascript" type="text/javascript">
    $(window).load(function () {
        $(document).trigger("BALANCE_UPDATED");
        <%=this.GetMetadata(".Receipt_Script").SafeJavascriptStringEncode()%>
    });
</script>
</asp:Content>

