<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<br /><br /><br />
        <%: Html.SuccessMessage(this.GetMetadata(".Success_Message"), true)%>
<br /><br />



<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        setTimeout(function () { $(document).trigger("EMAIL_ACTIVATED", ''); }, 5000);
    });
</script>