<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server" >
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        
        ReplaceDirectory = new Dictionary<string, string>();
        ReplaceDirectory["USERID"] = Profile.UserID.ToString();
        ReplaceDirectory["USERNAME"] = Profile.UserName;
    }

    private Dictionary<string, string> ReplaceDirectory { get; set; }
    
    private string ContentHtml {
        get {
            string contentHtml = this.GetMetadata(".ContentHtml");

            foreach (KeyValuePair<string, string> item in this.ReplaceDirectory)
            {
                contentHtml = contentHtml.Replace(string.Format("${0}$", item.Key), item.Value);
            }

            return contentHtml;
        }
    }

    private string InviteUrl {
        get {
            string inviteUrl = this.GetMetadata(".InviteUrl");

            foreach (KeyValuePair<string, string> item in this.ReplaceDirectory)
            {
                inviteUrl = inviteUrl.Replace(string.Format("${0}$", item.Key), item.Value);
            }

            return inviteUrl;
        }
    }
</script>


<p>
<%= ContentHtml.HtmlEncodeSpecialCharactors() %>
</p>
<p>
<input type="text" class="textbox" id="tbInviteUrl" value="<%=InviteUrl.HtmlEncodeSpecialCharactors() %>" />
<%: Html.Button(this.GetMetadata(".Button_Copy"), new{ @id="btnCopy" }) %>

</p>
<script type="text/javascript" src="//cdn.everymatrix.com/_js/jquery.zclip.min.js"></script>
<script type="text/javascript">
    $(function () {
        $("#tbInviteUrl").bind("focus", function () {
            this.select();
        });

        $("#btnCopy").zclip({
            copy: function () { return $("#tbInviteUrl").val(); }
        });
    });
</script>