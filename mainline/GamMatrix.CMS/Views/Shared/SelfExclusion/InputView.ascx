<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="System.Globalization" %>

<% using (Html.BeginRouteForm("SelfExclusion", new { @action = "Apply" }, FormMethod.Post, new { @id = "formSelfExclusion" }))
   {  %>

<div id="self-exclusion">
<p><%= this.GetMetadata(".Options_To_Choose").HtmlEncodeSpecialCharactors()%></p>
<table cellpadding="0" cellspacing="0" border="0">

<% 
    SelfExclusionPeriod[] ukLicensePeriods = new SelfExclusionPeriod[]
    {
        SelfExclusionPeriod.SelfExclusionFor6Months,
        SelfExclusionPeriod.SelfExclusionFor1Year
    };
    Type enumType =  typeof(SelfExclusionPeriod);
    SelfExclusionPeriod rgSelfExclusionPeriod;
    int _loop_index = 0;
    foreach(string enumName in Enum.GetNames(enumType))
    {
        if (Settings.IsUKLicense
            && !ukLicensePeriods.Contains((SelfExclusionPeriod)Enum.Parse(typeof(SelfExclusionPeriod), enumName)))
            continue;
        rgSelfExclusionPeriod = (SelfExclusionPeriod)Enum.Parse(enumType, enumName);
        string desc = this.GetMetadata( string.Format( CultureInfo.InvariantCulture, ".{0}Option", enumName));
        if (string.IsNullOrWhiteSpace(desc) || enumName == "Permanent" )
            continue;
        %>
        <tr class="<%=enumName %>">
            <td>
                <input type="radio" name="selfExclusionOption" value="<%=enumName %>" id="option<%=enumName %>" />
            </td>
            <td>
                <label for="option<%=enumName %>"><strong><%= desc.SafeHtmlEncode()%></strong></label>
            </td>
        </tr>
        <%
    }
%>
</table>
<p><%= this.GetMetadata(".Options_To_Choose_Supplement").HtmlEncodeSpecialCharactors()%></p>
<br />
<p id="msgWarning">
<%= this.GetMetadata(".PermanentExclusionInfo").HtmlEncodeSpecialCharactors() %>
</p>

<div id="divPermanentOption" style="display:none">
    <p><%= this.GetMetadata(".Options_To_Choose_Permanent").HtmlEncodeSpecialCharactors()%></p>
    <table cellpadding="0" cellspacing="0" border="0">
        <tr>
            <td>
                <input type="radio" name="selfExclusionOption" value="<%=SelfExclusionPeriod.SelfExclusionPermanent.ToString() %>" id="option<%=SelfExclusionPeriod.SelfExclusionPermanent.ToString() %>" />
            </td>
            <td>
                <label for="option<%=SelfExclusionPeriod.SelfExclusionPermanent.ToString() %>"><strong><%= this.GetMetadata("." + SelfExclusionPeriod.SelfExclusionPermanent.ToString() + "Option").SafeHtmlEncode()%></strong>
            </td>
        </tr>
    </table>
</div>


<br />
<center>
    <%: Html.Button(this.GetMetadata(".Button_Submit"), new { @id = "btnApplySelfExclusion" })%>
</center>
</div>
<% } %> 
<script type="text/javascript">
    var Warning_MSG = "";
    var getNewDateMSG = function (){
        var Warning_MSG_Permanent = '<%= this.GetMetadata(".Confirmation_Message_Permanent").SafeJavascriptStringEncode() %>';
        var Warning_MSG_General = '<%= this.GetMetadata(".Confirmation_Message").SafeJavascriptStringEncode() %>';
        var Option_Str = "";
        var NowDate = new Date();
        var NewDate = "";
        var Options =  document.getElementsByName('selfExclusionOption');
        for(var i= 0; i< Options.length ; i ++){
            if(Options.item(i).checked){
                Option_Str = Options.item(i).value;
            }
        } 
        if (Option_Str == "Permanent") {
            Warning_MSG = Warning_MSG_Permanent;
            return;
        } 
        switch(Option_Str){
            case "SevenDays":
                NewDate_Str = NowDate.dateAdd('d',7);
            break;
            case "ThirtyDays":
                NewDate_Str = NowDate.dateAdd('d',30);
            break;
            case "ThreeMonths":
                NewDate_Str = NowDate.dateAdd('d',90);
            break;
            case "SixMonths":
                NewDate_Str = NowDate.dateAdd('d',180);
            break;
            case "OneYear":
                NewDate_Str = NowDate.dateAdd('d',365);
            break;
            default: 
        } 
        Warning_MSG = Warning_MSG_General.format(NewDate_Str.toLocaleDateString());
    };
   
  
    $(document).ready(function () {
        $('#self-exclusion :radio:visible:first').attr('checked', true);
        setInterval(function () {
            if (!$('#msgWarning').is(':visible'))
                $('#divPermanentOption').show();
        }, 1000);
        $('#btnApplySelfExclusion').click(function (e) {
            e.preventDefault();
            getNewDateMSG();
            if (window.confirm(Warning_MSG) != true) return;
            $(this).toggleLoadingSpin(true);
            var options = {
                dataType: "html",
                type: 'POST',
                success: function (html) {
                    $('#btnApplySelfExclusion').toggleLoadingSpin(false);
                    $('#formSelfExclusion').parent().html(html);
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
    Date.prototype.dateAdd = function(interval,number)
    {
        var d = this;
        var k={'y':'FullYear','q':'Month','m':'Month','w':'Date','d':'Date','h':'Hours','n':'Minutes','s':'Seconds','ms':'MilliSeconds'};
        var n={'q':3,'w':7};
        eval('d.set'+k[interval]+'(d.get'+k[interval]+'()+'+((n[interval]||1)*number)+')');
        return d;
    }
    String.prototype.format = function(args) {
        var result = this;
        if (arguments.length > 0) {    
            if (arguments.length == 1 && typeof (args) == "object") {
                for (var key in args) {
                    if(args[key]!=undefined){
                        var reg = new RegExp("({" + key + "})", "g");
                        result = result.replace(reg, args[key]);
                    }
                }
            }
            else {
                for (var i = 0; i < arguments.length; i++) {
                    if (arguments[i] != undefined) {
                        var reg = new RegExp("({[" + i + "]})", "g");
                        result = result.replace(reg, arguments[i]);
                    }
                }
            }
        }
        return result;
    }
</script>