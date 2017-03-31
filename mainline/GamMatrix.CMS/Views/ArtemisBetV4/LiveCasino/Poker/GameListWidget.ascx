<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="Box AllTables">
    <div class="TablesContainer">
    <ol class="TablesList Container AllGames">
    <%
    string text, image, href;
    string[] paths = Metadata.GetChildrenPaths("/Metadata/LiveCasino/PokerGames");
    for (int i = 0; i < paths.Length; i++) 
    {
    text = Metadata.Get(string.Format("{0}.Text", paths[i])).DefaultIfNullOrEmpty("");
    image = Metadata.Get(string.Format("{0}.Image", paths[i])).DefaultIfNullOrEmpty("");
    href = Metadata.Get(string.Format("{0}.Href", paths[i])).DefaultIfNullOrEmpty("#");
%>
    <li class="GLItem">
                    <div class="GameThumb" style=" background-image: url('<%=image.HtmlEncodeSpecialCharactors() %>')" title="<%=text.SafeHtmlEncode() %>">
                        <a class="Button CTAButton PlayNowButton" href="<%=href.SafeJavascriptStringEncode() %>" title="<%=text.SafeHtmlEncode() %>">
                            <span class="ButtonText"><%=this.GetMetadata(".Button_Text").SafeHtmlEncode() %><span class="ActionSymbol">►</span></span>     
                        </a>
                    </div>
                    <h3 class="GameTitle">
                        <a href="<%=href.SafeJavascriptStringEncode() %>" class="Game" title="<%=text.SafeHtmlEncode() %>"><%=text.SafeHtmlEncode() %></a>
                    </h3>
                    <span class="GTStatus">
                        <span class="GTStatusIcon"></span> 
                        <span class="OptionSpecial"><%=this.GetMetadata(".OptionSpecial").SafeHtmlEncode() %></span>
                    </span>
                </li>
    
<% }
    %>
    </ol>
    </div>
</div>