<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>
<%@ Import Namespace="GamMatrixAPI" %>
<%@ Import Namespace="Finance" %>
<%@ Import Namespace="GmCore" %>
<%@ Import Namespace="System.Linq" %>

<script type="text/c#" runat="server">
    private bool CheckISFirstDeposit()
    {
        TransSelectParams transSelectParams = new TransSelectParams()
        {
            ByTransTypes = true,
            ParamTransTypes = new List<TransType> { TransType.Deposit, TransType.Vendor2User },
            ByUserID = true,
            ParamUserID = Profile.UserID,
            ByTransStatuses = true,
            ParamTransStatuses = new List<TransStatus>
            {
                TransStatus.Success,
            },
            ByDebitPayableTypes = true,
        };

        transSelectParams.ParamDebitPayableTypes = Enum.GetNames(typeof(PayableType))
            .Select(t => (PayableType)Enum.Parse(typeof(PayableType), t))
            .Where(t => t != PayableType.AffiliateFee && t != PayableType.CasinoFPP)
            .ToList();

        transSelectParams.ByCompleted = true;
        transSelectParams.ParamCompletedTo = DateTime.Now.AddDays(1);
        transSelectParams.ParamCompletedFrom = new DateTime(1900, 1, 1);

        using (GamMatrixClient client = GamMatrixClient.Get())
        {
            GetTransRequest getTransRequest = client.SingleRequest<GetTransRequest>(new GetTransRequest()
            {
                SelectionCriteria = transSelectParams,
                PagedData = new PagedDataOfTransInfoRec
                {
                    PageSize = 2,
                    PageNumber = 0,
                }
            });
            return (getTransRequest.PagedData.Records == null || getTransRequest.PagedData.Records.Count == 0);
        }
    }
</script>
<% if(Profile.IsAuthenticated && (Settings.IsUKLicense || Profile.UserCountryID == 230) && Settings.SafeParseBoolString(Metadata.Get("Metadata/Settings.EnableSetLimitPopup"), true) && CheckISFirstDeposit() && Request.Cookies["hasSetLimit"] == null)
{ %>
<div class="setlimitpopup-style">
<%= this.GetMetadata(".CustomCSS").HtmlEncodeSpecialCharactors() %>
</div>
<div class="limit-overlay">
<div class="limit-wrap">
    <div class="limit-box">
        <h2><%= this.GetMetadata(".Limit_Title").SafeHtmlEncode() %></h2>
        <ul class="limit_list">
            <li class="limit_item"><input type="radio" name="limit_type" id="limitNo" class="limit_type" /><label for="limitNo"><%= this.GetMetadata(".Limit_No").SafeHtmlEncode() %></label><a class="limit_url" href="javascript:void(0);"></a></li>
            <li class="limit_item"><input type="radio" name="limit_type" id="limitDeposit" class="limit_type" /><label for="limitDeposit"><%= this.GetMetadata(".Limit_Deposit").SafeHtmlEncode() %></label><a class="limit_url" href="/limit/deposit"></a></li>
            <li class="limit_item"><input type="radio" name="limit_type" id="limitLoss" class="limit_type" /><label for="limitLoss"><%= this.GetMetadata(".Limit_Loss").SafeHtmlEncode() %></label><a class="limit_url" href="/limit/loss"></a></li>
            <li class="limit_item"><input type="radio" name="limit_type" id="limitWagering" class="limit_type" /><label for="limitWagering"><%= this.GetMetadata(".Limit_Wagering").SafeHtmlEncode() %></label><a class="limit_url" href="/limit/wagering"></a></li>
            <li class="limit_item"><input type="radio" name="limit_type" id="limitSession" class="limit_type" /><label for="limitSession"><%= this.GetMetadata(".Limit_Session").SafeHtmlEncode() %></label><a class="limit_url" href="/limit/session"></a></li>
        </ul>
        <div class="limit-buttons">
            <%: Html.Button(this.GetMetadata(".Button_Setting"), new { @type="button", @class="limit-button button" } )%>
        </div>
    </div>
</div>
</div>
<script type="text/javascript">
    $(function() {
        var $container = $('body',top.document);
        
        if ($('.limit-overlay', $container).length == 0) {console.log('start');
            $('.setlimitpopup-style, .limit-overlay').appendTo($container);
        }
        
        var left = parseInt(($container.width() - $('.limit-wrap', $container).width()) / 2);
        $('.limit-wrap', $container).css('left', left);
        $('.limit-overlay', $container).width($container.width()).height($container.height()).css('display','block');

        $('.limit-button.button', $container).click(function(e) {
            e.preventDefault();
            var $container = $(top.document);
            var limit_type = $('input.limit_type:checked', $container);
            if (limit_type.length == 0) {
                alert('<%=this.GetMetadata(".NoCheckLimit").SafeJavascriptStringEncode() %>');
            } else if (limit_type.attr('id') == 'limitNo') {
                $.cookie('hasSetLimit', true);
                $('.limit-overlay', $container).hide();
            } else {
                $.cookie('hasSetLimit', true);    
                top.window.location = limit_type.siblings('.limit_url').attr('href');
                $('.limit-overlay', $container).hide();
            }            
        });

        $container.bind('resize', function() {
            var left = parseInt(($container.width() - $('.limit-wrap', $container).width()) / 2);
            $('.limit-wrap', $container).css('left', left);
        });
    });
</script>
<%}%>
