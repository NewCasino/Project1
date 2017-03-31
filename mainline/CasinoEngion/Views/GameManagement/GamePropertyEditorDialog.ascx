<%@ Control Language="C#" Inherits="System.Web.Mvc.ViewUserControl" %>
<%@ Import Namespace="CE.db" %>

<script type="text/C#" runat="server">
    private List<SelectListItem> GetAvailableProperties()
    {
        List<SelectListItem> list = new List<SelectListItem>();

        list.Add(new SelectListItem() { Text = "Availability", Value = "Enabled", Selected = true });
        list.Add(new SelectListItem() { Text = "Jackpot Type", Value = "JackpotType" });

        if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
        {
            list.Add(new SelectListItem() { Text = "Operator-Visible", Value = "OpVisible" });
            list.Add(new SelectListItem() { Text = "License", Value = "License" });
            list.Add(new SelectListItem() { Text = "Exclude from Bonuses", Value = "ExcludeFromBonuses" });
            list.Add(new SelectListItem() { Text = "Editable by Operator (Exclude from Bonuses)", Value = "ExcludeFromBonuses_EditableByOperator" });

            list.Add(new SelectListItem() { Text = "Support Free Spin Bonus", Value = "SupportFreeSpinBonus" });
        }
        else
        { 
            if(ShowExcludeFromBonusesForOperator)
                list.Add(new SelectListItem() { Text = "Exclude from Bonuses", Value = "ExcludeFromBonuses" });
        }

        list.Add(new SelectListItem() { Text = "FPP", Value = "FPP" });
        list.Add(new SelectListItem() { Text = "BonusContribution", Value = "BonusContribution" });
        list.Add(new SelectListItem() { Text = "PopularityCoefficient", Value = "PopularityCoefficient" });
        list.Add(new SelectListItem() { Text = "LaunchGameInHtml5", Value = "LaunchGameInHtml5" });
        list.Add(new SelectListItem() { Text = "AgeLimit", Value = "AgeLimit" });
        
        if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
        {
            list.Add(new SelectListItem() { Text = "AnonymousFunMode", Value = "AnonymousFunMode" });
            list.Add(new SelectListItem() { Text = "FunMode", Value = "FunMode" });
            list.Add(new SelectListItem() { Text = "RealMode", Value = "RealMode" });
        }
        
        if (DomainManager.CurrentDomainID == Constant.SystemDomainID)
        {
            list.Add(new SelectListItem() { Text = "Width", Value = "Width" });
            list.Add(new SelectListItem() { Text = "Height", Value = "Height" });
        }
        list.Add(new SelectListItem() { Text = "NewGame and NewGame Expitation Date", Value = "NewGame" });
        
        list.Add(new SelectListItem() { Text = "Tags", Value = "Tags" });
        
        return list;
    }

    private List<SelectListItem> GetEditTypeList()
    {
        List<SelectListItem> list = new List<SelectListItem>();
        list.Add(new SelectListItem() { Text = "Add", Value = "Add" });
        list.Add(new SelectListItem() { Text = "Delete", Value = "Delete" });
        return list;
    }

    private List<SelectListItem> GetLicenseList()
    {
        Array values = Enum.GetValues(typeof(LicenseType));
        List<SelectListItem> list = new List<SelectListItem>();
        foreach (object value in values)
        {
            list.Add(new SelectListItem()
            {
                Text = Enum.GetName(typeof(LicenseType), value),
                Value = value.ToString(),
            });
        }

        return list;
    }

    private List<SelectListItem> GetJackpotTypeList()
    {
        Array values = Enum.GetValues(typeof(CE.db.JackpotType));
        List<SelectListItem> list = new List<SelectListItem>();
        foreach (object value in values)
        {
            list.Add(new SelectListItem()
            {
                Text = Enum.GetName(typeof(CE.db.JackpotType), value),
                Value = value.ToString(),
            });
        }

        return list;
    }

    private bool ShowExcludeFromBonusesForOperator { get; set; }
    protected override void OnInit(EventArgs e)
    {
        base.OnInit(e);
        ShowExcludeFromBonusesForOperator = Request.QueryString["ShowExcludeFromBonusesForOperator"] == "true";
    }
