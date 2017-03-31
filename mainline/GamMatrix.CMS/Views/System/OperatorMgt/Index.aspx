<%@ Page Language="C#" MasterPageFile="~/Views/System/TopBar.master" Inherits="CM.Web.ViewPageEx<dynamic>"%>

<%@ Import Namespace="CM.db.Accessor" %>
<%@ Import Namespace="BLToolkit.Data" %>
<%@ Import Namespace="BLToolkit.DataAccess" %>
<script language="C#" runat="server" type="text/C#">
private SelectList GetOperators()
{
    SiteAccessor da = DataAccessor.CreateInstance<SiteAccessor>();

    var list = da.GetActiveDomains();

    return new SelectList(list, "Key", "Value");
}

private SelectList GetPasswordEncryptionModeList(int selectedValue)
{
    Dictionary<int, string> list = new Dictionary<int, string>();
    list.Add( 0, "MD5");
    list.Add( 1, "RC4(Jetbull Special)");
    list.Add( 2, "SHA1(IntraGame Special)");
    list.Add( 3, "SHA2_512");
    return new SelectList(list, "Key", "Value", selectedValue);
}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( "~/App_Themes/AdminConsole/OperatorMgt/Index.css") %>" />
    <link rel="stylesheet" type="text/css" href="<%= Url.Content("~/js/jquery/jquery.ui/redmond/jquery-ui-1.8.custom.css") %>" />
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">


<div class="creation-wrapper">
<div class="operator">
    <div class="head">
        <h3><span>Create a new site</span></h3>
    </div>

<% using( Html.BeginRouteForm( "OperatorMgt"
       , new { @action = "CreateSite" }
       , FormMethod.Post
       , new { @id="formCreateOperator"} ) )
       { %>
       <% Html.RenderPartial("../Warning"); %>
       <br /><br />

   <ui:InputField runat="server">
        <LabelPart>&#160;
        </LabelPart>
        <ControlPart>
            <table width="300px">
                <tr>
                    <td>
                    <%: Html.RadioButton("isNewOperator", true, new { @checked="checked", @id="btnIsNewOperator1"} ) %>
                    <label for="btnIsNewOperator1">This is a web site for new operator</label>
                    </td>
                </tr>
                <tr>
                    <td>
                    <%: Html.RadioButton("isNewOperator", false, new { @id = "btnIsNewOperator2" })%>
                    <label for="btnIsNewOperator2">This is a web site for exsiting operator</label>
                    </td>
                </tr>
            </table>
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Title:
        </LabelPart>
        <ControlPart>
            <%: Html.TextBox("title", "", new { @id = "txtTitle", @validator = ClientValidators.Create().Required("Please enter the title") })%>
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Distinct Name:
        </LabelPart>
        <ControlPart>
            <%: Html.TextBox("distinctName", "", new { @id = "txtDistinctName", @validator = ClientValidators.Create().Required("Please enter the distinct name.") })%>
        </ControlPart>
    </ui:InputField>



    <ui:InputField  ID="fldOperators" runat="server">
        <LabelPart>
        Operators:
        </LabelPart>
        <ControlPart>
            <%: Html.DropDownList("existingDomainID", GetOperators())%>
        </ControlPart>
    </ui:InputField>

    <ui:InputField  ID="fldApiUsername" runat="server">
        <LabelPart>
        API Username:
        </LabelPart>
        <ControlPart>
            <%: Html.TextBox("apiUsername", "_Api_Cms", new { @readonly="readonly", @id = "txtApiUsername", @validator = ClientValidators.Create().RequiredIf( "validateAsNewOperator", "Please enter the API Username.") })%>
        </ControlPart>
    </ui:InputField>

    <ui:InputField  ID="fldSecurityToken" runat="server">
        <LabelPart>
        Security Token:
        </LabelPart>
        <ControlPart>
            <%: Html.TextBox("securityToken", Guid.NewGuid().ToString("N").Truncate(15).ToUpper(), new { @id = "txtSecurityToken", @validator = ClientValidators.Create().RequiredIf( "validateAsNewOperator", "Please enter the security token.") })%>
        </ControlPart>
    </ui:InputField>

    <ui:InputField  ID="fldHostname" runat="server">
        <LabelPart>
        Host Name (for GmCore):
        </LabelPart>
        <ControlPart>
            <%: Html.TextBox("hostname", "", new { @id = "txtHostname", @validator = ClientValidators.Create().RequiredIf( "validateAsNewOperator", "Please enter the hostname.") })%>
        </ControlPart>
    </ui:InputField>
    
    <div class="buttons-wrap">
        <button type="button" id="btnCreateOperator">Create</button>
    </div>

    
<% } %> 

