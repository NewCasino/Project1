<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script language="C#" type="text/C#" runat="server">
    private string GetFormUrl()
    {
        try
        {
            Match m = Regex.Match(this.ViewData["FormHtml"] as string, @"\baction(\s*)\=(\s*)(?<quot>(\""|\'))(?<action>.+?)(\k<quot>)", RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
            if (m.Success)
                return m.Groups["action"].Value;
        }
        catch
        {
        }
        return string.Empty;
    }

    private string GetMethod()
    {
        try
        {
            Match m = Regex.Match(this.ViewData["FormHtml"] as string, @"\bmethod(\s*)\=(\s*)(?<quot>(\""|\'))(?<method>.+?)(\k<quot>)", RegexOptions.Multiline | RegexOptions.Compiled | RegexOptions.ECMAScript | RegexOptions.IgnoreCase | RegexOptions.CultureInvariant);
            if (m.Success)
                return m.Groups["method"].Value;
        }
        catch
        {
        }
        return "post";
    }
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">

    <style type="text/css">
    html, body { width:100%; height:100%; padding:0px; margin:0px; overflow:hidden; background-color:#EFEFEF; }
    #content { position: absolute; top:50%; height:120px; margin-top:-60px; width:100%; font-family:Verdana; }
</style>


</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">

    
<div id="content">    
    <center>
        <img alt="" src="/images/ajax-loader.gif" border="0" />
        <br />
        <h4 style="color:black"><%= this.GetMetadata(".Message").HtmlEncodeSpecialCharactors()  %></h4>
    </center>
</div>

<%= this.ViewData["FormHtml"] as string %>

<script type="text/javascript">
    //<![CDATA[
    window.onload = function () {
        setTimeout(function () {
            var forms = document.getElementsByTagName("form");
            if (forms.length == 0) {
                alert('No form found!');
                return;
            }
            var form = forms[0];
            var url = '<%= GetFormUrl().SafeJavascriptStringEncode() %>';
            form.setAttribute('method', '<%= GetMethod().SafeJavascriptStringEncode() %>');
            form.setAttribute('action', url);
            form.setAttribute('enctype', 'application/x-www-form-urlencoded');
            form.submit();
        }, 1000);
    };
    //]]>
</script>


</asp:Content>