</script>
<style type="text/css">
    .propertyItem{ display:none;}
    .col_label{ width:100px; text-align:right; vertical-align:top; padding-right:10px;}
    .newGameDatePicker { display: inline;}
    .date-inputbox{text-align:center;width: 80px;background: #acacac;}
</style>
<div id="edit_selected_games">
<table cellpadding="0" cellspacing="3" border="0" style="width:100%; table-layout:fixed;">
    <tr>
    <td class="col_label">
    <label class="label">Property:</label>
    </td>
    <td>
    <%: Html.DropDownList("roperties", GetAvailableProperties(), new { @id = "ddlProperties", @class = "ddl" })%>
    </td>
    </tr>
    <tr>
    <td class="col_label">
    <label class="label">Set value to:</label>
    </td>
    <td>
        <% if (CurrentUserSession.UserDomainID == Constant.SystemDomainID) { %>
        <div class="propertyItem" id="propertyOpVisible">
        <form action="">
        <input type="checkbox" id="OpVisible" name="OpVisible" style=" float:left; margin: 4px 4px 4px 0;" /><label for="OpVisible" style=" display:block;">Operator Visible</label>
        </form>
        </div>

        <div class="propertyItem" id="propertyLicense">
        <form action="">
        <%: Html.DropDownList("license", GetLicenseList(), new { @class = "ddl", @id = "ddlLisenceType" })%>
        </form>
        </div>

        <div class="propertyItem" id="propertyExcludeFromBonuses">
        <form action="">
        <%= Html.CheckBox("excludeFromBonuses", false, new { @id = "excludeFromBonuses" })%> <label for="excludeFromBonuses">Exclude from Bonuses</label>
        </form>
        </div>

        <div class="propertyItem" id="propertyExcludeFromBonuses_EditableByOperator">
        <form action="">
        <%= Html.CheckBox("excludeFromBonuses_EditableByOperator", false, new { @id = "excludeFromBonuses_EditableByOperator" })%> <label for="excludeFromBonuses_EditableByOperator">Editable by Operator (Exclude from Bonuses)</label>
        </form>
        </div>
        <%}
           else if (ShowExcludeFromBonusesForOperator)
           { %>
            <div class="propertyItem" id="propertyExcludeFromBonuses">
            <form action="">
            <%= Html.CheckBox("excludeFromBonuses", false, new { @id = "excludeFromBonuses" })%> <label for="excludeFromBonuses">Exclude from Bonuses</label>
            </form>
            </div>
        <%}%>

        <%if (CurrentUserSession.UserDomainID == Constant.SystemDomainID)
          { %>
        <div class="propertyItem" id="propertyRealMode">
        <form action="">
        <%= Html.CheckBox("realMode", false, new { @id = "realMode" })%> <label for="realMode">Enable Real Mode</label>
        </form>
        </div>
        <div class="propertyItem" id="propertyFunMode">
        <form action="">
        <%= Html.CheckBox("funMode", false, new { @id = "funMode" })%> <label for="funMode">Enable Fun Mode</label>
        </form>
        </div>
        <div class="propertyItem" id="propertyAnonymousFunMode">
        <form action="">
        <%= Html.CheckBox("anonymousFunMode", false, new { @id = "anonymousFunMode" })%> <label for="anonymousFunMode">Anonymous Fun Mode</label>
        </form>
        </div>

        <div class="propertyItem" id="propertySupportFreeSpinBonus">
        <form action="">
        <%= Html.CheckBox("supportFreeSpinBonus", false, new { @id = "supportFreeSpinBonus" })%> <label for="supportFreeSpinBonus">Support Free Spin Bonus</label>
        </form>
        </div>
        
         <div class="propertyItem" id="propertyLaunchGameInHtml5">
        <form action="">
        <%= Html.CheckBox("launchGameInHtml5", false, new { @id = "launchGameInHtml5" })%> <label for="launchGameInHtml5">Launch Game In HTML5 Mode</label>
        </form>
        </div>
        
         <div class="propertyItem" id="propertyAgeLimit">
        <form action="">
        <%= Html.CheckBox("ageLimit", false, new { @id = "ageLimit" })%> <label for="ageLimit">Age Limit</label>
        </form>
        </div>

        <%} %>
        <div class="propertyItem" id="propertyEnabled">
        <form action="">
        <input type="checkbox" id="gameEnabled" name="gameEnabled" style=" float:left; margin: 4px 4px 4px 0;" /><label for="gameEnabled" style=" display:block;">Enabled</label>
        </form>
        </div>
        <div class="propertyItem" id="propertyWidth">
        <form action="">
        <%: Html.TextBox("width", string.Empty, new { @id="txtWidth", @class = "textbox required digits", @autocomplete = "off", @maxlength = "5", @style = "text-align:right; width:40px" })%> px
        </form>
        </div>
        <div class="propertyItem" id="propertyHeight">
        <form action="">
        <%: Html.TextBox("height", string.Empty, new { @id="txtHeight", @class = "textbox required digits", @autocomplete = "off", @maxlength = "5", @style = "text-align:right; width:40px" })%> px
        </form>
        </div>

        <div class="propertyItem" id="propertyFPP">
        <form action="">
        <%: Html.TextBox("height", "0.000", new { @id = "txtFPP", @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:40px" })%> %
        </form>
        </div>

        <div class="propertyItem" id="propertyBonusContribution">
        <form action="">
        <%: Html.TextBox("height", "0.000", new { @id = "txtBonusContribution", @class = "textbox required number", @autocomplete = "off", @maxlength = "12", @style = "text-align:right; width:40px" })%> %
        </form>
        </div>

        <div class="propertyItem" id="propertyPopularityCoefficient">
        <form action="">
        <%: Html.TextBox("height", "1.00", new { @id = "txtPopularityCoefficient", @class = "textbox required number", @autocomplete = "off", @maxlength = "6", @style = "text-align:right; width:40px" })%>
        </form>
        </div>

        <div class="propertyItem" id="propertyNewGame">
        <form action="">
        <%= Html.CheckBox("newGame", false, new { @id = "newGame" })%> <label for="newGame">Is New Game</label>
        <div class="newGameDatePicker" style="display:none;">
            <span>till</span> <input class="date-inputbox" type="text" id="newGameExpirationDateSub" name="newGameExpirationDateSub" />
        </div>
        </form>
        </div>

        <div class="propertyItem" id="propertyJackpotType">
        <form action="">
        <%: Html.DropDownList("jackpotType", GetJackpotTypeList(), new { @class = "ddl", @id = "ddlJackpotType" })%>
        </form>
        </div>

        <div class="propertyItem" id="propertyTags">
        <form action="">
        <div class="tags"></div>
        <%: Html.Hidden("Tags", string.Empty, new { @class = "textarea", @autocomplete = "off", @id = "hTags" })%>
        <%: Html.TextBox("newTag", string.Empty, new { @id = "txtTag", @class = "textbox", @autocomplete = "on", @maxlength = "20", @style = "width:150px" })%>
        <%: Html.DropDownList("tagsEditType", GetEditTypeList())%>
        </form>
        <script type="text/html" id="tag-template">
            <# var d=arguments[0]; #>
            <span class="tag" title="<#= d.htmlEncode() #>"><#= d.htmlEncode() #><a href="javascript:void(0)"><span onclick="removeTag(this)"></span></a></span>
        </script>
        <script type="text/javascript">
            function removeTag(el) {
                $(el).parents('span.tag').remove();
                syncTags();
            }

            function syncTags() {
                var tags = ',';
                var $tags = $("#propertyTags").find('div.tags span.tag');
                for (var i = 0; i < $tags.length; i++) {
                    tags = tags + $tags[i].title + ',';
                }
                $("#propertyTags").find('#hTags').val(tags);
            }

            $(function () {
                $("#propertyTags").find('#txtTag').keypress(function (e) {
                    if (e.keyCode == 13) {
                        e.preventDefault();
                        var newTag = $(this).val();
                        if (newTag == null)
                            return;
                        newTag = newTag.trim();
                        var regex = new RegExp("[^\\w]", "g");
                        newTag = newTag.replace(regex, "-");
                        if (newTag.length > 0) {
                            $($("#propertyTags").find('#tag-template').parseTemplate(newTag.toLowerCase())).appendTo('#propertyTags div.tags');
                            $(this).val('');
                            syncTags();
                        }
                    }
                });

            });
        </script>
        </div>
                
    </td>
    </tr>
    <tr>
    <td colspan="2">
        <br />
        <button id="submitPropertyEdit" type="button">Submit</button>
        <%if (DomainManager.CurrentDomainID != Constant.SystemDomainID) { %>
        <button id="backToDefault" type="button">Restore to default</button>
        <%} %>
        <form target="_blank" enctype="application/x-www-form-urlencoded" id="formPropertyEdit" action="<%= this.Url.ActionEx("UpdateProperty" ).SafeHtmlEncode() %>" method="post">
            <input type="hidden" name="ids" value="" />
            <input type="hidden" name="property" value="" />
            <input type="hidden" name="value" value="" />
            <input type="hidden" name="editType" value="" />
            <input type="hidden" name="setToDefault" value="false" />
        </form>
    </td>
    </tr>
</table>
</div>

<script type="text/javascript">
    $(function () {
        $("#edit_selected_games").find("#ddlProperties").change(function () {
            $(".propertyItem").hide();
            var property = $("#edit_selected_games #ddlProperties").val();
            var propertyItem = $("#property" + property);
            propertyItem.show();
            propertyItem.find("form").validate({ validateHidden: true });
            if (property == "Tags")
                syncTags();
        }).trigger("change");

        $("#submitPropertyEdit").button().click(function () {
            var $this = $(this);

            var property = $("#edit_selected_games #ddlProperties").val();

            var _form = $("#property" + property).find("form");
            if (!_form.valid()) {
                e.preventDefault();
                return false;
            }

            var callback = null;

            $this.attr('disabled', true);
            var value = null;
            switch (property) {
                case "Enabled":
                    value = $("#edit_selected_games #gameEnabled").attr("checked") == "checked";
                    break;
                case "License":
                    value = $("#edit_selected_games #ddlLisenceType").val();
                    break;
                case "Width":
                    value = $("#edit_selected_games #txtWidth").val();
                    break;
                case "Height":
                    value = $("#edit_selected_games #txtHeight").val();
                    break;
                case "FPP":
                    value = $("#edit_selected_games #txtFPP").val();
                    break;
                case "BonusContribution":
                    value = $("#edit_selected_games #txtBonusContribution").val();
                    break;
                case "PopularityCoefficient":
                    value = $("#edit_selected_games #txtPopularityCoefficient").val();
                    break;
                case "AnonymousFunMode":
                    value = $("#edit_selected_games #anonymousFunMode").attr("checked") == "checked" ? true : false;
                    break;
                case "FunMode":
                    value = $("#edit_selected_games #funMode").attr("checked") == "checked" ? true : false;
                    break;
                case "RealMode":
                    value = $("#edit_selected_games #realMode").attr("checked") == "checked" ? true : false;
                    break;
                case "NewGame":
                    value = $("#edit_selected_games #newGame").attr("checked") == "checked" ? true : false;

                    var property2 = "NewGameExpirationDate";
                    var value2 = $("#edit_selected_games #newGameExpirationDateSub").val();

                    callback = function (json) {
                        Post($this, property2, value2);
                    };
                    break;
                case "Tags":
                    value = $("#edit_selected_games #hTags").val().trim();
                    if (value == ",") value = "";
                    if (value == "") {
                        //                        if (!window.confirm("Are you sure you want to remove all tags?")) {
                        //                            $this.attr('disabled', false);
                        //                            return false;
                        //                        }
                        $this.attr('disabled', false);
                        return false;
                    }
                    break;
                case "OpVisible":
                    value = $("#edit_selected_games #OpVisible").attr("checked") == "checked" ? true : false;
                    break;
                case "JackpotType":
                    value = $("#edit_selected_games #ddlJackpotType").val();
                    break;
                case "ExcludeFromBonuses":
                    value = $("#edit_selected_games #excludeFromBonuses").attr("checked") == "checked" ? true : false;
                    break;
                case "ExcludeFromBonuses_EditableByOperator":
                    value = $("#edit_selected_games #excludeFromBonuses_EditableByOperator").attr("checked") == "checked" ? true : false;
                    break;
                case "SupportFreeSpinBonus":
                    value = $("#edit_selected_games #supportFreeSpinBonus").attr("checked") == "checked" ? true : false;
                    break;
                case "LaunchGameInHtml5":
                    value = $("#edit_selected_games #launchGameInHtml5").attr("checked") == "checked" ? true : false;
                    break;
                case "AgeLimit":
                    value = $("#edit_selected_games #ageLimit").attr("checked") == "checked" ? true : false;
                    break;
                default:
                    property = null;
                    break;
            }

            Post($this, property, value, false, callback);

            return false;
        });

        $("#backToDefault").button().click(function (evt) {
            evt.preventDefault();
            var $this = $(this);
            $this.attr('disabled', true);
            var property = $("#edit_selected_games #ddlProperties").val();
            if (property != null && property.trim() != "") {
                if (window.confirm("Are you sure you want to set the value to default setting?")) {
                    Post($this, property, null, true);
                }
            }
            $this.attr('disabled', false);
        });

        function Post(evtSource, property, value, setToDefault, callback) {
            if (property != null && (value != null || setToDefault != null)) {
                if (selected_game_ids != null && selected_game_ids.length != 0) {
                    var fun = (function (btn) {
                        return function () {
                            btn.attr('disabled', false);
                            var json = arguments[0];

                            if (callback) {
                                callback(json);
                            } else {
                                if (!json.success) {
                                    btn.attr('checked', !btn.is(':checked'));
                                    alert(json.error);
                                }
                                else {
                                    if (window.confirm("The operation has been completed successfully!\n Do you want to refresh the list?") == true)
                                        $('#btnFilter').trigger('click');
                                    $('#dlgEditGameProperty').dialog('close');
                                }
                            }
                        };
                    })(evtSource);

                    var options = { dataType: 'json', success: fun };
                    $('#formPropertyEdit input[name="ids"]').val(selected_game_ids);
                    $('#formPropertyEdit input[name="property"]').val(property);

                    if (value != null)
                        $('#formPropertyEdit input[name="value"]').val(value);

                    if (setToDefault != null && setToDefault)
                        $('#formPropertyEdit input[name="setToDefault"]').val("true");
                    else
                        $('#formPropertyEdit input[name="setToDefault"]').val("false");

                    if (property == "Tags") {
                        $('#formPropertyEdit input[name="editType"]').val($("#tagsEditType").val());
                    }
                    else
                        $('#formPropertyEdit input[name="editType"]').val("");
                    $("#formPropertyEdit").ajaxSubmit(options);
                }
            }
            else { evtSource.attr('disabled', false); alert('Error, invalid value!'); }
        }
    });

    function getDateString(date) {
        return date.getMonth() + 1 + "/" + date.getDate() + "/" + date.getFullYear();
    }

    $('#newGame').click(function() {
        $('.newGameDatePicker').toggle(this.checked);
        var _d = new Date();
        if (this.checked) {
            _d.setDate(_d.getDate() + <%: ViewData["newStatusCasinoGameExpirationDays"] %>);
        } else {
            _d.setDate(_d.getDate() - 1);
        }
        $('#newGameExpirationDateSub').val(getDateString(_d));
    });

    $('#newGameExpirationDateSub').attr("readonly", "readonly").datepicker({ minDate: 'today', showOn: "button", });

</script>