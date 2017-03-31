<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
    private List<string> SelfExclusionOptions { get; set; }

	private string GetOptionMetadata(string optionName, string metaItem)
	{
        string label = new StringBuilder(".").Append(optionName).Append(metaItem).ToString();
		return this.GetMetadata(label);
	}

    private List<SelfExclusionPeriod> GetSelfExclusionPeriodSetting()
    {
        List<SelfExclusionPeriod> list = new List<SelfExclusionPeriod>();
        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetSelfExclusionSettingsRequest getSelfExclusionSettingsRequest = client.SingleRequest<GetSelfExclusionSettingsRequest>(new GetSelfExclusionSettingsRequest()
            {
                DomainId = SiteManager.Current.DomainID,
            });

            this.SelfExclusionEnabled = getSelfExclusionSettingsRequest.SelfExclusionEnableFrontEndOptions;

            if (this.SelfExclusionEnabled)
            {
                //list.Add(SelfExclusionPeriod.SelfExclusionNone);

                if (getSelfExclusionSettingsRequest.SelfExclusionAllow6MonthsOption)
                    list.Add(SelfExclusionPeriod.SelfExclusionFor6Months);

                if (getSelfExclusionSettingsRequest.SelfExclusionAllow1YearOption)
                    list.Add(SelfExclusionPeriod.SelfExclusionFor1Year);

                if (getSelfExclusionSettingsRequest.SelfExclusionAllow5YearsOption)
                    list.Add(SelfExclusionPeriod.SelfExclusionFor5Years);

                if (getSelfExclusionSettingsRequest.SelfExclusionAllowUntilOption)
                    list.Add(SelfExclusionPeriod.SelfExclusionUntilSelectedDate);

                if (getSelfExclusionSettingsRequest.SelfExclusionAllowPermanentOption)
                    list.Add(SelfExclusionPeriod.SelfExclusionPermanent);
            }
        }

        return list;
    }

    private List<SelfExclusionPeriod> GetUkLicenseSelfExclusionPeriods()
    {
        return new List<SelfExclusionPeriod>
        {
            SelfExclusionPeriod.SelfExclusionFor6Months,
            SelfExclusionPeriod.SelfExclusionFor1Year
        };
    }

    private List<SelfExclusionPeriod> GetAvailableSelfExclusionPeriods()
    {
        List<SelfExclusionPeriod> periods = new List<SelfExclusionPeriod>();
        List<SelfExclusionPeriod> ukLicensePeriods = GetUkLicenseSelfExclusionPeriods();

        List<string> disabledOptionNameList = new List<string>();
        string disabledConfig = this.GetMetadata(".DisabledOptions");
        if (!string.IsNullOrEmpty(disabledConfig))
        {
            disabledOptionNameList = disabledConfig.Split(new char[] { ',' }, StringSplitOptions.RemoveEmptyEntries).ToList();
        }
        
        foreach (SelfExclusionPeriod selfExclusionPeriod in GetSelfExclusionPeriodSetting())
        {
            if (Settings.IsUKLicense
            && !ukLicensePeriods.Exists(p => p == selfExclusionPeriod))
                continue;

            if (disabledOptionNameList.Exists(p => p.Equals(selfExclusionPeriod.ToString(), StringComparison.OrdinalIgnoreCase)))
                continue;

            periods.Add(selfExclusionPeriod);
        }
        
        return periods;
    }

    private List<SelfExclusionPeriod> AvailableSelfExclusionPeriods { get; set; }
    private bool SelfExclusionEnabled { get; set; }
    
	protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        this.AvailableSelfExclusionPeriods = (GetAvailableSelfExclusionPeriods() ?? new List<SelfExclusionPeriod>());
    }
</script>

