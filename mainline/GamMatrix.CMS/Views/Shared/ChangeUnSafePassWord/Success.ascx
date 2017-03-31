<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<center>
    <br />
    <%: Html.SuccessMessage( this.GetMetadata("/ChangePwd/_Success_ascx.Message") ) %>
</center>
<script language="javascript" type="text/javascript">
    function GotoHomePage() {
        top.location = "/";
    }
    setTimeout(GotoHomePage(), 3000);
</script>