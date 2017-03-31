<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<center>
    <br />
    <%: Html.SuccessMessage( this.GetMetadata(".Message") ) %>
</center>
<script language="javascript" type="text/javascript">
    setTimeout(function () {
        self.location = '/';
    }, 5000);
</script>