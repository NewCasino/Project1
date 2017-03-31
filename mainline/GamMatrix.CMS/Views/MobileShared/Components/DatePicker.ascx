<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="System.Text" %>
<script runat="server" type="text/C#">    
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
    }

    private string GetDayNamesJson()
    {
        StringBuilder sbNames = new StringBuilder();
        StringBuilder sbShortNames = new StringBuilder();
        StringBuilder sbMinNames = new StringBuilder();

        sbNames.Append("{ dayNames: [");
        sbShortNames.Append("{ dayNamesShort: [");
        sbMinNames.Append("{ dayNamesMin: [");
        string[] paths = Metadata.GetChildrenPaths("/Metadata/Date/Day/");
        int _loop_index = 0;
        foreach (string path in paths)
        {
            _loop_index++;
            sbNames.Append(string.Format("'{0}'{1}", this.GetMetadata(path + ".Name").SafeHtmlEncode(), _loop_index < paths.Length ? ",":""));
            sbShortNames.Append(string.Format("'{0}'{1}", this.GetMetadata(path + ".ShortName").SafeHtmlEncode(), _loop_index < paths.Length ? "," : ""));
            sbMinNames.Append(string.Format("'{0}'{1}", this.GetMetadata(path + ".MinName").SafeHtmlEncode(), _loop_index < paths.Length ? "," : ""));
        }
        sbMinNames.Append("]}");
        sbShortNames.Append("]},");
        sbNames.Append("]},");

        return sbNames.Append(sbShortNames).Append(sbMinNames).ToString();        
    }

    private string GetMonthNamesJson()
    {
        StringBuilder sbNames = new StringBuilder();
        StringBuilder sbShortNames = new StringBuilder();        

        sbNames.Append("{ dayNames: [");
        sbShortNames.Append("{ dayNamesShort: [");        
        string[] paths = Metadata.GetChildrenPaths("/Metadata/Date/Month/");
        int _loop_index = 0;
        foreach (string path in paths)
        {
            _loop_index++;
            sbNames.Append(string.Format("'{0}'{1}", this.GetMetadata(path + ".Name").SafeHtmlEncode(), _loop_index < paths.Length ? "," : ""));
            sbShortNames.Append(string.Format("'{0}'{1}", this.GetMetadata(path + ".ShortName").SafeHtmlEncode(), _loop_index < paths.Length ? "," : ""));
        }
        sbShortNames.Append("]}");
        sbNames.Append("]},");

        return sbNames.Append(sbShortNames).ToString(); 
    }
</script>

<script type="text/javascript" src="//cdn.everymatrix.com/_js/jquery-ui-1.8.23.custom.datepicker.min.js"></script>
<script type="text/javascript">
    if ($("link[href*='jquery-ui-1.8.23.custom.css']").length == 0) {
        var el = document.createElement("link");
        el.setAttribute('rel', 'stylesheet');
        el.setAttribute('type', 'text/css');
        el.setAttribute('media', 'screen');
        el.setAttribute('href', self.location.protocol + '//cdn.everymatrix.com/images/datepicker/jquery-ui-1.8.23.custom.datepicker.css');
        document.getElementsByTagName('head')[0].appendChild(el);
    }


    $.fn.datepickerEx = function (_regional) {
        var regional = _regional||{};

        //day names
        $.extend(regional, <%=GetDayNamesJson() %>);

        //month names
        $.extend(regional, <%=GetMonthNamesJson() %>);        

        return $(this).datepicker(regional);
    }
</script>
