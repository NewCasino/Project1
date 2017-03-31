<%@ Page Language="C#" PageTemplate="/DefaultMaster.master" Inherits="CM.Web.ViewPageEx" Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>" MetaDescription="<%$ Metadata:value(.Description)%>" %>
<%@ Import Namespace="GamMatrix.CMS.Models.Common.Components.ProfileInput" %>
<%@ Import Namespace="GamMatrix.CMS.Models.MobileShared.Components" %>
<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">   
    <div class="Box CenterBox">
        <div class="BoxContent"> 
            <% Html.RenderPartial("/Components/RegisterV2Form", new RegisterV2FormViewModel()); %>
        </div>
    </div>
    <%--<script type="text/javascript">
        $(CMS.mobile360.Generic.input);
        $(function () {
            $('#8_fldUsername').before($('#4_fldEmail'));
            $("#8_fldLanguage").hide();
            $("#registerEmail").change(function (e) {
                $("#registerUsername").val($("#registerEmail").val()).change();
            });

        });
    </script>--%>
</asp:content>

