'use strict';

(function ($) {
	var m360 = CMS.mobile360;

	//------------------- mobile views ---------------------//
	var mobileViews = m360.views;
	mobileViews.Form = function(selector){
		var form = $(selector || 'form');

		form.attr('novalidate', 'novalidate');
		form.initializeForm();
	};

	mobileViews.ToggleContent = function (domSelector){
		var signField = $('.ToggleArrow', domSelector);
		var content = $('.ToggleContent', domSelector);
			
		$('.ToggleButton', domSelector).click(function(){
			var close = !(content.css('display') == 'none');
			
			if (close)
				content.hide();
			else
				content.show();

			signField.html(close ? '&plus;' : '&minus;');
		});
	};

	mobileViews.ToggleContent.createFor = function(selector, context){ //static
		var instances = [];
		$(selector, context).each(function(index, element){
			instances.push(new mobileViews.ToggleContent(element));
		});
		return instances;
	};

	mobileViews.NavMenu = function(settings, dispatcher){
		var mainMenu = settings.men, 
			menuParent = settings.prt,
			menuButton = settings.mbt,
			additional = settings.abt,
			sessionId = settings.sid, 
			positioner = settings.pos;
		var loading, open;
		
		menuButton.click(toggleClickHandler);
		$(additional).click(toggleClickHandler);

		function toggleClickHandler(){
			if (loading === 2)
				toggleMenu();
			else 
				loadMenu();

			return false;
		}

		function loadMenu(){
			if (loading === 1)
				return;

			$.ajax({
				url: menuButton.attr('href') + menuButton.data('action') + '?_sid=' + sessionId,
				dataType: "html",
				success: onMenuReceived,
				error: function (jqXHR, textStatus, errorThrown) { menuError(errorThrown); }
			});

			loading = 1;
		}

		function toggleMenu(state){
			if (state === undefined)
				state = !open;
			open = state;
				
			if (state){
				mainMenu.slideDown();
				menuParent.addClass('OpenMenu');
			} else {
				mainMenu.slideUp();
				menuParent.removeClass('OpenMenu');
			}

			dispatcher.trigger('toggle', state);
		}

		function onMenuReceived(data) {
			try {
				$('.MenuData', mainMenu).append($(data));
			} catch (error) {
				return menuError(error);
			}

			$('.Close', mainMenu).click(toggleClickHandler);

			loading = 2;
			dispatcher.trigger('loaded', data);

			toggleMenu(true);
			if (positioner) 
				setTimeout(positioner.calc, 500);
		}

		function menuError(error) {
			console.error('menu error', error);
			self.location = menuButton.attr('href');
		}

		return {
			evt: dispatcher,
			toggle: toggleMenu
		}
	}

	mobileViews.NavPos = function(settings){
		var container = settings.elm,
			offset = settings.ofs || 0;

		function calculate(){
			var viewHeight = $(window).height() - offset,
				elementHeight = 0;

			container.children().each(function(){
				elementHeight += $(this).height();
			});
			
			if (elementHeight > viewHeight)
				container.css({height: viewHeight + 'px'});
			else
				container.css({height: 'auto'});
		}

		container.css('overflow', 'auto');
		$(window).resize(calculate);

		return {
			calc: calculate
		}
	}

	mobileViews.LangSelect = function (selector, initial) {
		var form = selector.closest('form'),
			language = initial ? initial : selector.find(':selected').val();

		selector.change(function () {
			var action = form.attr('action');

			var index = action.indexOf(language);
			if (index != -1)
				action = action.substr(index + language.length);

			language = $(this).val();
			form.attr('action', '/' + language + action);
		});

		return {
			lang: function () { return language; }
		}
	}
	//------------------- /mobile views ---------------------//



	//------------------- mobile generic ---------------------//
	m360.Generic = (function(){
		function init(){
			$('a[href="#"]').click(function(){
				return false;
			});
		}
		
		function input(){
			init();
			new mobileViews.Form();
		}

		window.log360 = CMS.utils.Debug;
		window.cmsGA = CMS.utils.Analytics;

		return {
			init: init,
			input: input
		}
	})();
	//------------------- /mobile generic --------------------//
})(jQuery);

