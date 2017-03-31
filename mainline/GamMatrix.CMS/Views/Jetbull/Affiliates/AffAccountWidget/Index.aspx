<%@ Page Language="C#" PageTemplate="/RootMaster.master" Inherits="CM.Web.ViewPageEx"
    Title="<%$ Metadata:value(.Title)%>" MetaKeywords="<%$ Metadata:value(.Keywords)%>"
    MetaDescription="<%$ Metadata:value(.Description)%>" %>

<asp:content contentplaceholderid="cphHead" runat="Server">
</asp:content>
<asp:content contentplaceholderid="cphMain" runat="Server">


<div class="affiliate">
    <form id="affiliateForm" name="affiliateForm" action="<%=this.GetMetadata("/Metadata/Affiliate.formActionPath")%>" target="_top">
        <div id="login-box">
            <%: Html.LinkButton(this.GetMetadata("/Metadata/Affiliate.form_Link_SignUp_Text"), new { @class = "join_now", @href = this.GetMetadata("/Metadata/Affiliate.form_Link_SignUp_Url").SafeHtmlEncode(), @target = "_top" })%>
            <%: Html.LinkButton(this.GetMetadata("/Metadata/Affiliate.form_Link_forgotPass_Text"), new { @class = "forgot_password", @href = this.GetMetadata("/Metadata/Affiliate.form_Link_forgotPass_Url").SafeHtmlEncode(), @target = "_top" })%>
            <div id="login-pane">
                <!--<div class="username_wrap">
                    <%: Html.TextboxEx("username", "", this.GetMetadata("/Head/LoginPane.Username_Wartermark"), new { placeholder = this.GetMetadata("/Head/LoginPane.Username_Wartermark") })%>
                </div>
                <div class="password_wrap">
                    <%: Html.TextboxEx("password", "", this.GetMetadata("/Head/LoginPane.Password_Wartermark"), new { type = "password", placeholder = this.GetMetadata("/Head/LoginPane.Password_Wartermark") })%>
                </div>-->
                <div class="login_btn">
                    <%: Html.Button(this.GetMetadata("/Metadata/Affiliate.form_Button_Sumbit_Text"), new { @type = "submit" })%>
                </div>
                <div style="clear:both"></div>
            </div>
        </div>
    </form>
</div>

<script type="text/javascript">
    function aff_loginpost() {
        var uname = $("#username").val();
        var pwd = $("#password").val();
        if (uname == "" || pwd == "") {
            alert("Your username or password do not match");
        }
        else {
            $('#txtUsername').val(uname);
            $('#txtPassword').val(pwd);
            $("#affiliateForm").submit();
        }
    }

    $(function () {
        $("#affiliateForm").bind("keypress", function (e) {
            var e = e || window.event;
            var keyCode = e.keyCode;
            if (keyCode == 13) {
                aff_loginpost();
            }
        });
    });  
</script>
</asp:content>
