<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<% Html.RenderPartial("/Home/MainContent", this.ViewData.Merge(new { })); %>


<script src="https://zz.connextra.com/dcs/tagController/tag/7d61b44fefd2/loggedin?" async defer></script>
<script language="javascript" type="text/javascript">
    $(document).ready(function () {
        setTimeout(function () { $(document).trigger("EMAIL_ACTIVATED", ''); }, 5000);
        jQuery('body').addClass('ActivateSucceed');
    });
    $(window).load(function() {
        PopUpInIframe("/RegisterSuccessPopUp","register-success-popup",670,690);
    });
</script>