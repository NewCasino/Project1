<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx<dynamic>" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>


<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server"><div id="livesupport"><%= this.GetMetadata(".MainImg") %></div>
<ui:MinifiedJavascriptControl runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript"> 
    var chatcount = 0;
    var chatTitles = [];
    var chatClass = [];

    $.each($("#livesupport"), function (i, n) {
        chatTitles.push($(n).html());
        chatClass.push($(n).attr("class"));
        $(n).replaceWith('<div id="lpButDivID-1312275796568-' + i + '" class="livesupport-box"></div>');
        chatcount += 1;
    });

    for (x = 0; x < chatcount; x++) {
        try {
            var lc = document.createElement('script');
            lc.type = 'text/javascript';
            lc.async = true;
            lc.src = 'https://server.iad.liveperson.net/hc/59999637/?cmd=mTagRepstate&site=59999637&buttonID=7&divID=lpButDivID-1312275796568-' + x + '&bt=3&c=1';
            var s = document.getElementById('lpButDivID-1312275796568-' + x);
            s.parentNode.appendChild(lc);
        }
        catch (ex) { }
    }

    var reSetTextTriedNum = 0;
    reSetText();
    function reSetText() {
        var alldone = true;
        for (x = 0; x < chatcount; x++) {
            try {
                var chatContainer = $("#lpButDivID-1312275796568-" + x);
                var chatTextContainer = null;
                if (chatContainer.find("span").find("a").length > 0) {
                    chatTextContainer = chatContainer.find("span").find("a");
                }
                else if (chatContainer.find("a").length > 0) {
                    chatTextContainer = chatContainer.find("a");
                }
                if (chatTextContainer != null) {
                    chatTextContainer.find("span.lpChatTextLinkText").html(chatTitles[x]);
                    chatTextContainer.toggleClass(chatClass[x]);
                }
                else {
                    alldone = false;
                }
            }
            catch (ex) { }
        }

        if (!alldone && reSetTextTriedNum < 20) {
            reSetTextTriedNum++;
            setTimeout(reSetText, 1000);
        }
    }
</script>
</ui:MinifiedJavascriptControl>
</asp:Content>

