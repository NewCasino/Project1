<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<CM.db.cmUser>" %>

<%------------------------------------------
    3 Checkboxes
 -------------------------------------------%>
<div class="reg-addtional-info">
<ul>


<% if (this.Model == null)
   { %>
    <li>
    <ui:InputField ID="fldTermsConditions" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart></LabelPart>
	    <ControlPart>
            <%: Html.CheckBox("acceptTermsConditions", false, new { @id = "btnTermsConditions", @validator = ClientValidators.Create().Required(this.GetMetadata(".TermsConditions_Error")) })%>
            <label for="btnTermsConditions"><%= this.GetMetadata(".TermsConditions_Label").SafeHtmlEncode()%></label>
            <a href="<%= Settings.TermsConditions_Url.SafeHtmlEncode()%>" target="_blank"><%= this.GetMetadata(".TermsConditions_Link").SafeHtmlEncode()%></a>
        </ControlPart>
    </ui:InputField>
    </li>
<% } %>


    <li>
    <ui:InputField ID="fldNewsOffers" runat="server" BalloonArrowDirection="Left">
	    <LabelPart></LabelPart>
	    <ControlPart>
            <%: Html.CheckBox("allowNewsEmail", this.Model == null ? true : this.Model.AllowNewsEmail, new { @id = "btnAllowNewsEmail"})%>
            <label for="btnAllowNewsEmail"><%= this.GetMetadata(".NewsOffers_Label").SafeHtmlEncode() %> </label>            
        </ControlPart>
    </ui:InputField>
    </li>

    <li>
    <ui:InputField ID="fldSmsOffer" runat="server" BalloonArrowDirection="Left">
	    <LabelPart></LabelPart>
	    <ControlPart>
            <%: Html.CheckBox("allowSmsOffer", this.Model == null ? true : this.Model.AllowSmsOffer, new { @id = "btnAllowSmsOffer" })%>
            <label for="btnAllowSmsOffer"><%= this.GetMetadata(".SmsOffers_Label").SafeHtmlEncode() %> </label>            
        </ControlPart>
    </ui:InputField>
    </li>


<%--<% if (this.Model == null)
   { %>
    <li>
    <ui:InputField ID="fldAbove18" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left">
	    <LabelPart></LabelPart>
	    <ControlPart>
            <%: Html.CheckBox("above18", false, new { @id = "btnAbove18", @validator = ClientValidators.Create().Custom("validateAbove18Option") })%>
            <label id="lblAbove18" for="btnAbove18"><%= this.GetMetadata(".LegalAge_Label").SafeHtmlEncode()%> </label>
        </ControlPart>
    </ui:InputField>
    </li>
    <script type="text/javascript">
        function validateAbove18Option() {
            if ($("#btnAbove18").attr("checked"))
                return true;
            
            return '<%= this.GetMetadata(".LegalAge_Error").SafeJavascriptStringEncode()%>'.format(__Registration_Legal_Age);
        }
        $(document).bind("COUNTRY_SELECTION_CHANGED", function (e, data) {
            $("#lblAbove18").html('<%= this.GetMetadata(".LegalAge_Label").SafeJavascriptStringEncode()%>'.format(data.LegalAge));
            if ($("#fldAbove18").hasClass('correct') || $("#fldAbove18").hasClass('incorrect')) {
                window.setTimeout(function () {
                    $("#fldAbove18").parents("form").validate().element($("#btnAbove18"));
                }, 800);
            }
        });
    </script>
<% } %>--%>
    
</ul>
</div>