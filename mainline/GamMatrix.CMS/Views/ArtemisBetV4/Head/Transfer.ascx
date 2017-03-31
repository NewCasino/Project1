<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<script type="text/C#" runat="server">
    private bool? _ShowClose = null;
    private bool ShowClose {
        get {
            if (!_ShowClose.HasValue)
            {
                if (this.ViewData["ShowClose"] != null)
                {
                    bool temp = false;
                    if (bool.TryParse(this.ViewData["ShowClose"].ToString().Trim(), out temp))
                        _ShowClose = temp;
                }
                if (!_ShowClose.HasValue)
                    _ShowClose = false;
            }
            return _ShowClose.Value;
        }
    }
</script>

<%-- if( Profile.IsAuthenticated ) { %>
<div id="transfer-button-wrap">
    <%: Html.LinkButton(this.GetMetadata(".BUTTON_TEXT"), new { @class = "transfer-button", @href = this.Url.RouteUrl("Transfer", new { @action = "Index" }), @target = "_top" })%>
</div>

<script type="text/javascript">

    $(function () {

        var height = 500;
        var width = 750;

        function onDialogOpen(dialog) {
            dialog.data.css('padding', '0px').show();
            var marginLeft = (width / -2).toString(10) + "px";
            dialog.container.css("margin-left", marginLeft);
            dialog.container.css("width", width.toString(10) + "px");
            dialog.container.css({ "z-index": "999999", "height": "auto", "top": "25px", "left": "50%" }).show();
            dialog.overlay.css("z-index", "999998").show();

            $('div.simplemodal-wrap', dialog.container).css('overflow', 'hidden');
        };

        $('#transfer-button-wrap a.transfer-button').click(function (e) {
            e.preventDefault();

            var id = '_dlg_' + (new Date).getTime().toString();
            var $iframe = $('<iframe allowTranceparency="true" scrolling="no" frameborder="0" style="background-color:transparent"></iframe>');
            $iframe.attr('id', id);
            $iframe = $iframe.appendTo(top.document.body);
            $iframe = $(top.document.getElementById(id));
            $iframe.width(width).height(height);

            var url = '<%= this.Url.RouteUrl("Transfer", new { @action = "QuickTransfer" }).SafeJavascriptStringEncode() %>/?_=' + ((new Date).getTime());
            $iframe.attr('src', url);

            var dialogCloseHtml = '<%= ShowClose ? @"<a class=""modalCloseImg"" title=""Close""></a>" : "" %>';

            $.modal($iframe[0], { appendTo: top.document.body
            , width: width
            , height: height
            , minHeight: height
            , autoResize: false
            , autoPosition: false
            , closeHTML: dialogCloseHtml
            , onOpen: onDialogOpen
            , containerCss: { padding: '0px'
                            , border: 'solid 1px #999999'
                            , background: 'url(/images/icon/loading.gif) no-repeat 20px 20px #000000'
            }
            , overlayClose: true
            , onClose: function (dialog) {
                dialog.placeholder = false;
                $.modal.close();
            }
            });
        });
    });
</script>

<% } --%>