<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="CM.Web.UI" %>

<script type="text/C#" runat="server">
    private string GetOptionMetadata(string optionName, string metaItem)
    {
        string label = new StringBuilder(".").Append(optionName).Append(metaItem).ToString();
        return this.GetMetadata(label);
    }
    
    private List<SelfExclusionPeriod> GetCoolOffPeriodSetting()
    {
        List<SelfExclusionPeriod> list = new List<SelfExclusionPeriod>();
        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetCoolOffSettingsRequest getCoolOffSettingsRequest = client.SingleRequest<GetCoolOffSettingsRequest>(new GetCoolOffSettingsRequest()
            {
                DomainId = SiteManager.Current.DomainID,
            });

            this.CoolOffEnabled = getCoolOffSettingsRequest.CoolOffEnableFrontEndOptions;

            if (this.CoolOffEnabled)
            {
                //list.Add(SelfExclusionPeriod.CoolOffNone);

                if (getCoolOffSettingsRequest.CoolOffAllow24HoursOption)
                    list.Add(SelfExclusionPeriod.CoolOffFor24Hours);

                if (getCoolOffSettingsRequest.CoolOffAllow7DaysOption)
                    list.Add(SelfExclusionPeriod.CoolOffFor7Days);

                if (getCoolOffSettingsRequest.CoolOffAllow30DaysOption)
                    list.Add(SelfExclusionPeriod.CoolOffFor30Days);

                if (getCoolOffSettingsRequest.CoolOffAllow3MonthsOption)
                    list.Add(SelfExclusionPeriod.CoolOffFor3Months);
                
                if (getCoolOffSettingsRequest.CoolOffAllowUntilOption)
                    list.Add(SelfExclusionPeriod.CoolOffUntilSelectedDate);
            }
        }

        return list;
    }
    

    private List<SelfExclusionPeriod> GetAvailableCoolOffPeriods()
    {
        List<SelfExclusionPeriod> periods = new List<SelfExclusionPeriod>();

        foreach (SelfExclusionPeriod selfExclusionPeriod in GetCoolOffPeriodSetting())
        {

            periods.Add(selfExclusionPeriod);
        }
        return periods;
    }


    private List<SelfExclusionPeriod> AvailableCoolOffPeriods { get; set; }
    private bool CoolOffEnabled { get; set; }
    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        this.AvailableCoolOffPeriods = (GetAvailableCoolOffPeriods() ?? new List<SelfExclusionPeriod>());
        
    }

    private SelectList GetCoolOffReasons()
    {

        string[] paths = Metadata.GetChildrenPaths("/Metadata/CoolOff/CoolOffReasons");
        var list = paths.Select(p => new { Key = p.Substring(p.LastIndexOf("/")+1), Value = this.GetMetadata(p,".Text") }).ToList();

        return new SelectList(list, "Key", "Value");
    }

    private SelectList GetUnsatisfiedReason()
    {

        string[] paths = Metadata.GetChildrenPaths("/Metadata/CoolOff/UnsatisfiedReasons");
        var list = paths.Select(p => new { Key = p.Substring(p.LastIndexOf("/")+1), Value = this.GetMetadata(p,".Text") }).ToList();

        return new SelectList(list, "Key", "Value");
    }
    
