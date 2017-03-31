<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx<GamMatrix.CMS.Models.MobileShared.Components.BonusSelectorViewModel>" %>

<div class="BonusContainer" id="bonusContainer">
<div class="FormItem SquareForm" id="selectBonusChoose">
<input class="FormRadio" type="checkbox" autocomplete="off" id="bonusSwitchRadio" />
<label for="bonusSwitchRadio" class="FormBulletLabel"><%= this.GetMetadata(".BonusSelect_Switch").HtmlEncodeSpecialCharactors()%></label>
</div>

<div class="BonusContainer SelectBonusContainer Hidden" id="selectBonusContainer" data-config="<%= this.Model.GetBonusUrl().SafeHtmlEncode() %>">
<input type="hidden" autocomplete="off" id="bonusVendor" name="bonusVendor" disabled />
</div>

    <div class="FormItem SquareForm" id="bonusCodeChoose">
        <input class="FormRadio" type="checkbox" autocomplete="off" id="bonusCodeSwitchRadio" />
        <label for="bonusCodeSwitchRadio" class="FormBulletLabel"><%= this.GetMetadata(".BonusCode_Switch").HtmlEncodeSpecialCharactors()%></label>
    </div>
<div class="BonusContainer InputBonusContainer Hidden" id="inputBonusContainer">
<div class="FormItem">
<label class="FormLabel" for="bonusCodeInput"><%= this.GetMetadata(".InputBonus_Label").SafeHtmlEncode()%></label>
<%: Html.TextBox("bonusCode", string.Empty, new Dictionary<string, object>()
{
{ "id", "bonusCodeInput" },
{ "class", "FormInput" },
{ "maxlength", "30" },
{ "disabled", "disabled" },
{ "placeholder", this.GetMetadata(".InputBonus_Label") },
{ "data-validator", ClientValidators.Create().Required(this.GetMetadata(".InputBonus_Empty")) },
}) %>
<span class="FormStatus">Status</span>
<span class="FormHelp"></span>
</div>
</div>
</div>

