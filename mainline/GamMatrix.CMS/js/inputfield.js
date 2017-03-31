if (!Array.prototype.indexOf) {
    Array.prototype.indexOf = function (obj, start) {
        for (var i = (start || 0), j = this.length; i < j; i++) {
            if (this[i] === obj) { return i; }
        }
        return -1;
    }
}

$.ajaxSetup({ cache: false });
jQuery.validator.addMethod(
        "custom",
        function (value, element, param) {
            var validator = this;

            try {
                if (typeof (param) != 'function') {
                    alert(param + ' is not a function');
                    return false;
                }
                var ret = param.call(value);
                setTimeout((function (r, validator, el) {
                    return function () {
                        if (r != true) {
                            var errors = {};
                            errors[el.name] = r;
                            validator.showErrors(errors);
                            return true;
                        }
                    };
                })(ret, this, element)
                , 0
                );
                return ret == true;
            }
            catch (e) {
                alert(e);
                throw e;
            }
        },
        ""
);

function ServerValidationHandler(object_settings, field, validator, element) {
    this.object_settings = object_settings;
    this.field = field;
    this.element = element;
    this.validator = validator;
    this.onResponse = function (json) {
        if (json != null) {
            if (json.value != $(this.element).val())
                return;
            $(this.element).parents('div.inputfield').removeClass('validating');
            var inputField = InputFields.fields[this.field.attr('id')];
            if (!json.success) {
                inputField.validated[this.element.name + '_' + json.value] = json.error;
                this.field.removeClass('correct').addClass("incorrect").removeClass('validating');
                var errors = {};
                errors[this.element.name] = json.error;
                validator.showErrors(errors);
                return false;
            } else {
                inputField.validated[this.element.name + '_' + json.value] = true;
                this.field.removeClass('incorrect').addClass("correct").removeClass('validating');
                inputField.hideTooltip();
                return true;
            }
        }
    };
};

jQuery.validator.addMethod("server", function (value, element, params) {
    var field = $(element).parents('div.inputfield');
    var inputField = InputFields.fields[field.attr('id')];
    var err = inputField.validated[element.name + '_' + value];
    var validator = this;

    if( err == null )
        field.addClass('validating');
    var data = {};
    data[$(element).attr("name")] = value;
    var options = {
        url: params.url,
        type: 'POST',
        data: data,
        dataType: 'json',
        success: (function (o, f, v, e) {
            return function () {
                (new ServerValidationHandler(o, f, v, e)).onResponse(arguments[0]);
            };
        })(this.settings, field, validator, element),
        error: function (r, textStatus, errorThrown) {

        }
    };
    $.ajax(options);
    if (err == true)
        return true;
    else
        return false;
}, '');


function InputField(selector) {
    this.field = $(selector);
    this.field.data('InputField', this);
    this.validated = {};
    this.validator = null;

    this.showIndicator = function (show) {
        $('div.inputfield_Container div.inputfield_Table div.indicator div', this.field).css('visibility', show ? 'visible' : 'hidden');
    };

    this.showError = function (msg) {
        $('div.inputfield_Error', this.field).text(msg);
    };

    this.getTooltip = function () {
        var tooltip = $('div.bubbletip[elementId="' + this.field.attr('id') + '"]');
        if (tooltip.length > 0)
            return tooltip;
        return $('div.inputfield_Error', this.field);
    };

    this.showTooltip = function (msg) {
        var icon = this.field.find('.inputfield_Container .inputfield_Table .indicator div');
        var $pos = icon.position();
        if ($(document.body).attr('dir') != 'rtl') {
            this.getTooltip().css('left', $pos.left + icon.outerWidth(true)).css('top', $pos.top).show();
        } else {
            this.getTooltip().css('right', this.field.parents('form').outerWidth(true) - $pos.left).css('top', $pos.top).show();
        }
    };

    this.hideTooltip = function () {
        this.getTooltip().hide();
        return this;
    };

    this.clearError = function () {
        this.field.removeClass('incorrect').removeClass('correct');
        return this;
    };

    this.onFocus = function () {
    };

    this.init = function () {
        this.searchChildren(this.field.find('.inputfield_Container .inputfield_Table .controls'));
    };

    this.searchChildren = function ($parent) {
        var $children = $parent.children();
        for (var $i = 0; $i < $children.length; $i++) {
            $child = $($children[$i]);
            if ($child[0].tagName.toLowerCase() == 'input') {
                $child.bind('focus', this, function (e) { e.data.onFocus(); });
                switch ($child.attr('type')) {
                    case "text":
                    case "password":
                        {
                            $child.addClass(($child.attr('type') == 'text') ? 'textbox' : 'password');
                            if ($child.attr('validator') != null) {
                                $child.bind('blur', this, function (evt) {
                                    if ($(this).val() != '' && evt.data.validator != null) {
                                        var field = InputFields.fields[$(this).parents('div.inputfield').attr('id')];
                                        if (field != null)
                                            field.hideTooltip();
                                        $(this).parents('div.inputfield').removeClass('correct').removeClass("incorrect").removeClass('validating');
                                        evt.data.validator.element($(this));
                                    }
                                }
                            );
                            };
                            $child.attr('autocomplete', 'off');
                            continue;
                        }
                    case "checkbox":
                        {
                            $child.change(function () {
                                $(this).parents("form").validate().element($(this));
                            }) ;
                            continue;
                        }
                    case "file": continue;
                }
            } else if ($child[0].tagName.toLowerCase() == 'select') {
                $child.bind('focus', this, function (e) { e.data.onFocus(); });
                $child.addClass('select');
                continue;
            } else if ($child[0].tagName.toLowerCase() == 'textarea') {
                $child.bind('focus', this, function (e) { e.data.onFocus(); });
                $child.addClass('textarea'); $child.attr('autocomplete', 'off');
                continue;
            }
            this.searchChildren($child);
        }
    };

    this.init();
}

