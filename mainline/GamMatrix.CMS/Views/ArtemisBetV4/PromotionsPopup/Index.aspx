<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>
<script runat="server" type="text/C#">
    private string[] proPaths { get; set; }
</script>
<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>


<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
<div class="popup_pro_content">
<div id="popup_PromotionList">
    <% 
        this.proPaths = Metadata.GetChildrenPaths("/Metadata/Promotion_Popup").ToArray();
        for (int i = 0; i < proPaths.Length; i++)
        {
            string Text = Metadata.Get(string.Format("{0}.Text", proPaths[i])).DefaultIfNullOrEmpty(" ");
            string Url = Metadata.Get(string.Format("{0}.Url", proPaths[i])).DefaultIfNullOrEmpty(" ");
            string PositionStyle = Metadata.Get(string.Format("{0}.PositionStyle", proPaths[i])).DefaultIfNullOrEmpty(" ");
            string ButtonStyle = Metadata.Get(string.Format("{0}.ButtonStyle", proPaths[i])).DefaultIfNullOrEmpty(" ");
            string ContentStyle = Metadata.Get(string.Format("{0}.ContentStyle", proPaths[i])).DefaultIfNullOrEmpty(" ");
            string  ButtonType = Metadata.Get(string.Format("{0}.ButtonType", proPaths[i])).DefaultIfNullOrEmpty(" ");
            %>
        <div class="popup-promotion-item" style="<%= PositionStyle.HtmlEncodeSpecialCharactors()%>">
<button class="button whitebutton"  style="<%= ButtonStyle.HtmlEncodeSpecialCharactors()%>" onclick="this.blur();window.parent.location.href = '<%=Url.HtmlEncodeSpecialCharactors()%>';">

            <div class="inlineblock white <%= ButtonType.HtmlEncodeSpecialCharactors()%>" style="<%= ContentStyle.HtmlEncodeSpecialCharactors()%>"><%=Text.HtmlEncodeSpecialCharactors()%><div>
        </button>
        </div>
        <%
        }
    %>
</div>

<div id="bottom_popup_Promotion">
<%= this.GetMetadata(".donotshow").HtmlEncodeSpecialCharactors() %>
<input id="ifHide_popup_Promotion" name="acceptTermsConditions" type="checkbox" value="true" />
</div>
<div class="bodycentercontent"><%= this.GetMetadata(".bodycentercontent").HtmlEncodeSpecialCharactors() %><div>
</div>
<script type="text/javascript">
        <%
            var backgroundImage = Metadata.Get("/Metadata/Promotion_Popup.BackgroundImage").DefaultIfNullOrEmpty(string.Empty);
            if (!String.IsNullOrEmpty(backgroundImage))
            {
        %>
            $('body').css('background-image', 'url(<%=backgroundImage%>)');
        <% } %>

    $(function () {
        if($.cookie("dontshow_popup_promotion") != "1"){
        $("#ifHide_popup_Promotion").change(function() { 
            if($("#ifHide_popup_Promotion").is(':checked') == true){
                $.cookie("dontshow_popup_promotion", "1",{expires:9999,path: '/'});  
            } 
            else{
                $.cookie("dontshow_popup_promotion", "0",{expires:9999,path: '/'});  
            }
        }); 
        }
    });  
</script>
</asp:Content>

