<%@ Page Language="C#" MasterPageFile="~/Views/System/Content.master" Inherits="CM.Web.ViewPageEx"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/TermsConditions/Index.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div id="terms-conditions-form-wrapper">

    <div class="ui-widget">
	    <div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all"> 
		    <p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-info"></span>
		    <strong>NOTE!</strong> Changes made here affect all existing users within this operator.</p>
	    </div>
    </div>


   <ul class="terms-conditions-options">
        <li>
            <input type="radio" name="termsConditionsChange" value="Major" id="btnForceAcceptTC" />
            <label for="btnForceAcceptTC">Force players to accept T&amp;C</label>
        </li>
        <li>
            <input type="radio" name="termsConditionsChange" value="Minor" id="btnNotifyAcceptTC" />
            <label for="btnNotifyAcceptTC">Notify players T&amp;C has been changed.</label>
        </li>
        <li>
            <input type="radio" name="termsConditionsChange" value="No" id="btnNoNotification" />
            <label for="btnNoNotification">Clear the flags and no notification to players.</label>
        </li>
   </ul>
   <ui:Button runat="server" Text="Submit" ID="btnSubmitTC">  </ui:Button>


</div>

<script type="text/javascript">
    $(function () {
        $('#btnSubmitTC').click(function (e) {
            e.preventDefault();
            if ($('input[name="termsConditionsChange"]:checked').length == 0) {
                alert('Please select the option');
                return;
            }

            if (window.confirm('Are you sure to apply this change?') != true)
                return;

            if (self.startLoad) self.startLoad();

            var url = '<%= this.Url.RouteUrl( "TermsConditionsManager", new { @action = "Apply" }).SafeJavascriptStringEncode() %>';
            var data = { distinctName: '<%= this.ViewData["distinctName"] %>', now: (new Date()).getTime() };
            data.termsConditionsChange = $('input[name="termsConditionsChange"]:checked').val();
            $(this).attr('disabled', true);
            jQuery.getJSON(url, data, function (json) {
                if (self.stopLoad) self.stopLoad();
                $('#btnSubmitTC').attr('disabled', false);
                if (!json.success) { alert(result.error); return; }

                alert('Operation completed successfully!');
            });
        });
    });
</script>

</asp:Content>

