<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<%

string leftPath = Request.IsHttps() ? "https://" + Request.Url.Host : "http://" + Request.Url.Host;
%>
<ul class="Tabs Cols-3 Container SettingsTabs SettingsTabs_V2">
<li class="Col Tab ActiveTab OddsFormat" id="OddsFormatTab">
<a class="TabLink" id="otherTab" 
            data-tablink="<%= leftPath + Url.RouteUrl("Menu", new { @action = "AccountSettingsPartial" }) %>">
            <%= this.GetMetadata(".OtherSettings").HtmlEncodeSpecialCharactors()%>
</a>
</li>
<li class="Col Tab SelfExclusion" id="SelfExclusionTab">
<a class="TabLink" id="exclusionTab" 
            data-tablink="<%= leftPath + Url.RouteUrl("Menu", new { @action = "SelfExclusionPartial" }) %>">
            <%= this.GetMetadata(".SelfExclusion").HtmlEncodeSpecialCharactors()%>
</a>
</li>
<li class="Col Tab DepositLimit" id="DepositLimit">
<a class="TabLink" id="limitTab" 
            data-tablink="<%= leftPath + Url.RouteUrl("Menu", new { @action = "DepositLimitPartial" }) %>">
            <%= this.GetMetadata(".DepositLimit").HtmlEncodeSpecialCharactors()%>
</a>
</li>
</ul>

<div id="settingsLoaderContainer" class="LoaderContainer Hidden">
    <div id="settingsLoadingContent" class="LoadingContent">
        <div class="spinner spinner--steps icon-spinner2 LoadingIcon" aria-hidden="true"></div>
        <span id="settingsLoadDetails" class="LoadDetails"><%= this.GetMetadata(".SettingsLoading_Text").SafeJavascriptStringEncode() %></span>
    </div>
</div>

<div id="settingsContainer" class="SettingsContainer SettingsContainer_V2">
    <% Html.RenderPartial("/AccountSettings/InputView"); %>
</div>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" AppendToPageEnd="false">
<script type="text/javascript">
    $('.TabLink').on('click', function () {
        var $tabLink = $(this);
        var $parentTab = $tabLink.parent();
        var $settingsLoaderContainer = $('#settingsLoaderContainer');
        var $settingsLoadDetails = $('#settingsLoadDetails');

        if ($parentTab.hasClass('ActiveTab')) {
            return;
        } else {
            $('.Tab').removeClass('ActiveTab'); //remove activetab class for all tabs
            $parentTab.addClass('ActiveTab');

            var $settingsContainer = $('#settingsContainer');
            $settingsContainer.fadeOut('fast')
                .promise()
                .done(function () {
                    $settingsLoaderContainer.removeClass('Hidden');
                    $.ajax({
                        url: $tabLink.data('tablink')
                        , type: "GET"
                        , xhrFields: { withCredentials: true }
                    })
                    .done(function (partialViewResult) {
                        $settingsContainer.html(partialViewResult);
                        $settingsLoaderContainer.addClass('Hidden');
                        $settingsContainer.fadeIn('fast');
                    }).fail(function (xhr, textStatus, errorThrown) {
                        $settingsLoaderContainer.addClass('Hidden');
                        $settingsContainer.html('<p>' + xhr + '; ' + textStatus + '; ' + errorThrown + '</p>');
                    });
                });
        }
    });
</script>
</ui:MinifiedJavascriptControl>