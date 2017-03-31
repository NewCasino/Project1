<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<script runat="server">
    private string SearchEmptyText
    {
        get
        {
            if (ViewData["SearchEmptyText"] != null)
                return ViewData["SearchEmptyText"] as string;

            return this.GetMetadata(".Empty_Text").DefaultIfNullOrEmpty("Search");
        }
    }
    private string SearchKey
    {
        get
        {
            if (ViewData["SearchKey"] == null)
                return string.Empty;
            return ViewData["SearchKey"] as string;
        }
    }
</script>
<div class="search-box">
    <form action="/Faq/Search" method="GET" id="searchForm" autocomplete="off">
        <input id="txtKeyWord" type="text" name="query" title="search-query" class="search-query" placeholder="<%=SearchEmptyText %>" value="<%=SearchKey %>">

        <%: Html.Button(this.GetMetadata(".Search_Text"), new {@id="btnSearch" ,@onclick="this.blur();"}) %>
    </form>
</div>
<script type="text/javascript">
    $(function () {
        var input = $("#txtKeyWord"),
            btn = $("#btnSearch");
        function toSearch() {
            if (input.val() != '') {
                window.location = "/Faq/Search/" + encodeURIComponent(input.val());
            }
        }

        btn.bind("click", function (e) {
            toSearch();
            return false;
        });

        input.keypress(function (e) {
            if (e.which == 13) {
                toSearch();
            }
        });
    });
</script>