</div>
</div>



<div class="operator-wrapper">



</div>
<br /><br />

<script id="item-template" type="text/html">
<#
    var d=arguments[0];
    for(var i=0; i < d.length; i++)     
    {      
        var item = d[i]; 
#>
<div class="operator">
    <div class="head">
        <h3><span><#= item.DistinctName.htmlEncode() #></span></h3>
        <div class="links">
            <a href="<#= item.ChangeHistoryUrl #>" target="_blank">Change history...</a>&#160;&#160;&#160;
        </div>
    </div>
<% using( Html.BeginRouteForm( "OperatorMgt"
       , new { @action = "Save" }
       , FormMethod.Post ) )
       { %>
    <input type="hidden" name="id" value="<#= item.ID #>" />
    <ui:InputField runat="server">
        <LabelPart>
        API Username:
        </LabelPart>
        <ControlPart>
        <input type="text" readonly="readonly" value="<#= (item.ApiUsername || '').htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Security Token:
        </LabelPart>
        <ControlPart>
        <input type="text" readonly="readonly" value="<#= (item.SecurityToken || '').htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Pwd Encryption Mode:
        </LabelPart>
        <ControlPart>
            <select name="passwordEncryptionMode">
                <option value="0" <#= (item.PasswordEncryptionMode == 0) ? 'selected="selected"' : '' #> >MD5</option>
                <option value="1" <#= (item.PasswordEncryptionMode == 1) ? 'selected="selected"' : '' #> >RC4 (Jetbull Special)</option>
                <option value="2" <#= (item.PasswordEncryptionMode == 2) ? 'selected="selected"' : '' #> >SHA1 (IntraGame Special)</option>
                <option value="3" <#= (item.PasswordEncryptionMode == 3) ? 'selected="selected"' : '' #> >SHA2_512</option>
            </select>
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Template Site:
        </LabelPart>
        <ControlPart>
        <input type="text" name="templateDomainDistinctName" value="<#= item.TemplateDomainDistinctName.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Default Theme:
        </LabelPart>
        <ControlPart>
        <input type="text" name="defaultTheme" value="<#= item.DefaultTheme.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Default Culture:
        </LabelPart>
        <ControlPart>
        <input type="text" name="defaultCulture" value="<#= item.DefaultCulture.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Email Host:
        </LabelPart>
        <ControlPart>
        <input type="text" name="emailHost" value="<#= item.EmailHost.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Session Cookie Name:
        </LabelPart>
        <ControlPart>
        <input type="text" name="sessionCookieName" value="<#= item.SessionCookieName.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Session Cookie Domain:
        </LabelPart>
        <ControlPart>
        <input type="text" name="sessionCookieDomain" value="<#= item.SessionCookieDomain.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Session Timeout Seconds:
        </LabelPart>
        <ControlPart>
        <input type="text" name="sessionTimeoutSeconds" value="<#= item.SessionTimeoutSeconds #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        HTTP Port:
        </LabelPart>
        <ControlPart>
        <input type="text" name="httpPort" value="<#= item.HttpPort #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        HTTPS Port:
        </LabelPart>
        <ControlPart>
        <input type="text" name="httpsPort" value="<#= item.HttpsPort #>" />
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        Static File Server Domain:
        </LabelPart>
        <ControlPart>
        <input type="text" name="staticFileServerDomainName" value="<#= item.StaticFileServerDomainName.htmlEncode() #>" />
        </ControlPart>
    </ui:InputField>    

    <ui:InputField runat="server">
        <LabelPart>
        Current SessionID:
        </LabelPart>
        <ControlPart>
            <table border="0" cellpadding="0" cellspacing="0" style="border-collapse:collapse">
                <tr>
                    <td> <input type="text" name="sessionID" readonly="readonly" value="<#= item.SessionID.htmlEncode() #>" /> </td>
                    <td>
                        <img title="Renew the operator session id" src="/images/transparent.gif" class="btn-renew-session-id"/>
                    </td>
                </tr>
            </table>
        </ControlPart>
    </ui:InputField>

    <ui:InputField runat="server">
        <LabelPart>
        &nbsp;
        </LabelPart>
        <ControlPart>
            <div style="width:300px">
            <input type="radio" name="useRemoteStylesheet" value="True" id="btnUseRemoteStylesheet<#= item.ID #>"
            <#= item.UseRemoteStylesheet ? 'checked="checked"' : '' #> />
            <label for="btnUseRemoteStylesheet<#= item.ID #>">Use Remote Stylesheet</label>
            <br />
            <input type="radio" name="useRemoteStylesheet" value="False" id="btnUseLocalStylesheet<#= item.ID #>"
            <#= item.UseRemoteStylesheet ? '' : 'checked="checked"' #> />
            <label for="btnUseLocalStylesheet<#= item.ID #>">Use Local Stylesheet</label>
            </div>
        </ControlPart>
    </ui:InputField>
    
    <div class="buttons-wrap">
        <button type="button" class="btnSaveOperator">Save</button>
    </div>
<% } %> 
</div>
<#   }  #>
</script>

<script language="javascript" type="text/javascript">

    function validateAsNewOperator() {
        return $('input[name="isNewOperator"]:checked').val().toLowerCase() == "true";
    }

    function validateAsExistingOperator() {
        return $('input[name="isNewOperator"]:checked').val().toLowerCase() != "true";
    }

    function OperatorMgt() {
        this.getOperatorsAction = '<%= Url.RouteUrl( "OperatorMgt", new { @action="GetOperators" }).SafeJavascriptStringEncode()  %>';
        self.OperatorMgt = this;

        this.onBtnSaveClicked = function (btn) {
            var form = btn.parents('form');
            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) {
                    if (json.success)
                        alert('The operation has been completed successfully!');
                    else
                        alert(json.error);
                }

            };
            form.ajaxForm(options);
            form.submit();
        };



        this.refresh = function () {
            $('div.operator-wrapper').html('');
            jQuery.getJSON(this.getOperatorsAction, null, function (data) {
                if (!data.success) alert(data.error);
                else {
                    var $html = $('#item-template').parseTemplate(data.operators);
                    $('div.operator-wrapper').html($html);

                    var forms = $('div.operator-wrapper > div.operator > form');
                    for (var i = 0; i < forms.length; i++) {
                        InputFields.initialize($(forms[i]));
                    }

                    $('button.btnSaveOperator').button().bind('click', this, function (e) {
                        e.preventDefault();
                        self.OperatorMgt.onBtnSaveClicked($(this));
                    });

                    console.log($('div.operator > div.head > div.links > a').length);
                    $('div.operator > div.head > div.links > a').click(function (e) {
                        var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
                        if (wnd) e.preventDefault();
                    });
                }
            });
        };

        this.onBtnCreateClicked = function () {
            if ($("#formCreateOperator").valid()) {
                if (self.startLoad) self.startLoad();
                var options = {
                    type: 'POST',
                    dataType: 'json',
                    success: function (json) {
                        if (self.stopLoad) self.stopLoad();
                        if (!json.success) { alert(json.error); return; }
                        alert('The operation has been completed successfully!');
                        self.OperatorMgt.refresh();
                        $('#formCreateOperator').get(0).reset();
                    }
                };
                $('#formCreateOperator').ajaxForm(options);
                $('#formCreateOperator').submit();
            }
        };

        InputFields.initialize($('#formCreateOperator'));
        $('input[name="isNewOperator"]').bind('click', this, function (e) {
            var isNewOperator = $('input[name="isNewOperator"]:checked').val().toLowerCase() == "true";
            $('#fldOperators').css("display", isNewOperator ? 'none' : '');
            $('#fldApiUsername').css("display", !isNewOperator ? 'none' : '');
            $('#fldSecurityToken').css("display", !isNewOperator ? 'none' : '');
            $('#fldHostname').css("display", !isNewOperator ? 'none' : '');
        });
        $('input[name="isNewOperator"][checked]').trigger('click');


        $('#btnCreateOperator').button().bind('click', this, function (e) {
            e.preventDefault();
            e.data.onBtnCreateClicked();
        });
        $('#formCreateOperator span.text').html("To grant access in GmCore, the following SQL need be executed:<br/><pre>          INSERT INTO GmCore..GmIPUserRule(Type, UserID, IPRange, isNoPasswordLoginAllowed)<br/>          VALUES(1, <em>UserID</em>, '<em>ip1,ip2,...</em>', 1)</pre>");

        this.refresh();   
    };
    $(document).ready(function () { new OperatorMgt(); });
</script>
</asp:Content>

