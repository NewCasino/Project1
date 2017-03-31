<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<script type="text/C#" runat="server">

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

        foreach (SelfExclusionPeriod selfExclusionPeriod in GetSelfExclusionPeriodSetting())
        {
            if (Settings.IsUKLicense
            && !ukLicensePeriods.Exists(p => p == selfExclusionPeriod))
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


<%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
<ui:Panel runat="server" ID="pnSelfExclusion">
<div class="presentation">
<%= this.GetMetadata(".Presentation").HtmlEncodeSpecialCharactors() %>
</div>

<%
if (this.SelfExclusionEnabled)
{
   using (Html.BeginRouteForm("SelfExclusion", new { @action = "ApplySelfExclusion" }, FormMethod.Post, new { @id = "formSelfExclusion" }))
   {  %>

<table cellpadding="0" cellspacing="0" border="0" class="options-table">

<%     
    string periodName;
    string title;
    foreach (SelfExclusionPeriod selfExclusionPeriod in AvailableSelfExclusionPeriods)
    {
        periodName = selfExclusionPeriod.ToString();
        title = this.GetMetadata(string.Format(CultureInfo.InvariantCulture, ".{0}Option", periodName)).DefaultIfNullOrWhiteSpace(periodName);
            
        %>
        <tr class="<%=periodName %>">
            <td>
                <input type="radio" name="selfExclusionOption" value="<%=periodName %>" id="option<%=periodName %>" />
            </td>
            <td>
                <label for="option<%=periodName %>"><strong><%= title.SafeHtmlEncode()%></strong></label>
                <% if(selfExclusionPeriod == SelfExclusionPeriod.SelfExclusionUntilSelectedDate) {%>
                <ui:InputField ID="fldSelfExclusionUntilSelectedDate" runat="server" ShowDefaultIndicator="true" BalloonArrowDirection="Left" >
                    <LabelPart></LabelPart>
	                <ControlPart>
		                <%: Html.TextBox("selectedDate", string.Empty, new 
		                    {
                                @maxlength = 100,
                                @readonly = "readonly",
		                        @id = "txtSelfExclusionUntilSelectedDate",
                                @validator = ClientValidators.Create()
                                    .Custom("validateSelfExclusionUntil")                                
		                    }
                        ) %>
	                </ControlPart>
                </ui:InputField>
                <script type="text/ecmascript">
                    function validateSelfExclusionUntil() {
                        if ($('#option<%=periodName %>').prop('checked')) {
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
                        });//.val(minDate);

                        function showSelfExclusionUntilSelectedDate() {
                            if ($('#option<%=periodName %>').prop('checked')) {
                                $('#fldSelfExclusionUntilSelectedDate').show();
                            }
                            else {
                                $('#fldSelfExclusionUntilSelectedDate').hide();
                            }
                        }
                        showSelfExclusionUntilSelectedDate();
                        $('input[name="selfExclusionOption"]').click(function () {
                            showSelfExclusionUntilSelectedDate();
                        });
                    });
                </script>
                <% } %>
            </td>
        </tr>
        <tr>
            <td colspan="2"><%=this.GetMetadata(string.Format(CultureInfo.InvariantCulture, ".{0}Description", periodName)).SafeHtmlEncode() %></td>
        </tr>
        <%
    }
%>
</table>

<br />

<center>
    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnApplySelfExclusion" })%>
</center>
<% } %>
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
                return;

            if (!$('#formSelfExclusion').valid())
                return;

            if (!window.confirm(initSelfExclusionWarningMSG())) return;

            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnApplySelfExclusion').toggleLoadingSpin(false);
                    $(document).trigger("_ON_SelfExclusionCoolOff_APPLIED", html);
                },
                error: function (xhr, textStatus, errorThrown) {
                    alert(errorThrown);
                    $('#btnApplySelfExclusion').toggleLoadingSpin(false);
                }
            };
            $('#formSelfExclusion').ajaxForm(options);
            $('#formSelfExclusion').submit();
        });
    });
</script>
<%
} 
%>
</ui:Panel>