<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<dynamic>" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="CM.db" %>

<% 
    cmSite domain = this.ViewData["cmSite"] as cmSite;
%>

<div id="visibility-order-links" class="payment-method-mgt-links">
<ul>
    <li><a href="javascript:void(0)" target="_self" class="refresh">Refresh</a></li>
    <li>|</li>
    <li><a href="javascript:void(0)" target="_self" class="save">Save</a></li>
    <li>|</li>
    <li>
        <a href="<%= this.Url.RouteUrl( "HistoryViewer", new {  
            @action = "Dialog",
            @distinctName = domain.DistinctName.DefaultEncrypt(),
            @relativePath = "/.config/PaymentMethods".DefaultEncrypt(),
            @searchPattner = ".%",
            } ).SafeHtmlEncode()  %>" target="_blank" class="history">Change history...</a>
    </li>
</ul>
</div>

<hr class="seperator" />

<div style="margin-top: 20px; padding: 0pt 0.7em;" class="ui-state-error ui-corner-all"> 
	<p><span style="float: left; margin-right: 0.3em;" class="ui-icon ui-icon-alert"></span>
    <p style="color:red;">
	<strong>WARNING</strong>
    <ul style="font-size:16px; color:red; font-family:Consolas">
        <li>Enabling payment method below only affects visibility in the frontend!</li>
        <li>It <strong>DOES NOT</strong> mean this payment method works!</li>
        <li>You <strong>MUST</strong> guarantee that the payment method is configured in backend with correct bank details before show it!</li>
        <li>If you have any query, please contact Account Manager.</li>
    </ul>
    </p>
</div>
<br />

<% 
    using (Html.BeginRouteForm("PaymentMethodMgt", new
    {
        @action = "SaveVisibilityAndOrder",
        @distinctName = domain.DistinctName.DefaultEncrypt()
    }, FormMethod.Post
    , new { @id = "formSaveVisibilityAndOrder" }
    ))
    {
        PaymentMethodCategory[] categories = PaymentMethodManager.GetCategories(domain, "en");
        PaymentMethod[] paymentMethods = PaymentMethodManager.GetPaymentMethods(domain, false).ToArray();

        foreach (PaymentMethodCategory category in categories)
        {  %>

<div class="pm-category">
    <%: Html.H5(category.GetDisplayName(domain, "en"))%>

    <% 
    foreach (PaymentMethod paymentMethod in paymentMethods.Where(p => p.Category == category).OrderBy(p => p.Ordinal))
    {
        if (!string.Equals(domain.DistinctName, "Shared", StringComparison.InvariantCultureIgnoreCase) ||
                !string.Equals(domain.DistinctName, "MobileShared", StringComparison.InvariantCultureIgnoreCase))
        {
            if (!GmCore.DomainConfigAgent.IsVendorEnabled(paymentMethod, domain))
                continue;
        }
            %>
            <div class="pm-item">
                <table cellpadding="5" cellspacing="0" border="0">
                    <tr>
                        <td valign="middle">
                            <%: Html.CheckBox(string.Format("enabled_{0}", paymentMethod.UniqueName.SafeHtmlEncode())
                            , paymentMethod.IsVisible
                            )%>
                        </td>
                        <td valign="middle"><div class="icon" style="background-image:url('<%= paymentMethod.GetImageUrl(domain) %>')"></div></td>
                        <td valign="middle"><span class="<%= paymentMethod.IsDisabled ? "disabled" : "" %>"><%= paymentMethod.UniqueName.SafeHtmlEncode()%></span></td>
                    </tr>
                </table>
                <input type="hidden" name="ordinal_<%= paymentMethod.UniqueName.SafeHtmlEncode() %>" value="<%= paymentMethod.Ordinal %>" />
            </div>
            <%
    }
    %>

</div>


<%      }
    }%>

<div style="clear:both"></div>



