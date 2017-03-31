<%@ Page Language="C#" PageTemplate="/InfoMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>"%>

<script runat="server">
private string Category {
    get {
        return this.ViewData["Category"] as string ?? string.Empty;
    }
}

private string SubCategory {
    get {
        return this.ViewData["SubCategory"] as string ?? string.Empty;
    }
}

private string GetContentMetaPath() {
    return string.Format("/Metadata/Promotions/{0}{1}",
        Category,
        string.IsNullOrEmpty(SubCategory) ? "" : "/" + SubCategory
    );
}

private string GetContentTitle() {
    return this.GetMetadata(string.Format("{0}{1}", GetContentMetaPath(), ".Title"));
}

private string GetContentHtml() {
    return this.GetMetadata(string.Format("{0}{1}", GetContentMetaPath(), ".TermsAndConditionsHTML"));
}

protected override void OnInit(EventArgs e) {
    string pageTitle = this.GetMetadata(".Title");
    if (!string.IsNullOrEmpty(PageTemplate)) {
        Page.Title = pageTitle.Replace("$PROMOTION-TITLE$", GetContentTitle());
    }
    base.OnInit(e);
}
</script>

<asp:Content ContentPlaceHolderID="cphHead" Runat="Server">
</asp:Content>

<asp:Content ContentPlaceHolderID="cphMain" Runat="Server">
    <h1 class="PageTitle PromoTitle"><%= GetContentTitle().SafeHtmlEncode()%></h1>
    <%= GetContentHtml().HtmlEncodeSpecialCharactors()%>
</asp:Content>