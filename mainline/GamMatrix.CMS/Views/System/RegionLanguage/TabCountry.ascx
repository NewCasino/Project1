<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Controllers.System.RegionLanguageParam>" %>
    
<%@ Import Namespace="System.Text" %>
<style type="text/css">
label.red{ color:#FF0000;}
label.disabled{ color:#555555;}
label.disabled.red{ color:#880000;}
</style>
<div id="country-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li> 
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
           @action = "Dialog",
           @distinctName = this.Model.DistinctName.DefaultEncrypt(),
           @relativePath = "/.config/countries.setting".DefaultEncrypt(),
           @searchPattner = "",
           } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<div class="ui-widget">
	<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-highlight ui-corner-all"> 
		<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-info"></span>
		Difficult to find in so many countries below? Try to press <strong>CTRL + F</strong> and search the country in the page.</p>
	</div>
</div>
<br />

<% using (Html.BeginForm( "SaveCountries"
       , null
       , new { @distinctName = this.Model.DistinctName.DefaultEncrypt() }
       , FormMethod.Post
       , new { @id = "formCountry"}
    ) ) { %>


<table id="table-country" class="table-list" cellpadding="0" cellspacing="0" rules="none" border="0" rules="rows">
    <thead>
        <tr>
            <th class="col-internal-id">ID</th>
            <th class="col-english-name">English name</th>
            <th class="col-iso-3166">ISO-3166 name</th>
            <th class="col-alpha-2-code">Alpha 2 code</th>
            <th class="col-alpha-3-code">Alpha 3 code</th>
            <th class="col-currency">Currency</th>
            <th class="col-phone-code">Phone code</th>
            <th class="col-personal-id" align="left">Personal ID</th>
            <th class="col-control">
            </th>
        </tr>
    </thead>
    <tbody>       
    </tbody>
</table>
<%  } %>

<script id="country-template" type="text/html">
<% 
bool isSystemAdmin = Profile.IsInRole("CMS System Admin");
%>
<#
var d=arguments[0];
for( var i = 0; i < d.length; i++){
    var item = d[i];

    var strDisabled='';
    var isDisabled = false;
    <%if(!isSystemAdmin) {%>
    if(item.AdminLock)
    {
        strDisabled = 'onclick="return false;"';
        isDisabled = true;
    }
    <%}%>
#>
<tr <#= ((i%2) == 0) ? "" : 'class="alternate-row"' #> >
    <td valign="middle" align="center" class="col-internal-id">
        <#= item.InternalID #>
    </td>
    <td valign="middle" align="center" class="col-english-name">
        <#= item.EnglishName.htmlEncode() #>
    </td>
    <td valign="middle" align="center" class="col-iso-3166">
        <#= item.ISO_3166_Name.htmlEncode() #>
    </td>
    <td valign="middle" align="center" class="col-alpha-2-code">
        <#= item.ISO_3166_Alpha2Code.htmlEncode() #>
    </td>
    <td valign="middle" align="center" class="col-alpha-3-code">
        <#= item.ISO_3166_Alpha3Code.htmlEncode() #>
    </td>
    <td valign="middle" align="center" class="col-currency">
        <input maxlength="3" type="text" value="<#= item.CurrencyCode.htmlEncode() #>" name="Country_CurrencyCode_<#= item.InternalID #>" onfocus="this.select()" />
    </td>
    <td valign="middle" align="center" class="col-phone-code">
        <input maxlength="7" type="text" value="<#= item.PhoneCode.htmlEncode() #>" name="Country_PhoneCode_<#= item.InternalID #>" onfocus="this.select()" />
    </td>
    <td valign="middle" align="left" class="col-personal-id">
        <table class="table-content">
        <tr>
        <td colspan="2">
        <input type="checkbox" id="btnIsPersonalIdVisible_<#= item.InternalID #>" name="Country_IsPersonalIdVisible_<#= item.InternalID #>" <#= item.IsPersonalIdVisible ? 'checked="checked"' : ''  #>  value="true" />
        <label class="<#= item.IsPersonalIdVisible ? 'red' : '' #>" name="displayIsPersonalIdVisible_<#= item.InternalID #>" for="btnIsPersonalIdVisible_<#= item.InternalID #>">Visible</label>
        &nbsp;&nbsp;
        <input type="checkbox" id="btnIsPersonalIdMandatory_<#= item.InternalID #>" name="Country_IsPersonalIdMandatory_<#= item.InternalID #>" <#= item.IsPersonalIdMandatory ? 'checked="checked"' : ''  #>  value="true" />
        <label class="<#= item.IsPersonalIdMandatory ? 'red' : '' #>" name="displayIsPersonalIdMandatory_<#= item.InternalID #>" for="btnIsPersonalIdMandatory_<#= item.InternalID #>">Required</label>
        </td>
        </tr>
        </table>
        <table id="tableRestrictRegistrationByRegionCode_<#= item.InternalID #>" class="table-content table-content-details <#= item.RestrictRegistrationByRegion ? '' : 'hidden' #>">  
        <tr>
            <td colspan="2">*Write down the region codes here which you want them to be excluded from the restriction and separate them with comma. <br /><br />
            <a href="http://geolite.maxmind.com/download/geoip/misc/region_codes.csv">http://geolite.maxmind.com/download/geoip/misc/region_codes.csv</a><br /><br />
            for example: 04,05,07</td>
        </tr>
        <tr>
            <td colspan="2">
                <input type="text" name="Country_RestrictRegistrationByRegionCode_<#= item.InternalID #>" id="Country_RestrictRegistrationByRegionCode_<#= item.InternalID #>" value="<#= item.RestrictRegistrationByRegionCode #>" />
            </td>
        </tr>
        </table> 
        <table class="table-content table-content-details <#= item.IsPersonalIdVisible ? '' : 'hidden' #>">        
        <td>Max length: </td>
        <td><input maxlength="50" type="text" value="<#= item.PersonalIdMaxLength #>" name="Country_PersonalIdMaxLength_<#= item.InternalID #>" onfocus="this.select()" /></td>
        </tr>
        <tr>
        <td colspan="2">Validation Regular Expression: </td>
        </tr>
        <tr>
        <td colspan="2">        
        <textarea style="width:98%;" rows="2" autocomplete="off" name="Country_PersonalIdValidationRegularExpression_<#= item.InternalID #>" onfocus="this.select()" ><#= item.PersonalIdValidationRegularExpression #></textarea>
        </td>
        </tr>
        <tr>
        <td colspan="2" align="right"><a href="javascript:void(0)" class="btnPersonalIdMore" id="btnPersonalIdMore_<#= item.InternalID #>" data-countryid = "<#= item.InternalID #>">More...</a></td>
        </tr>
        </table>
    </td>
    <td valign="middle" align="left" class="col-control">
        <input <#= strDisabled #> type="checkbox" id="btnDisplayInRegistration_<#= item.InternalID #>" <#= item.UserSelectable ? 'checked="checked"' : ''  #> name="Country_UserSelectable_<#= item.InternalID #>" value="true"/>
        <label class="<#= isDisabled ? 'disabled ' : '' #><#= item.UserSelectable ? '' : 'red' #>" name="displayInRegistrationForm<#= item.InternalID #>" for="btnDisplayInRegistration_<#= item.InternalID #>">User selectable in form</label>
        <br />
        <input <#= strDisabled #> name="Country_RestrictRegistrationByIP_<#= item.InternalID #>" type="checkbox" id="btnRestrictRegistrationByIP_<#= item.InternalID #>" <#= item.RestrictRegistrationByIP ? 'checked="checked"' : ''  #> value="true"/>
        <label class="<#= isDisabled ? 'disabled ' : '' #><#= item.RestrictRegistrationByIP ? 'red' : '' #>" for="btnRestrictRegistrationByIP_<#= item.InternalID #>">Restrict registration by IP</label>
        <br />
        <input <#= strDisabled #> name="Country_RestrictRegistrationByRegion_<#= item.InternalID #>" type="checkbox" id="btnRestrictRegistrationByRegion_<#= item.InternalID #>" <#= item.RestrictRegistrationByRegion ? 'checked="checked"' : ''  #> value="true" onclick="showRegion(this, <#= item.InternalID #>);"/>
        <label class="<#= isDisabled ? 'disabled ' : '' #><#= item.RestrictRegistrationByRegion ? 'red' : '' #>" for="btnRestrictRegistrationByRegion_<#= item.InternalID #>">Restrict registration by Region</label>
        <br />
        <input <#= strDisabled #> name="Country_RestrictLoginByIP_<#= item.InternalID #>" type="checkbox" id="btnRestrictLoginByIP_<#= item.InternalID #>" <#= item.RestrictLoginByIP ? 'checked="checked"' : ''  #> value="true"/>
        <label class="<#= isDisabled ? 'disabled ' : '' #><#= item.RestrictLoginByIP ? 'red' : '' #>" for="btnRestrictLoginByIP_<#= item.InternalID #>">Restrict login by IP</label>
        <br />
        <input <#= strDisabled #> name="Country_RestrictCreditCardWithdrawal_<#= item.InternalID #>" type="checkbox" id="btnRestrictCCWithdrawal__<#= item.InternalID #>" <#= item.RestrictCreditCardWithdrawal ? 'checked="checked"' : ''  #> value="true"/>
        <label title="Restrict withdrawal to credit card which is issued in this country" class="<#= isDisabled ? 'disabled ' : '' #><#= item.RestrictCreditCardWithdrawal ? 'red' : '' #>" for="btnRestrictCCWithdrawal__<#= item.InternalID #>">Restrict CC Withdrawal</label>
        <%if (isSystemAdmin){%>
        <br />
        <input name="Country_AdminLock_<#= item.InternalID #>" type="checkbox" id="btnAdminLock_<#= item.InternalID #>" <#= item.AdminLock ? 'checked="checked"' : ''  #> value="true"/>
        <label <#= item.AdminLock ? 'style="color:red"' : ''  #> for="btnAdminLock_<#= item.InternalID #>">Admin lock</label>
        <%} %>
    </td>
</tr>
<#   }  #>
</script>
</div>

<div id="countryPersonalIdDetails"></div>

<script language="javascript" type="text/javascript">
function showRegion(source, InternalID) {
    if ($(source).attr('checked')) {
        $('#tableRestrictRegistrationByRegionCode_' + InternalID).removeClass('hidden');
    } else {
        $('#tableRestrictRegistrationByRegionCode_' + InternalID).removeClass('hidden').addClass('hidden');
    }
    
}

function TabCountry(viewEditor) {
    self.tabCountry = this;
    this.getCountriesAction = '<%= Url.RouteUrl( "RegionLanguage", new { @action = "GetCountries", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
    this.getPersionalDetailsAction = '<%= Url.RouteUrl( "RegionLanguage", new { @action = "PersonalIdDetails", @distinctName = this.Model.DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';

    this.refresh = function () {
        $('#table-country > tbody').html('');
        if (self.startLoad) self.startLoad();
        jQuery.getJSON(this.getCountriesAction, null, function (json) {
            if (self.stopLoad) self.stopLoad();
            if (!json.success) { alert(json.error); return; }
            $('#table-country > tbody').html($('#country-template').parseTemplate(json.data));

            self.tabCountry.bindEvent();
        });
    };

    this.save = function () {
        if (self.startLoad) self.startLoad();
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (self.stopLoad) self.stopLoad();
                if (!json.success) { alert(json.error); return; }
            }
        };
        $('#formCountry').ajaxForm(options);
        $('#formCountry').submit();
    };

    this.bindEvent = function () {
        $.each($("#table-country td.col-personal-id"), function (i, n) {
            var $n = $(n);
            var visibleCheckbox = $n.find("input[id^='btnIsPersonalIdVisible_']");

            visibleCheckbox.change(function () {
                var $this = $(this);
                if ($this.attr("checked") == true) {
                    $n.find(".table-content-details").fadeIn("normal", function () { $(this).removeClass("hidden"); });
                }
                else {
                    $n.find(".table-content-details").fadeOut("normal", function () { $(this).removeClass("hidden"); });
                }
            });

            $n.find("a[id^=btnPersonalIdMore_]").unbind("click").click(function () {
                var id = $(this).data("countryid") || $(this).attr("data-countryid");
                if (id > 0) {
                    $("#countryPersonalIdDetails").dialog({
                        height: 300,
                        width: 810,
                        draggable: false,
                        resizable: false,
                        modal: true,
                        close: function () {
                            $("#countryPersonalIdDetails").html("");
                        }
                    }).load(self.tabCountry.getPersionalDetailsAction + "/" + id);                   
                }
            });
        });
    };

    this.init = function () {
        $('#country-links a.refresh').bind('click', this, function (e) {
            e.data.refresh();
        });
        $('#country-links a.save').bind('click', this, function (e) {
            e.data.save();
        });

        $('#country-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });

        this.refresh();
    };

    this.init();
}
</script>