InputFields = {
    fields: [],
    initialize: function ($form) {
        var $fields = $('div.inputfield', $form);

        $.metadata.setType("attr", "validator");
        var validator = $form.validate({
            showErrors: InputFields.onShowErrors,
            success: InputFields.onSuccess,
            errorPlacement: InputFields.onErrorPlacement
        });

        for (var i = 0; i < $fields.length; i++) {
            if ($($fields[i]).hasClass('__inited'))
                continue;
            var $f = new InputField($fields[i]);
            $f.validator = validator;
            InputFields.fields[$($fields[i]).attr('id')] = $f;
            $($fields[i]).addClass('__inited');
        }
        return validator;
    },


    onSuccess: function ($label) {
        var inputField = $('#' + $label.attr('elementId'));
        inputField.removeClass('incorrect').addClass("correct");
        var field = InputFields.fields[inputField.attr('id')];
        if (field) {
            field.hideTooltip();
        }
    },

    onShowErrors: function (errorMap, errorList) {
        for (var i = 0; i < errorList.length; i++) {
            var fieldID = $(errorList[i].element).parents("div.inputfield").removeClass('correct').addClass("incorrect").attr('id');
            var field = InputFields.fields[fieldID];
            if (field) {
                field.showTooltip(errorList[i].message);
            }
        }
        this.defaultShowErrors();
    },

    onErrorPlacement: function (error, element) {
        error.attr('elementId', $(element).parents("div.inputfield").attr('id'));
        if ($(element).attr('validator') == null)
        return;
        var container = $('div.inputfield_Error', $(element).parents("div.inputfield"));
        if (container.length == 0) {
        var field = InputFields.fields[$(element).parents("div.inputfield").attr('id')];
        container = $('div.inputfield_Error', field.getTooltip());
        }
        error.appendTo(container);
    }
};



