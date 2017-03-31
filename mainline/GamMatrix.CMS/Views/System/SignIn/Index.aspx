<%@ Page Language="C#" AutoEventWireup="true" Inherits="CM.Web.ViewPageEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="GmCore" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head runat="server">
    <title>CMS Console SignIn</title>
    <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon" />
    <link rel="icon" href="/favicon.ico" type="image/x-icon" />
    <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
    <link rel="stylesheet" type="text/css" href="<%= Url.Content( string.Format("~/App_Themes/{0}/SignIn/Index.css", this.PageTheme) ) %>" />
    <script language="javascript" type="text/javascript" src="/js/jquery/jquery-1.5.2.min.js"></script>
    <script language="javascript" type="text/javascript" src="/js/jquery/jquery.form.js"></script>
</head>
<body>


<%     
    string roleString = string.Empty;
    
    

    
    try
    {
        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GamMatrixClient.GetSessionID(SiteManager.Current, true);
        }
    }
    catch (Exception ex)
    {
        roleString = ex.Message + ex.Source + ex.StackTrace;
        throw ex;
    }
%>
<div style="display:none"><%=roleString %> </div>

<% using (Html.BeginForm("Login", null, null, FormMethod.Post, new { @id = "formSignIn" }))
   { %>
<div id="dlg">
    <div class="info">For the best experience, we strongly recommend to use Google Chrome Web Browser.</div>
	<div class="controls">
    	<table cellpadding="0" cellspacing="5" border="0" id="table-login">
        	<tr>
            	<td align="right" class="col1">Username:</td>
                <td><%: Html.TextBox("username", "", new { @onfocus = "this.select()", id = "txtUsername", autocomplete = "off" })%></td>
            </tr>
            <tr>
            	<td align="right">Password:</td>
                <td><%: Html.Password("password", "", new { @onfocus = "this.select()", id = "txtPassword", autocomplete = "off" })%></td>
            </tr>
            <tr>
            	<td align="right">Security Token:</td>
                <td><%: Html.TextBox("securityToken", "", new { @onfocus = "this.select()", id = "txtSecurityToken", autocomplete = "off" })%></td>
            </tr>
            <tr>
                <td>&nbsp;</td>
                <td align="right">
                    <span class="msg"></span>
                    <br /><br />
                    <input type="image" onfocus="this.blur()" src="/images/transparent.gif" id="btnSignIn" />
                </td>
            </tr>
        </table>
    </div>
</div>
    <% } %>
<script language="javascript" type="text/javascript">
    SignIn = {
        redirectUrl: '<%= string.Format( "{0}#{1}", Url.RouteUrl("ContentMgt"), Request.QueryString["returnUrl"]).SafeJavascriptStringEncode() %>',

        onBtnLoginClick: function () {
            $('span.msg').html('<img id="icoLoading" src="/images/icon/loading.gif" />');
            $('#btnSignIn').attr('disabled', 'disabled');

            var options = {
                type: 'POST',
                dataType: 'json',
                success: function (json) { SignIn.onResponse(json); }
            };
            $('#formSignIn').ajaxForm(options);
            $('#formSignIn').submit();
        },

        onResponse: function (json) {
            $('#btnSignIn').attr('disabled', null);

            if (json.success) {
                switch (json.result) {
                    case 'NoMatch':
                        $('span.msg').text('Login failed! Invalid credential.');
                        break;
                    case 'EmailNotVerified':
                        $('span.msg').text('Login failed! Email address is not verified.');
                        break;
                    case 'Blocked':
                        $('span.msg').text('Login failed! Blocked.');
                        break;
                    case 'Success':
                        {
                            setTimeout(function () {
                                top.location.replace(SignIn.redirectUrl);
                            }, 1000);
                            break;
                        }
                    default:
                        break;
                }
            }
            else {
                $('span.msg').text(json.error);
            }
        },

        init: function () {
            $('#btnSignIn').attr('disabled', null);
            $('#btnSignIn').bind('click', this, function (e) { e.preventDefault(); SignIn.onBtnLoginClick(); });
            (new Image()).src = "/images/icon/loading.gif";

            $.browser.chrome = /chrome/.test(navigator.userAgent.toLowerCase());
            if ($.browser.chrome) {
                $('#dlg div.info').hide();
            }
            try{localStorage.clear();}catch(err){}
            
        }
    };

$(document).ready(SignIn.init);
</script>

</body>
</html>
