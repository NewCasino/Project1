<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<% using (Html.BeginRouteForm("_UpdateAffiliateMarker", new { @action = "Update" }, FormMethod.Post, new { @id = "formAffiliateMarker" }))
   { %>
    <ul class="form_ul">
        <li class="field_item">
            <%------------------------------------------
                AffiliateMarker
             -------------------------------------------%>
            <ui:InputField ID="fldAffiliateMarker" runat="server" ShowDefaultIndicator="false" BalloonArrowDirection="Left">
	        <LabelPart><%= this.GetMetadata(".AffiliateMarker_Label").SafeHtmlEncode() %></LabelPart>
	        <ControlPart>
		        <%: Html.TextBox("affiliateMarker", Profile.AffiliateMarker , new { 
                    @maxlength = 64,
                    @id = "txtAffiliateMarker" })%>
	        </ControlPart>
            </ui:InputField>
        </li>
        <li class="field_item">
            <div class="button-wrapper">
            <%: Html.Button(this.GetMetadata(".Button_Update"), new { @id = "btnAffiliateMarker" })%>
            </div>
        </li>
    </ul>
<%} %>
<ui:MinifiedJavascriptControl runat="server" ID="scriptAffiliateMarker" AppendToPageEnd="true" Enabled="false">
    <script type="text/javascript">
        $(function () {
            $('#formAffiliateMarker').initializeForm();
            $('#btnAffiliateMarker').click(function (e) {
                e.preventDefault();
                $('#btnAffiliateMarker').toggleLoadingSpin(true);
                var options = {
                    dataType: "json",
                    type: 'POST',
                    success: function (json) {
                        $('#btnAffiliateMarker').toggleLoadingSpin(false);
                        if (json.success)
                            alert('<%=this.GetMetadata(".Success_Label") %>');
                        else
                            alert(json.error);
                    },
                    error: function (xhr, textStatus, errorThrown) {
                        alert(errorThrown);
                        $('#btnAffiliateMarker').toggleLoadingSpin(false);
                    }
                };
                $('#formAffiliateMarker').ajaxForm(options);
                $('#formAffiliateMarker').submit();
            });
        });
    </script>
</ui:MinifiedJavascriptControl>