<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<script runat="server"> 
/*
    private void Page_Load(object sender, System.EventArgs e) { 
        Response.Status = "301 Moved Permanently"; 
        Response.AddHeader("Location","/landing"); 
    }
*/ 
</script>
<br /><br /><br />
        <%: Html.SuccessMessage(this.GetMetadata(".Success_Message"))%>
<br /><br />

<script>
top.location.href='/';
</script>


<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        _gaq.push(['_trackEvent', 'Registration', 'ActivationMailConfirmed', 'Success']);
        window.location.href="/";
        setTimeout(function () { $(document).trigger("EMAIL_ACTIVATED", ''); }, 5000);
    });
</script>