$.fn.extend({
    toggleLoadingSpin: function (enable) {
        if (enable != true && enable != false)
            enable = !$(this).hasClass('loading_Spin');
        if (enable) {
            $(this).addClass('loading_Spin');
            $('<div id="loading_block_all" class="loading_block_all" style="position:fixed;left:0px;top:0px;width:100%;height:100%;background-color:black;filter: alpha(opacity=10);-moz-opacity:0.1;opacity: 0.1;z-index:99999999;"></div>').appendTo(document.body);
        }
        else {
            $(this).removeClass('loading_Spin');
            setTimeout(function () { $('#loading_block_all').remove(); }, 30);
            $('#loading_block_all').remove();
        }
        return $(this);
    },

    initializeForm: function () {
        var $name = $(this)[0].tagName.toLowerCase();
        if ($name == 'form') {
            $(this).data('validator', InputFields.initialize($(this)));
        }
        return $(this);
    },

    //----------------- selectable table ------------------------------

    initilizeSelectableTable: function (onchange) {
        $('tr', this).bind('click', { fun: onchange, table: $(this) }, function (e) {
            $(this).siblings().removeClass('selected');
            $(this).addClass('selected');
            var val = $(this).attr('key');
            e.data.table.setSelectableTableValue(val);
        });
        $(this).bind('SELECTION_CHANGE', { fun: onchange, table: $(this) }, function (e) {
            var val = $('#' + e.data.table.attr('elementId')).val();
            e.data.fun(val, e.data.table.getSelectableTableData()[val]);
        });

        var val = $('#' + $(this).attr('elementId')).val();
        if (val != null && val.length > 0)
            $(this).setSelectableTableValue(val);
        return $(this);
    },

    setSelectableTableValue: function (val) {
        var $table = $(this);
        var $name = $(this)[0].tagName.toLowerCase();
        if ($name != 'table') {
            $table = $(this).parents('table');
        }
        $('tr', $table).removeClass('selected');
        $('tr[key="' + val.scriptEncode() + '"]', $table).addClass('selected');
        $('#' + $table.attr('elementId')).val(val);

        $table.trigger('SELECTION_CHANGE');
    },

    removeSelection: function () {
        var $table = $(this);
        var $name = $(this)[0].tagName.toLowerCase();
        if ($name != 'table') {
            $table = $(this).parents('table');
        }
        $('tr', $table).removeClass('selected');
        $('#' + $table.attr('elementId')).val('');
    },

    getSelectableTableValueField: function () {
        var $table = $(this);
        var $name = $(this)[0].tagName.toLowerCase();
        if ($name != 'table') {
            $table = $(this).parents('table');
        }
        var $tr = $('tr.selected', $table);
        if ($tr.length == 0) return null;
        return $tr.attr('key');
    },

    getSelectableTableData: function () {
        var $id = $(this).attr('id');
        var $name = $(this)[0].tagName.toLowerCase();
        if ($name != 'table') {
            $id = $(this).parents('table').attr('id');
        }
        return self.tableData[$id];
    },

    //----------------- Textbox ------------------------------
    initializeTextbox: function () {
        __initializeAllTextbox();
    },

    allowNumberOnly: function () {
        $(this).keypress(function (e) {
            if (e.which >= 48 && e.which <= 57) {
            }
            else if (e.which == 0 || e.which == 8) {
            }
            else
                e.preventDefault();
        });
        $(this).change(function (e) {
            $(this).val($(this).val().replace(/[^\d]/g, ''));
        });
    },

    //----------------- Navigation Menu ------------------------------
    initilizeNavigationMenu: function (menuType) {
        switch (menuType) {
            case 'sidemenu':
                $(this).initilizeSideMenu();
                break;
        }
    },

    initilizeSideMenu: function () {
        var objs = $('li > span > a', $(this));
        for (var i = 0; i < objs.length; i++) {
            var link = $(objs[i]);
            var li = link.parent('span').parent('li');
            var href = link.attr('href');
            var hasUrl = (href != null) && (href != '#') && (href != 'javascript:void(0)');
            var childrenWrapper = $('div.children', li);
            if (childrenWrapper.length > 0) {
                if (hasUrl)
                    childrenWrapper.removeClass('collapsed');
                else {
                    link.click(function (e) {
                        $('div.children', $(this).parent('span').parent('li')).toggleClass('collapsed');
                    });
                }
            }
        }
    },

    //----------------- Tab ------------------------------
    selectTab: function (id) {
        var tab = $('ul.tabs > li.tab[forid="' + id + '"]', $(this));
        if (tab.length == 0) return false;
        tab.siblings('li').removeClass('selected');
        tab.addClass('selected');
        $('div.tabbody', $(this)).hide();
        $(('#' + id), $(this)).show();
        return tab;
    },

    showTab: function (id, show) {
        var tab = $('ul.tabs > li.tab[forid="' + id + '"]', $(this));
        if (show == true)
            tab.show();
        else
            tab.hide();
    },

    getSelectedTabID: function () {
        var tab = $('ul.tabs > li.selected', $(this));
        return tab.attr('id');
    }
});


/////// wartermark ///////

function __initializeAllTextbox() {
    var textboxes = $('input.textboxex_wartermark');
    for (var i = 0; i < textboxes.length; i++) {
        var target = $(textboxes[i]).prev();
        if (target.get(0).tagName.toLowerCase() != "input")
            continue;
        if (target.attr('__init') == '1')
            continue;
        target.attr('__init', '1');

        $(textboxes[i]).removeAttr('__init').width(target.width());
        target.blur(function (e) {
            if ($(this).val() == '' || $(this).val() == null) {
                $(this).hide();
                $(this).next().show();
            }
        });
        $(textboxes[i]).focus(function (e) {
            $(this).hide();
            $(this).prev().show().focus();
        });
        target.blur();
    }
}
$(__initializeAllTextbox);


/////// tabbed Panel ///////
function __initializeTabbedContent(container) {
    var tabs = $('ul.tabs > li.tab', container);

    for (var i = 0; i < tabs.length; i++) {
        var tab = $(tabs[i]);
        var tbody = $(document.getElementById(tab.attr('forid')));
        if (!tab.hasClass('selected'))
            tbody.hide();
        $('a', tab).bind('click', { t: tab, b: tbody, c: container }, function (e) {
            e.preventDefault();
            e.data.t.siblings('li').removeClass('selected');
            $(this).parents('li').addClass('selected');
            e.data.b.siblings('div').hide();
            e.data.b.show();
        });
    }
}