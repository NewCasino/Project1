<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script language="C#" runat="server" type="text/C#"> 
    private string TermsConditionsChange { get { return this.ViewData["PopupType"] as string; } }
    protected override void OnPreRender(EventArgs e)
    {
        if (Profile.IsAuthenticated)
        {
            switch (TermsConditionsChange)
            {
                case "MustAcceptTCWithMajorChange":
                    MustAcceptTCWithMajorChange.Visible = true;
                    break;
                case "MustAcceptTC":
                    MustAcceptTC.Visible = true;
                    break;
                case "MinorChange":
                    MinorChange.Visible = true;
                    break;
                default:
                    TCPopUpNo.Visible = true;
                    break;
            }
        }
        base.OnPreRender(e);
    }
</script>
<style>
    .TCChangeCheck-frame
    {
        background: none repeat scroll 0 0 rgba(0, 0, 0, 0.7);
        display: block;
        height: 100%;
        left: 0;
        padding-top: 10%;
        position: fixed;
        top: 0;
        width: 100%;
        z-index: 999999;
    }

    .TCChangeCheck-wrap
    {
        display: block;
        margin: 0 auto;
        width: 500px;
    }

        .TCChangeCheck-wrap .panel
        {
            margin: 0 auto;
            padding-bottom: 10px;
            padding-top: 10px;
            width: 600px;
        }

    .TCPopUpButtons
    {
        display: block;
        margin: 0 auto;
        width: 600px;
    }
</style>
<script type="text/javascript">
    var TCBox = $(".TCChangeCheck-wrap").parent();
    var RemoveTCBox = function () {
        TCBox.remove();
        PopupCounter.tc = false;
    };
    var TCUrl = "<%=this.GetMetadata("/Metadata/Settings.Terms_Conditions_Url")%>";
    var LoadTCBox = function (str) {
        TCBox.addClass("TCChangeCheck-frame").show();
        if (str == "Minor") {
            $("#btnTCOk").click(function () {
                $.getJSON("/TermsConditions/accept/2", function (data) {
                    if (data.success) {
                        RemoveTCBox();
                    }
                });
            });
        } else {
            $("#btnTCAccept").click(function () {
                $.getJSON("/TermsConditions/accept/1", function (data) {
                    if (data.success) {
                        RemoveTCBox();
                    } else {
                        top.location.href = TCUrl;
                    }
                });
            });
            $("#btnTCDeny").click(function () {
                $.getJSON("/TermsConditions/reject", function (data) {
                    if (data.success) {
                        top.location.href = "/";
                    }
                });
            });
        }
    };
    try {
        var TopURL = top.location.href;
        var LocalURL = window.location.href;
        if (
            TopURL.indexOf(TCUrl) > 0 ||
            TopURL != LocalURL ||
            LocalURL.indexOf("accountwidget") > 0 ||
            window.screen.width < 700
            ) {
            RemoveTCBox();
        }
    } catch (err) {
        RemoveTCBox();
    }
</script>
<div class="TCChangeCheck-wrap">
    <ui:Panel runat="server" ID="MustAcceptTCWithMajorChange" Visible="false">
        <%: Html.InformationMessage( this.GetMetadata(".TermsConditionsChange_Major"), true ) %>
        <div class="TCPopUpButtons">
            <%: Html.Button(this.GetMetadata(".Accept_Text"), new { @type= "button", @id = "btnTCAccept"})%>
            <%: Html.Button(this.GetMetadata(".Deny_Text"), new { @type= "button", @id = "btnTCDeny"})%>
        </div>
        <script type="text/javascript">
            LoadTCBox("Major");
        </script>
    </ui:Panel>
    <ui:Panel runat="server" ID="MustAcceptTC" Visible="false">
        <%: Html.InformationMessage(this.GetMetadata(".TermsConditionsChange_MustAccept"), true)%>
        <div class="TCPopUpButtons">
            <%: Html.Button(this.GetMetadata(".Accept_Text"), new { @type= "button", @id = "btnTCAccept"})%>
            <%: Html.Button(this.GetMetadata(".Deny_Text"), new { @type= "button", @id = "btnTCDeny"})%>
        </div>
        <script type="text/javascript">
            LoadTCBox("Major");
        </script>
    </ui:Panel>
    <ui:Panel runat="server" ID="MinorChange" Visible="false">
        <%: Html.InformationMessage( this.GetMetadata(".TermsConditionsChange_Minor"), true ) %>
        <div class="TCPopUpButtons">
            <%: Html.Button(this.GetMetadata(".Ok_Text"), new { @type= "button", @id = "btnTCOk"})%>
        </div>
        <script type="text/javascript">
            LoadTCBox("Minor");
        </script>
    </ui:Panel>
    <ui:Panel runat="server" ID="TCPopUpNo" Visible="false">
        <script type="text/javascript">
            RemoveTCBox();
        </script>
    </ui:Panel>
</div>

