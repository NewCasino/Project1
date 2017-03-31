<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>


<br />
<br />
<br />
<%: Html.SuccessMessage(this.GetMetadata(Settings.Registration.RequireActivation ? ".Success_Message" : ".Success_Message_NotRequireActivation"), true)%>
<br />
<br />
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        setTimeout(function () { $(document).trigger("REGISTRATION_COMPLETED", ''); }, 5000);
    });
</script>