<script type="text/html" id="bonusContentTemplate">
<ul class="FormRadio SelectBonusType" id="bonusSelector">
<# var items = arguments[0];
for (var i = 0; i < items.length; i++){ 
var item = items[i]; #>
<li class="FormItem">
<input class="BonusRadioCheck" id="<#= item.code #>Bonus" type="radio" name="bonusCode" value="<#= item.code #>" data-vendor="<#= item.vendorID #>" />
<label class="FormBulletLabel BonusInfo" for="<#= item.code #>Bonus">
<span class="BonusTitle"><#= item.name #></span>
<# if (item.bannerHTML) { #>
<span class="BonusDescription"><#= item.bannerHTML #></span>
<# } #>
</label>
</li>
<# } #>
</ul>
</script>

<ui:MinifiedJavascriptControl ID="MinifiedJavascriptControl1" runat="server" Enabled="true" AppendToPageEnd="true">
<script type="text/javascript">
var BonusSelector = (function () {//internal classes in closure
var hiddenStyle = 'Hidden';

function BonusOptionSelect() {
var dispatcher = new CMS.utils.Dispatcher(),
selectContainer = $('#selectBonusContainer'), bonusVendor = $('#bonusVendor'),
localEnabled, serverEnabled,
cache = {}, currentId = null;

function onConfigLoaded(json, id) {
serverEnabled = json.success;

if (!serverEnabled) {
    currentId = null;
    $("#selectBonusChoose").toggleClass(hiddenStyle, true);
return;
}

var content = $($('#bonusContentTemplate').parseTemplate(parseConfig(json)));
$('.BonusRadioCheck', content).change(onOptionChanged);
cache[id] = content;

if (id == currentId) {
selectContainer.append(content);
resetOptions();
dispatcher.trigger('loaded');
}
}

function parseConfig(json) {
var config = [];
for (var vendor in json.bonuses) {
var bonuses = json.bonuses[vendor];

if (bonuses instanceof Array) {
for (var i = 0; i < bonuses.length; i++)
bonuses[i].vendorID = vendor;

config = config.concat(bonuses);
}
}

return config;
}

function onOptionChanged(event) {
bonusVendor.val($(this).data('vendor'));
}

function updateSettings(settings) {
toggleOptions(false);

var id = settings.config;
localEnabled = settings.enabled;
serverEnabled = (cache[id] != null);

if (cache[currentId])
cache[currentId].detach();

if (!localEnabled)
return;

if (serverEnabled) {
selectContainer.append(cache[id]);
} else {
$.ajax({
url: selectContainer.data('config') + '&AccountID=' + id,
dataType: 'json',
success: function (json) { return onConfigLoaded(json, id); }
});
}

currentId = id;
}

function toggleOptions(state) {
selectContainer.toggleClass(hiddenStyle, !state);

getOptions().add(bonusVendor).prop('disabled', !state);
if (state) 
resetOptions();
}

function resetOptions() {
var firstOption = getOptions().eq(0);

firstOption.prop('checked', true);
bonusVendor.val(firstOption.data('vendor'));
}

function getOptions() {
return $('.BonusRadioCheck', selectContainer);
}

function getEnabled() {
return localEnabled && serverEnabled;
}

return {
update: updateSettings,
toggle: toggleOptions,
enabled: getEnabled,

evt: dispatcher
}
}

function BonusOptionInput() {
var inputContainer = $('#inputBonusContainer'),
inputField = $('#bonusCodeInput'),
enabled;

function updateSettings(settings) {
toggleInput(false);

enabled = settings.enabled;
}

function toggleInput(state) {
inputContainer.toggleClass(hiddenStyle, !state);

inputField.prop('disabled', !state);
if (state)
inputField.val('');
}

function getEnabled() {
return enabled;
}

return {
update: updateSettings,
toggle: toggleInput,
enabled: getEnabled
}
}

function BonusSelector() {
var bonusContainer = $('#bonusContainer'),
bonusSwitch = $('#bonusSwitchRadio');
    bonusCodeSwitch = $('#bonusCodeSwitchRadio');

var selectBonus = new BonusOptionSelect(),
inputBonus = new BonusOptionInput(),
activeBonus;

selectBonus.evt
.bind('loaded', function () {
toggleBonus(selectBonus.enabled());
switchBonus();
});

bonusSwitch.change(function (event) {
    switchBonus();
    if (!bonusSwitch.is(':checked')) {
        $('#bonusVendor').val('');
    }
    $('#bonusCodeInput').val('');
    bonusCodeSwitch.attr("checked", false);
    inputBonus.toggle(false);
});
bonusCodeSwitch.change(function (event) {
    switchBonusCode();
    if (!bonusSwitch.is(':checked')) {
        $('#bonusVendor').val('');
    }
    $('#bonusVendor').val('');
    bonusSwitch.attr("checked", false);
    selectBonus.toggle(false);
});

function updateBonuses(settings) {

                selectBonus.update(settings.selectBonus);
                inputBonus.update(settings.inputBonus);

                if (settings.selectBonus.enabled || settings.inputBonus.enabled) {
                    toggleBonus(true);
                    if (settings.selectBonus.enabled){
                        switchBonus();
                    }
                    else {
                        $("#selectBonusChoose").toggleClass(hiddenStyle, true);
                    }
                    if (settings.inputBonus.enabled) {
                        switchBonusCode();
                    }
                    else {
                        $("#bonusCodeChoose").toggleClass(hiddenStyle, true);
                    }
                } else
                    toggleBonus(false);
            }

            function toggleBonus(state) {
                bonusContainer.toggleClass(hiddenStyle, !state);
            }

            function switchBonus() {
                selectBonus.toggle(bonusSwitch.is(':checked'));
            }
            function switchBonusCode() {
                inputBonus.toggle(bonusCodeSwitch.is(':checked'));
            }

            updateBonuses({ selectBonus: {}, inputBonus: {} });

            return {
                update: updateBonuses
            }
        }

        return BonusSelector;
    })();
</script>
</ui:MinifiedJavascriptControl>