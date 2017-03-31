<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>


    <% 
    string isActive = String.Empty;
    if (Profile.IsAuthenticated) {
        isActive = " signin";
    }%>
<div class="toolbar<%=isActive%>">
    <div class="news_content">
        <div class="toolbar_signup">
        <%if (String.IsNullOrEmpty(isActive))
            { %>
                
                    <%=this.GetMetadata(".Signup_Html").HtmlEncodeSpecialCharactors()%>
            <%}
            else
            { %>
            
                <%=this.GetMetadata(".News_Html").HtmlEncodeSpecialCharactors()%>
            
        <%} %>
        </div>
    </div>
    <div class="toolbar_Pane">
        <div class="toolbar_details">
            <div style="width:100%;height:200px;"></div>
        </div>
        <button class="toolbar_button"></button>
        <%--<button onclick="$('.toolbar_details').slideToggle('slow');" class="toolbar_button"></button>--%>
    </div>
</div>