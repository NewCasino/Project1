<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%@ Import Namespace="System.Globalization" %>

<script type="text/C#" runat="server">
private string ID { get; set; }
private bool IsRealMoney { get; set; }
private bool IsSportsPage 
{ 
    get
    {
        bool isSportsPage = false;
        try 
        {
            isSportsPage = (bool)this.ViewData["IsSportsPage"];
        }
        catch
        {
            isSportsPage = false;
        }
        return isSportsPage;
    }
}
protected override void OnPreRender(EventArgs e)
{
  base.OnPreRender(e);

  if (IsSportsPage) 
  {  
    if (!Profile.IsAuthenticated || !Settings.Casino_EnableQuickDeposit)
    {
        this.Visible = false;
        return;
    }
  }
  else 
  {
      this.ID = string.Format(System.Globalization.CultureInfo.InvariantCulture, "_{0}", Guid.NewGuid().ToString("N").Truncate(6));
      this.IsRealMoney = (bool)this.ViewData["RealMoney"];
      if (!Profile.IsAuthenticated || !Settings.Casino_EnableQuickDeposit || !IsRealMoney)
      {
          this.Visible = false;
          return;
      }
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
            <%: Html.H1(this.GetMetadata(".HEAD_TEXT")) %>
            <div class="QuickDepositInfo"><%=this.GetMetadata(".Info").HtmlEncodeSpecialCharactors() %></div>
            <iframe id="quickDepositFrame" frameborder="no" border="0" scrolling="no"  style="border:none;width:100%;height:500px;"></iframe>
        </div>
    </div>
</div> 
</div>
<script type="text/javascript">
$(function() {
    if ($('.QuickDepositPanel').length > 1) {
        $('body > .QuickDepositPanel').remove();
    }
    $('.QuickDepositPanel').appendTo('body');
    <% if (IsSportsPage)
    { %>
        $('#btnQuickDeposit').css('display','none').appendTo('body');
    <% }
    else 
    { %>
    var newElement = $('#quickDepositWidth<%=ID %>').clone();
    $('#quickDepositWidth<%=ID %>').remove();
    $('.CBQuickDeposit').append($(newElement).html());
    <% } %>

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

        $("#quickDepositFrame").attr("src", "/Deposit").load(function() { $(this).height($(this).contents().find("#pnDeposit").height() + 20); });
    }

    function DoQuickDepositOnce() {
      <% var quickdepositonce = Request.Cookies["quickdepositonce"];
         var cmSession = Request.Cookies["cmSession"];
         if (quickdepositonce != null && quickdepositonce.Value == cmSession.Value) 
     {%>
        return;
      <% } %>

      $.getJSON("/_get_balance.ashx?separateBonus=True&useCache=False", null, function(json) {

        if (!json.success) {
            if (json.isSessionTimedOut == true) {
                alert('<%= this.GetMetadata("/Head/_BalanceList_ascx.Session_Timedout").SafeJavascriptStringEncode() %>');
                self.location = self.location;
            }
            return;
        }

        var accounts = json.accounts;
        for (var i=0;i<accounts.length; i++) {
          var item = accounts[i];
          <%--<% if (IsSportsPage) 
          { %>
          if (item.VendorID == "OddsMatrix") {
            if (item.BalanceAmount <= 10) {
              $.cookie("quickdepositonce", '<%=cmSession.Value%>', {path:"/"});
              $('#btnQuickDeposit').click();
            }
          }
          <% } 
          else 
          { %>--%>
          if (item.VendorID == "CasinoWallet") {
            if (item.BalanceAmount <= 10) {
              $.cookie("quickdepositonce", '<%=cmSession.Value%>', {path:"/"});
              $('#btnQuickDeposit').click();
            }
          }
          <%--<% } %>--%>
        }
      });      
    }
    $(window).bind("scroll", function(){ 
        if ($('.QuickDepositPanel').height() < $(document).height()) {
            $('.QuickDepositPanel').height($(document).height());
        }
    });

    DoQuickDepositOnce();
});
</script>