</script>
<%
if (this.CoolOffEnabled)
{
   %>
<form id="formCoolOff" action="<%= Url.RouteUrl("SelfExclusion", new { @action = "ApplyCoolOff" }).SafeHtmlEncode() %>" method="post" class="FormList SelfExclusionForm CoolOffForm" >
    
	<fieldset>
		<legend class="hidden">
			<%= this.GetMetadata(".HEAD_TEXT").SafeHtmlEncode()%>
		</legend>
        <div class="Container">
        <p class="SelfExclusionText"><%= this.GetMetadata(".Presentation").HtmlEncodeSpecialCharactors()%>
        </div>
		<ul class="FormList SelfExclusionList CoolOffList">
            <li class="FormItem SelfExclusionItem">
                <label class="FormLabel" for="limitAmount"><%= this.GetMetadata(".CoolOffReason_Label").SafeHtmlEncode()%></label>
                <%: Html.DropDownList("coolOffReason", GetCoolOffReasons(), new 
                {
                    @id = "ddlCoolOffReason",
                    @class = "FormInput", 
                    @validator = ClientValidators.Create()
                        .Required( this.GetMetadata(".CoolOffReason_Empty"))
                })%>
            </li>
            <li class="FormItem SelfExclusionItem" id="fldUnsatisfiedReason">
                <label class="FormLabel" for="limitAmount"><%= this.GetMetadata(".UnsatisfiedReason_Label").SafeHtmlEncode()%></label>
                <%: Html.DropDownList("unsatisfiedReasonSelector", GetUnsatisfiedReason(), new 
                {
                    @id = "ddlUnsatisfiedReason",
                    @class = "FormInput", 
                    @validator = ClientValidators.Create()
                        .Required( this.GetMetadata(".UnsatisfiedReason_Empty"))
                })%>
            </li>
            <li class="FormItem SelfExclusionItem" id="fldCoolOffDescription">
                <label class="FormLabel" for="limitAmount"><%= this.GetMetadata(".CoolOffReasonDescription_Label").SafeHtmlEncode()%></label>
                <%: Html.TextBox("coolOffDescription", string.Empty, new 
		        {
                    @maxlength = 100,
		            @id = "txtCoolOffDescription",
                    @class = "FormInput", 
                    @validator = ClientValidators.Create()
                        .Required(this.GetMetadata(".CoolOffReasonDescription_Empty"))
                        .MaxLength(100, this.GetMetadata(".CoolOffReasonDescription_Length"))
		        }) %>
            </li>
            <input type="hidden" name="unsatisfiedReason" id="unsatisfiedReason" />
            <input type="hidden" name="coolOffReasonDescription" id="coolOffReasonDescription" />
            <input type="hidden" name="unsatisfiedDescription" id="unsatisfiedDescription" />
            <script type="text/javascript">
                $(function () {
                    $('#ddlCoolOffReason').change(function () {
                        $('#fldCoolOffDescription').hide();
                        $('#fldUnsatisfiedReason').hide();
                        if ($(this).val().toLowerCase() == 'other') {
                            $('#fldCoolOffDescription').show();
                        }
                        else {
                            if ($(this).val().toLowerCase() == 'unsatisfied') {
                                $('#fldUnsatisfiedReason').show();
                            }
                        }

                        $('#ddlUnsatisfiedReason').change();
                    });

                    $('#ddlUnsatisfiedReason').change(function () {
                        if ($('#ddlCoolOffReason').val().toLowerCase() == 'unsatisfied') {
                            if ($('#ddlUnsatisfiedReason').val().toLowerCase() == 'other') {
                                $('#fldCoolOffDescription').show();
                            }
                            else {
                                $('#fldCoolOffDescription').hide();
                            }
                        }
                    });

                    $('#ddlCoolOffReason').change();

                });
            </script>

			<% 
				bool first = true;
                string optionName = string.Empty;
                foreach (SelfExclusionPeriod selfExclusionPeriod in this.AvailableCoolOffPeriods)
				{
                    optionName = selfExclusionPeriod.ToString();
			%>
			<li class="FormItem SelfExclusionItem">
				<input class="FormRadio" type="radio" name="coolOffPeriod" value="<%= optionName %>" id="option<%= optionName %>" <%= first ? "checked=\"checked\"" : "" %> />
				<label class="FormBulletLabel" for="option<%= optionName %>"><%= GetOptionMetadata(optionName, "Option").SafeHtmlEncode()%></label>
                <% if(selfExclusionPeriod == SelfExclusionPeriod.CoolOffUntilSelectedDate) {%>
                    <%: Html.TextBox("selectedDate", string.Empty, new 
		                {
                            @maxlength = 100,
                            @readonly = "readonly",
		                    @id = "txtCoolOffUntilSelectedDate",
                            @class = "FormInput", 
                            @validator = ClientValidators.Create()
                                .Custom("validateCoolOffUntil")                                
		                }
                    ) %>
                    <script type="text/ecmascript">
                        function validateCoolOffUntil() {
                            if ($('#option<%=optionName %>').prop('checked')) {
                            var _str = $('#txtCoolOffUntilSelectedDate').val();
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
                        var _minDate = new Date();
                        _minDate = new Date(_minDate.setDate(_minDate.getDate() + 1));
                        $("#txtCoolOffUntilSelectedDate").datepickerEx({
                            changeMonth: true,
                            changeYear: true,
                            maxDate: _date,
                            minDate: _minDate,
                            setDate: _date
                        });

                        function showCoolOffUntilSelectedDate()
                        {
                            if ($('#option<%=optionName %>').prop('checked')) {
                                $('#txtCoolOffUntilSelectedDate').show();
                            }
                            else {
                                $('#txtCoolOffUntilSelectedDate').hide();
                            }
                        }
                        showCoolOffUntilSelectedDate();
                        $('input[name="coolOffPeriod"]').click(function(){
                            showCoolOffUntilSelectedDate();
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
		<button class="Button AccountButton SubmitRegister" type="submit" name="send" id="btnApplyCoolOff">
			<strong class="ButtonText"><%= this.GetMetadata(".Button_Submit")%></strong>
		</button>
	</div>
</form>
<script type="text/javascript">
    $(function () {
        $('#formCoolOff').initializeForm();

        function initCoolOffWarningMSG() {
            var _msg = '<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>';
            var _option = $('#formCoolOff input:radio[name=coolOffPeriod]:checked').val();
            var _date = new Date();
            switch (_option) {
                case "CoolOffFor24Hours":
                    _date.setDate(_date.getDate() + 1);
                    break;
                case "CoolOffFor7Days":
                    _date.setDate(_date.getDate() + 7);
                    break;
                case "CoolOffFor30Days":
                    _date.setDate(_date.getDate() + 30);
                    break;
                case "CoolOffFor3Months":
                    _date.setMonth(_date.getMonth() + 3);
                    break;
                case "CoolOffUntilSelectedDate":
                    _date = new Date($('#txtCoolOffUntilSelectedDate').val());
                    break;
                default:
            }

            return _msg.format(_date.toLocaleDateString());
        }

        $('#btnApplyCoolOff').click(function (e) {
            e.preventDefault();

            if (!$('#formCoolOff').valid())
                return false;

            if ($('#formCoolOff input:radio[name=coolOffPeriod]:checked').length == 0)
                return false;

            if (!window.confirm(initCoolOffWarningMSG()))
                return false;

            $('#unsatisfiedReason').val('');
            $('#coolOffReasonDescription').val('');
            $('#unsatisfiedDescription').val('');

            if ($('#ddlCoolOffReason').val().toLowerCase() == 'other') {
                $('#coolOffReasonDescription').val($('#txtCoolOffDescription').val());
            }
            else if ($('#ddlCoolOffReason').val().toLowerCase() == 'unsatisfied') {
                $('#unsatisfiedReason').val($('#ddlUnsatisfiedReason').val());
                if ($('#ddlUnsatisfiedReason').val().toLowerCase() == 'other') {
                    $('#unsatisfiedDescription').val($('#txtCoolOffDescription').val());
                }
                else {
                    $('#unsatisfiedDescription').val('');
                }
            }

            $('#formCoolOff').submit();
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