<%
if (this.SelfExclusionEnabled)
{
   %>
<form id="formSelfExclusion" action="<%= Url.RouteUrl("SelfExclusion", new { @action = "ApplySelfExclusion" }, Request.Url.Scheme).SafeHtmlEncode() %>" method="post" class="FormList SelfExclusionForm" >
    
	<fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode()%>
		</legend>
        <div class="Container SelfExclusionDemo">
        <p class="SelfExclusionText"><%= this.GetMetadata(".Presentation").HtmlEncodeSpecialCharactors()%>
        </div>
		<ul class="FormList SelfExclusionList">
			<% 
				bool first = true;
                string optionName = string.Empty;
                foreach (SelfExclusionPeriod selfExclusionPeriod in this.AvailableSelfExclusionPeriods)
				{
                    optionName = selfExclusionPeriod.ToString();
			%>
			<li class="FormItem SelfExclusionItem">
				<input class="FormRadio" type="radio" name="selfExclusionOption" value="<%= optionName %>" id="option<%= optionName %>" <%= first ? "checked=\"checked\"" : "" %> />
				<label class="FormBulletLabel" for="option<%= optionName %>"><%= GetOptionMetadata(optionName, "Option").SafeHtmlEncode()%></label>
                <% if(selfExclusionPeriod == SelfExclusionPeriod.SelfExclusionUntilSelectedDate) {%>
                    <%: Html.TextBox("selectedDate", string.Empty, new 
		                {
                            @maxlength = 100,
                            @readonly = "readonly",
                            @class = "FormInput", 
		                    @id = "txtSelfExclusionUntilSelectedDate",
                            @validator = ClientValidators.Create()
                                .Custom("validateSelfExclusionUntil")                                
		                }
                    ) %>
                    <script type="text/ecmascript">
                        function validateSelfExclusionUntil() {
                            if ($('#option<%=optionName %>').prop('checked')) {
                                var _str = $('#txtSelfExclusionUntilSelectedDate').val();
                                if (_str.trim() == '')
                                    return '<%=this.GetMetadata(".Date_Invalid").SafeJavascriptStringEncode()%>';

                                if (/Invalid|NaN/.test(new Date(_str)))
                                    return '<%=this.GetMetadata(".Date_Invalid").SafeJavascriptStringEncode()%>';
                            }
                            return true;
                        }

                        $(function () {
                            var _date = new Date();
                            _date.setMonth(_date.getMonth() + 6);
                            var _dateStr = _date.getMonth() + "/" + _date.getDate() + "/" + _date.getFullYear();
                            $("#txtSelfExclusionUntilSelectedDate").datepickerEx({
                                changeMonth: true,
                                changeYear: true,
                                minDate: _date,
                                setDate: _date
                            });

                            function showSelfExclusionUntilSelectedDate() {
                                if ($('#option<%=optionName %>').prop('checked')) {
                                    $('#txtSelfExclusionUntilSelectedDate').show();
                                }
                                else {
                                    $('#txtSelfExclusionUntilSelectedDate').hide();
                                }
                            }
                            showSelfExclusionUntilSelectedDate();
                            $('input[name="selfExclusionOption"]').click(function () {
                                showSelfExclusionUntilSelectedDate();
                            });
                        });
                    </script>
                <% } %>
				<span class="FormBulletDesc"><%= GetOptionMetadata(optionName, "Description").SafeHtmlEncode()%></span>
			</li>
			<%
					first = false;
				}
			%>            
		</ul>
	</fieldset>
	<div class="AccountButtonContainer SelfExclusionBTN">        
		<button class="Button AccountButton SubmitRegister" type="submit" name="send" id="btnApplySelfExclusion">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit")%></strong>
		</button>
	</div>
</form>
<script language="javascript" type="text/javascript">
    $(function () {
        $('#formSelfExclusion').initializeForm();

        function initSelfExclusionWarningMSG() {
            var _msg = '<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>';

            var _option = $('#formSelfExclusion input:radio[name=selfExclusionOption]:checked').val();

            if (_option == "SelfExclusionPermanent") {
                _msg = '<%= this.GetMetadata(".Confirmation_Message_Permanent").SafeJavascriptStringEncode() %>';
                return _msg;
            }

            var _date = new Date();
            switch (_option) {
                case "SelfExclusionFor6Months":
                    _date.setMonth(_date.getMonth() + 6);
                    break;
                case "SelfExclusionFor1Year":
                    _date.setFullYear(_date.getFullYear() + 1);
                    break;
                case "SelfExclusionFor5Years":
                    _date.setFullYear(_date.getFullYear() + 5);
                    break;
                case "SelfExclusionUntilSelectedDate":
                    _date = new Date($('#txtSelfExclusionUntilSelectedDate').val());
                    break;
                default:
            }

            return _msg.format(_date.toLocaleDateString());
        }

        $('#btnApplySelfExclusion').click(function (e) {
            e.preventDefault();
            if ($('#formSelfExclusion input:radio[name=selfExclusionOption]:checked').length == 0)
                return false;

            if (!$('#formSelfExclusion').valid())
                return false;

            if (!window.confirm(initSelfExclusionWarningMSG()))
                return false;

            $('#formSelfExclusion').submit();
        });
    });
</script>
<% 
} 
else{ %>
<fieldset>
	<legend class="hidden">
		<%= this.GetMetadata(".HEAD_TEXT_NoOption").SafeHtmlEncode()%>
	</legend>
    <div class="Container SelfExclusionDemo">
    <p class="SelfExclusionText"><%= this.GetMetadata(".Presentation").HtmlEncodeSpecialCharactors()%>
    </div>
</fieldset>
<%
}
%> 