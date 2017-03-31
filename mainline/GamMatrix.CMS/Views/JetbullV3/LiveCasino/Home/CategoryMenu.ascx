<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>

<script runat="server" type="text/C#">

    private string _MetaPath = "/MetaData/LiveCasino/GameCategory";
    public string MetaPath
    {
        get { return _MetaPath; }
        set { _MetaPath = value; }
    }
    
    protected override void OnInit(EventArgs e)
    {
        if (ViewData["CategoryMetaPath"] != null && !string.IsNullOrEmpty(ViewData["CategoryMetaPath"].ToString()))
        {
            MetaPath = ViewData["CategoryMetaPath"].ToString();
        }
        base.OnInit(e);
    }
</script>

<h2 class="GLTitle">Table Games</h2>
<ul class="List XproCategory">
<%
    if (!string.IsNullOrEmpty(MetaPath))
    {
        int _category_loop_index = 0;
        foreach (string path in Metadata.GetChildrenPaths(MetaPath))
        {
            _category_loop_index++;
            string s = _category_loop_index%2 == 0 ? "Even" : "Odd";
            
            %>
            <%= string.Format(@"<li class=""Item {0}"">
								<a onclick=""SwitchXproCategory('{1}')"" data-type=""{1}"" title=""{2}"" class=""ListLink"" href=""{3}"">
									<span>{4}</span>
								</a>
							</li>"
                                                , _category_loop_index%2 == 0 ? "Even" : "Odd" 
                ,this.GetMetadata(path+".Value").DefaultIfNullOrEmpty("all").SafeHtmlEncode()
                ,this.GetMetadata(path+".Title").DefaultIfNullOrEmpty(string.Empty).SafeHtmlEncode()
                ,this.GetMetadata(path+".Url").DefaultIfNullOrEmpty("javascript:void(0)")
                ,this.GetMetadata(path+".Text").DefaultIfNullOrEmpty("Untitled").SafeHtmlEncode())%>
            <%
        }
    }
     %>
</ul>
     <script type="text/javascript">

        function SwitchXproCategory(gameType) {            
            if (!gameType) gameType = "all";
            $("ul.XproCategory").find(".Active").removeClass("Active");
            var _cur_category_holder = $("ul.XproCategory").find("a[data-type='" + gameType + "']");
            _cur_category_holder.parent().addClass("Active");

            if (gameType == "all")
                $(".live_casino_game").show();
            else {
                $(".live_casino_game").hide();
                $("div[type='" + gameType + "']").show();
            }            
            $("#Xpro_LobbyTitle").html(_cur_category_holder.find("span").html());
        }

        SwitchXproCategory("all");
     </script>
