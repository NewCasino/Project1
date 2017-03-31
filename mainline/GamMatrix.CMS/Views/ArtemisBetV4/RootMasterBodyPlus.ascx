<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
protected string testdata = string.Empty;
    protected override void OnInit(EventArgs e) {
        

        base.OnInit(e);
    }
</script>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="true">


    <script type="text/javascript">
        $(window).load(function() {
            //$(".LiveChatFixed").click(function(e){
            //  e.preventDefault();
            //    $(".lebtn div").trigger("click");
            //});
        });
        if (window.location.toString().indexOf('.gammatrix-dev.net') > 0)
            document.domain = document.domain;
        else
            document.domain = '<%= SiteManager.Current.SessionCookieDomain.SafeJavascriptStringEncode() %>';

        $(function() {
            //$("[src='//cdn.everymatrix.com/_js/jquery-1.11.2.min.js']").prependTo("head");
            $('.tablePaymentMethodsList').off('click', 'a.PaymentItem[data-resourcekey=Neteller]').on('click', 'a.PaymentItem[data-resourcekey=Neteller]', function(e) {
            e.preventDefault();
            //$('a.livechat').trigger('click');
            $("#support-notice").modal({
                    autoResize: true,
                    maxHeight: 240,
                    containerCss: {
                        border: '6px solid #050506',
                        borderRadius: '.5em',
                        backgroundColor: '#1d2127'
                    }
                });
            });
            $("#simplemodal-container .simplemodal-data").css("min-width","auto !important").css("min-height","auto !important")
        });

    </script>
</ui:MinifiedJavascriptControl>
<div id="support-notice" class="Hidden">
    <%=this.GetMetadata(".Contact_Support_Html") %>
</div>