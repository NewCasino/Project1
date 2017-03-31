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

function ServerValidationHandler(validator, element) {
    this.element = element;
    this.validator = validator;
    this.onResponse = function (json) {
    	if (json != null) {
    		if (json.value != $(this.element).val())
    			return;
    		var $formItem = $(this.element).parents('.FormItem');
    		$formItem.data('validated_' + json.value, json.success);
    		if (!json.success) {
    			$formItem.removeClass('Validating').removeClass('OK').addClass('Error');
    			var errors = {};
    			errors[this.element.name] = json.error;
    			validator.showErrors(errors);
    			return false;
    		} else {
    			$formItem.addClass('OK');
    			return true;
    		}
    	}
    };
};

jQuery.validator.addMethod("server", function (value, element, params) {
	var $formItem = $(element).parents('.FormItem');
	
	if ($formItem.data('last_value') == value)
		return 'pending';
	$formItem.data('last_value', value);

	$formItem.addClass('Validating').removeClass('OK').removeClass('Error');
	var v = $formItem.data('validated_' + value);
	var validator = this;

	var data = {};
	data[$(element).attr("name")] = value;
	var options = {
		url: params.url,
		type: 'POST',
		data: data,
		dataType: 'json',
		success: (function (v, e) {
			return function () {
				(new ServerValidationHandler(v, e)).onResponse(arguments[0]);
			};
		})(validator, element),
		error: function (r, textStatus, errorThrown) {
			//alert(textStatus);
		}
	};
	$.ajaxSetup({ cache: false });
	$.ajax(options);
	return (v === null) ? "pending" : v;
}, '');

$.fn.extend({
	initializeForm: function () {
		$.validator.setDefaults({ ignore: [] });

		var options = {
			invalidHandler: function () {  },
			errorPlacement: function (error, element) {
				var $formItem = element.parents('.FormItem');
				$('.FormHelp', $formItem).empty().append(error);
				if (!$formItem.hasClass('Validating'))
					$formItem.removeClass('OK').addClass('Error');
			},
			success: function (label) {
				var $formItem = label.parents('.FormItem');
				label.remove();
				if (!$formItem.hasClass('Validating'))
					$formItem.removeClass('Error').addClass('OK');
			}
		};
		var messages = {};
		var rules = {};
		var $inputs = $('input[data-validator], select[data-validator], textarea[data-validator]', $(this));
		for (var i = 0; i < $inputs.length; i++) {
			var $input = $inputs.eq(i);
			var d = $input.data('validator');
			var obj = eval('(' + d + ')');
			var name = $input.attr('name');

			messages[name] = obj.messages;
			delete obj.messages;
			rules[name] = obj;
		}
		options.messages = messages;
		options.rules = rules;
		$(this).validate(options);
	},

	clearFormErrors: function () {
		var $li = $('li.Error.FormItem', $(this));
		$li.removeClass('Error');
		$('span.FormHelp label.error', $li).remove();
		return $(this);
	}
});


