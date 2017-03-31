'use strict';

var CMS = {};

CMS.utils = {};
CMS.views = {};

CMS.mobile360 = {};
CMS.mobile360.views = {};



(function ($) {
	//------------------------ cms utils -----------------------//
	var cmsUtils = CMS.utils;

	cmsUtils.Debug = (function(){
		var consoleEnabled = true, htmlEnabled = false;
		var debugBox;

		function debugConsole(type, message){
			console[type.toLowerCase()](message);
		}

		function debugHtml(type, message){
			if (!debugBox)
				debugBox = $('<div class="DebugBox" id="debugBox" />').prependTo($('body'));
			
			$('<span />')
				.addClass('DebugMessage Debug' + type)
				.data('time', Math.round(+new Date() / 1000))
				.text(message)
				.prependTo(debugBox);
		}

		function debugOutput(type, message){
			if (consoleEnabled)
				debugConsole(type, message);
			if (htmlEnabled)
				debugHtml(type, message);
		}

		return{
			l: function(message){ debugOutput('Log', message); },
			d: function(message){ debugOutput('Debug', message); },
			e: function(message){ debugOutput('Error', message); },
			w: function(message){ debugOutput('Warn', message); },
			i: function(message){ debugOutput('Info', message); },

			toHtml: function(value) { htmlEnabled = value },
			toConsole: function(value) { consoleEnabled = value }
		}
	})();

	cmsUtils.Format = (function () {
		function formatAmount(value) {
			return formatNumber(value, 2, true);
		}

		function formatNumber(value, decimals, commaSplit) {
			var parts = (Math.abs(value) || 0).toString().split('.'),
				intPart = parts[0],
				fractPart = parts[1] || '';

			if (fractPart.length > decimals)
				return formatNumber(trimToDecimals(value, decimals, true), decimals, commaSplit);

			if (commaSplit) {
				var temp = '';
				while (intPart.length > 3) {
					var position = intPart.length - 3;
					temp = ',' + intPart.substring(position) + temp;
					intPart = intPart.substring(0, position);
				}
				intPart = intPart + temp;
			}
			if (decimals) {
				while (fractPart.length < decimals)
					fractPart += '0';
				fractPart = '.' + fractPart;
			}

			return (value < 0 ? '-' : '') + intPart + fractPart;
		}

		function trimToDecimals(value, decimals, round) {
			var trim = round ? Math.round : (value < 0 ? Math.ceil : Math.floor),
				power = Math.pow(10, decimals);

			return trim(value * power) / power;
		}

		return {
			amount: formatAmount,
			number: formatNumber
		}
	})();

	cmsUtils.Analytics = (function(){
		window._gaq = window._gaq || [];

		var clientTracker;

		function init(settings){
			var gaq = window._gaq;
			gaq.push(['_setAccount', settings.gid]);

			if (settings.cid){
				clientTracker = settings.c;
				gaq.push([clientTracker + '._setAccount', settings.cid]);
			}

			queue('_setCustomVar', 1, 'Client', settings.c);
			queue('_setCustomVar', 2, 'User Type', settings.u);
			queue('_setCustomVar', 3, 'Product', settings.p);
			queue('_setCustomVar', 4, 'Language', settings.l);

			push(['_setSiteSpeedSampleRate', 5], ['_trackPageview']);

			var ga = document.createElement('script'); 
			ga.type = 'text/javascript'; 
			ga.async = true;
			ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
			var s = document.getElementsByTagName('script')[0]; 
			s.parentNode.insertBefore(ga, s);
		}

		function queue(methodCall){
			var gaq = window._gaq;

			gaq.push(Array.prototype.slice.call(arguments));
			if (clientTracker)
				gaq.push([clientTracker + '.' + methodCall].concat(Array.prototype.slice.call(arguments, 1)));
				
			return this;
		}

		function push(){
			for (var i = 0; i < arguments.length; i++)
				queue.apply(this, arguments[i]);
		}

		function event(category, action, opt_label, opt_value, opt_noninteraction){
			queue('_trackEvent', category, action, opt_label, opt_value, opt_noninteraction);
		}

		return {
			init: init,
			q: queue,
			p: push,
			evt: event
		}
	})();

	cmsUtils.Dispatcher = function(){
		var bindings = {};

		function bindEvent(name, handler){
			unbindEvent(name, handler);

			var handlers = bindings[name];
			if (!handlers)
				handlers = bindings[name] = [];
			handlers.push(handler);
			
			return this;
		}

		function unbindEvent(name, handler){
			var handlers = bindings[name];
			if (!handlers) return this;

			var index = $.inArray(handler, handlers)
			if (index != -1)
				handlers.splice(index, 1);
			if (!handlers.length)
				delete bindings[name];

			return this;
		}

		function triggerEvent(name, data){
			var handlers = bindings[name];
			if (!handlers) return this;

			for (var i = 0; i < handlers.length; i++)
				handlers[i](data);

			return this;
		}

		return{
			bind: bindEvent,
			unbind: unbindEvent,
			trigger: triggerEvent
		}
	}

	cmsUtils.StorageWrapper = function(storage){
		storage = storage || {};

		function set(key, value) {
			if (storage.setItem)
				storage.setItem(key, value);
		}

		function get(key) {
			if (storage.getItem)
				return storage.getItem(key);
		}

		function rem(key) {
			if (storage.removeItem)
				storage.removeItem(key);
		}

		return {
			setItem: set,
			getItem: get,
			removeItem: rem
		}
	}

	cmsUtils.AppLinks = function (){
		function add(element){
			if (window.standalone){
				$(element).click(function(){
					window.location = this.href;
					return false;
				});
			}
		}

		return {
			add: add
		}
	}

	//------------------------ /cms utils -----------------------//



	//------------------------ cms views -----------------------//
	var cmsViews = CMS.views;
	cmsViews.DataList = function(domSelector, activeClass){
		var dispatcher = new CMS.utils.Dispatcher();
		var current;
		activeClass = activeClass || 'Active';

		function deselect(){
			if (!current)
				return;

			current.removeClass(activeClass)
					.find('a:first')
						.bind('click', onLinkClick)
			current = null;
		}

		function select(element){
				deselect();
				 
				element.addClass(activeClass)
					.find('a:first')
						.unbind('click', onLinkClick);
				current = element;
		}

		function selectByIndex(index){
			select($('li:eq(' + index + ')', domSelector));
			return getData();
		}

		function getData(){
			return current ? current.data() : null;
		}

		function onLinkClick(){
			var element = $(this).parents('li');
			select(element);

			dispatcher.trigger('select', getData());
		}
			
		$('>li', domSelector).find('a:first').click(onLinkClick);

		return{
			evt: dispatcher,
			select: selectByIndex,
			deselect: deselect,
			data: getData
		}
	};

	cmsViews.RestrictedInput = function (selector, restriction) {
		var whitelist = restriction.whitelist,
			chars = restriction.chars;

		var regex = (function () {
			var hex = '';
			for (var i = 0; i < chars.length; i++)
				hex += '\\x' + chars.charCodeAt(i).toString(16);

			var rules = (whitelist ? '[^' : '[') + hex + ']';
			return new RegExp(rules, 'g');
		})();

		var input = $(selector)
			.keypress(function(event){
				var code = event.which,
					character = String.fromCharCode(code),
					found = chars.indexOf(character) != -1;
				
				if ((found && !whitelist)
					|| (whitelist && !found && (code != 0 && code != 8)))
					return false;
			})
			.change(function () {
				input.val(input.val().replace(regex, ''));
			});
	}
	cmsViews.RestrictedInput.username = {
		whitelist: false,
		chars: '\x22\x27~`!@#$%^&*()_+-={}|[]\:;<>?,./'
	};
	cmsViews.RestrictedInput.digits = {
		whitelist: true,
		chars: '0123456789'
	};
	cmsViews.RestrictedInput.amount = {
		whitelist: true,
		chars: '0123456789.'
	};

	cmsViews.AmountInput = function (selector) {
		new cmsViews.RestrictedInput(selector, cmsViews.RestrictedInput.amount);

		var input = $(selector)
			.focus(function(){
				input.val(amountVal() || '');
			})
			.blur(function(){
				amountVal(input.val());
			});

		function amountVal(value) {
			if (value === undefined)
				return parseFloat(input.val() || 0);
			return input.val(cmsUtils.Format.number(value, 2));
		}

		return {
			val: amountVal
		}
	}

	cmsViews.BackBtn = function(selector){
		$(selector).click(function () {
			if (window.navigator.standalone)
				window.location = document.referrer;
			else
				history.back();
			return false;
		});
	}

	//------------------------ /cms views ----------------------//
})(jQuery);