<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
private string ID { get; set; }
private bool IsRealMoney { get; set; }
protected override void OnPreRender(EventArgs e)
{
  base.OnPreRender(e);
this.Visible = false;
  this.ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
  this.IsRealMoney = (bool)this.ViewData["RealMoney"];
  if (!Profile.IsAuthenticated || !Settings.Casino_EnableQuickDeposit || !IsRealMoney)
  {
      this.Visible = false;
      return;
  }
}
</script>
<div id="quickDepositWidth<%=ID %>">
<%: Html.Button(this.GetMetadata(".Button_QuickDeposit"), new { 
        @id = "btnQuickDeposit", 
        //@class = "Button",
        @style = "float: left;",
        @type = "button",
        //@disabled = "disabled"
    })%>
<div class="QuickDepositPanel">
    <div class="QuickDepositDialog">
        <a class="Close">X</a>
         <div class="QuickDepositBox">
            <iframe id="quickDepositFrame" frameborder="no" border="0" scrolling＝"no"  style="border:none;width:100%;"></iframe>
        </div>
    </div>
</div> 
</div>
<script type="text/javascript">
$(function() {
    $('.QuickDepositPanel').appendTo('body');
    var newElement = $('#quickDepositWidth<%=ID %>').clone();
    $('#quickDepositWidth<%=ID %>').remove();
    $('.CBQuickDeposit').append($(newElement).html());

    $('#btnQuickDeposit').click(function() {
        try { OpenQuickDepositDialog(); } catch(e) {}
    });
    $(".QuickDepositDialog .Close").click(function () {
        $(".QuickDepositPanel").hide();
         $("#quickDepositFrame").attr("src", "");
    });

    function OpenQuickDepositDialog() {
        $('.simplemodal-close').click();
        $('.QuickDepositPanel', document).hide();
        $('.QuickDepositPanel').width($(document).width());
        $('.QuickDepositPanel').height($(document).height());
        var dialogLeft = ($(document).width() - $('.QuickDepositDialog').width()) / 2;
        if (dialogLeft < 0) dialogLeft = 0;
        $('.QuickDepositDialog', document).css('left', dialogLeft);
        $('.QuickDepositPanel', document).show();
        $("#quickDepositFrame").attr("src", "/QuickDeposit");
    }
});
</script>