<ui:ExternalJavascriptControl ID="ExternalJavascriptControl1" runat="server" Enabled="false">
<script type="text/javascript">
function TabVisibilityOrder(viewEditor) {
    self.tabVisibilityOrder = this;

    if (document.captureEvents) { document.captureEvents(Event.MOUSEMOVE | Event.MOUSEUP); }

    $(document.body).bind('mouseup', this, function (e) { e.data.onMouseUp(); });
    $(document.body).bind('mousemove', this, function (e) { e.data.onMouseMove(e.pageX, e.pageY); });
    $(document.body).bind("selectstart", function (e) { e.preventDefault(); });

    this.init = function () {
        $('#visibility-order-links a.refresh').bind('click', this, function (e) {
            e.preventDefault();
            e.data.refresh();
        });
        $('#visibility-order-links a.save').bind('click', this, function (e) {
            e.preventDefault();
            e.data.save();
        });
        $('div.pm-category .pm-item .icon').bind('mousedown', this, function (e) { e.data.onImgMouseDown(e.pageX, e.pageY, $(this).parents('div.pm-item')); });

        $('#visibility-order-links a.history').click(function (e) {
            var wnd = window.open($(this).attr('href'), null, "width=1000,height=700,toolbar=no,location=no,directories=0,status=yes,menubar=no,copyhistory=no");
            if (wnd) e.preventDefault();
        });
    };

    this.refresh = function () {
        if (self.startLoad) self.startLoad();
        var url = '<%= this.Url.RouteUrl( "PaymentMethodMgt", new { @action = "TabVisibilityOrder", @distinctName = (this.ViewData["cmSite"] as cmSite).DistinctName.DefaultEncrypt() }).SafeJavascriptStringEncode() %>';
        $('#visibility-order-links').parent().load(url, function () {
            if (self.stopLoad) self.stopLoad();
            self.tabVisibilityOrder.init();
        });
    };

    this.isMouseDown = false;
    this.offset = {};
    this.selectedElem = null;
    this.container = null;

    this.onImgMouseDown = function (x, y, elem) {
        if (this.isMouseDown)
            return;
        this.isMouseDown = true;
        this.offset.x = x - elem.offset().left;
        this.offset.y = y - elem.offset().top;
        this.selectedElem = elem;
        this.container = elem.parents('div.pm-category');

        this.placeHolder = $('<div class="placeholder"></div>').insertBefore(elem);
        this.placeHolder.height(elem.height());

        this.selectedElem.width(this.selectedElem.width());
        this.selectedElem.height(this.selectedElem.height());
        this.selectedElem.addClass('moving');

        this.selectedElem.css('left', (x - this.offset.x));
        this.selectedElem.css('top', (y - this.offset.y));
    };

    this.onMouseUp = function () {
        if (!this.isMouseDown)
            return;
        this.isMouseDown = false;
        this.isMouseMoved = false;

        this.selectedElem.insertBefore(this.placeHolder).removeClass('moving');
        this.placeHolder.remove();

        var items = $('div.pm-item', this.container);
        for (var i = 0; i < items.length; i++) {
            $(':hidden', items[i]).val(i + 1);
        }
    };

    this.onMouseMove = function (x, y) {
        if (!this.isMouseDown)
            return;

        x -= this.offset.x;
        y -= this.offset.y;

        this.selectedElem.css('left', x);
        this.selectedElem.css('top', y);

        x += this.selectedElem.width() / 2;

        var items = $('div.pm-item', this.container);
        for (var i = 0; i < items.length; i++) {
            if ($(items[i]).hasClass('moving'))
                continue;
            var pos = $(items[i]).position();
            if (y > pos.top &&
                y < pos.top + $(items[i]).height() &&
                x > pos.left &&
                x < pos.left + $(items[i]).width()) {
                if (y < pos.top + $(items[i]).height() / 2) {
                    this.placeHolder.insertBefore(items[i]);
                } else {
                    this.placeHolder.insertAfter(items[i]);
                }
                break;
            }
        }
    };

    this.save = function () {
        var options = {
            type: 'POST',
            dataType: 'json',
            success: function (json) {
                if (!json.success) { alert(json.error); }
                if (self.stopLoad) self.stopLoad();
            }
        };
        if (self.startLoad) self.startLoad();
        $('#formSaveVisibilityAndOrder').ajaxForm(options);
        $('#formSaveVisibilityAndOrder').submit();
    };

    this.init();
}
</script>
</ui:ExternalJavascriptControl>