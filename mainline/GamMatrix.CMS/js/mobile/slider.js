CMS.mobile360.views.PromoSlider = function (settings) {
	this.el = $('#newSlider');
	this._isAnimating = false;
	this._canvasEl = $('#canvas');
	this._sliderListEl = $('#slidingList');
	this._currentSlideIndex = 0;
	this.TOTAL_SLIDES = 0;
	this.SLIDE_LENGTH = 460;
	this._attachEvents();
	this._screenSize();
	this.initialize(settings);

	var self = this;
	$(window).bind('resize', function () {
		self._screenSize();
	});
}

CMS.mobile360.views.PromoSlider.prototype = {
	events: {
		//'click #sliderMenu li a:not(".BackSlideLink, .ForwardSlideLink")': 'handleMenuSelectSlide',
		//'click li.SlideContainer:not(".ActiveSlide") a.SlideTrigger': 'handleSliderSelectSlide',

		// 'click #sliderMenu li.BackSlide a': 'handleMoveBack',
		//'click #sliderMenu li.ForwardSlide a': 'handleMoveForward',

		// dummy calls that prevent clicks on active slides
		'click #sliderMenu li.Active a,': 'handleDummyMenuSelect'
	},

	initialize: function (settings) {
		var self = this;
		if (settings) {
			if (settings.autoSlideTime > 0)
				setInterval(function () { self.handleMoveForward(); }, settings.autoSlideTime);
		}

		this._setTotalSlides();
	},

	changeSliderWidth: function (NewScreenSize) {
		$('#slidingList').css('width', NewScreenSize);
	},

	_screenSize: function () {
		var viewportwidth = '';
		if (typeof window.innerWidth != 'undefined')
			viewportwidth = window.innerWidth;
		else if (typeof document.documentElement != 'undefined' && typeof document.documentElement.clientWidth != 'undefined' && document.documentElement.clientWidth != 0)
			viewportwidth = document.documentElement.clientWidth;
		else
			viewportwidth = document.getElementsByTagName('body')[0].clientWidth;

		if (viewportwidth <= 500) {
			this.changeSliderWidth(viewportwidth);
			this.repositionSlider();
		} else {
			this.changeSliderWidth(this._getTotalSliderWidth() + 8);
			this.repositionSlider();
		}
	},

	_attachEvents: function () {
		var self = this;

		this.el.find('.NewSliderControls .NextLink').on('click', function (evt) {
			self.handleMoveForward(evt);
		});

		this.el.find('.NewSliderControls .PrevLink').on('click', function (evt) {
			self.handleMoveBack(evt);
		});
		this.el.find('.NewSliderControls .NumberLink').on('click', function (evt) {
			self.handleMenuSelectSlide(evt);
		});
		// this.el.find('.SlideList a.SlideLink').on('click', function(evt){
		//   self.handleSliderSelectSlide(evt);
		// });


	},

	_setTotalSlides: function () {
		// not sure if this dumb test is enough
		if (this.el.length) {
			// this._sliderListEl.css({ width: this._getTotalSliderWidth() });
			this.TOTAL_SLIDES = this._getTotalSliderLength();
			if (!this.TOTAL_SLIDES)
				this.el.addClass('Hidden');
		}
	},

	/**
	* Handlers
	*/

	/**
	* Slides forward one step
	*
	* @description tries to slide one step forward but stops
	* if reaches the end of the containing wrapper
	*/
	handleMoveForward: function (evt) {
		if (evt)
			evt.preventDefault();
		if (this._isAnimating)
			return;

		var scroll;
		if (this._currentSlideIndex < this.TOTAL_SLIDES - 1)
			scroll = this._getRemainingSlideOffset(this._currentSlideIndex += 1);
		else
			scroll = this._getRemainingSlideOffset(this._currentSlideIndex = 0);

		this._scrollTo(scroll);
	},

	handleMoveBack: function (evt) {
		if (evt)
			evt.preventDefault();
		if (this._isAnimating)
			return;

		if (this._currentSlideIndex > 0)
			scroll = this._getRemainingSlideOffset(this._currentSlideIndex -= 1);
		else
			scroll = this._getRemainingSlideOffset(this._currentSlideIndex = this.TOTAL_SLIDES - 1);

		this._scrollTo(scroll);
	},

	/**
	* Selects a slide by clicking on one of the dots
	* @param  {Object} evt jquery event object
	*/
	handleMenuSelectSlide: function (evt) {
		evt.preventDefault();
		var el = $(evt.currentTarget);
		if (this._isAnimating || el.parent().is('.CurrentNumber')) {
			return false;
		}
		var idx = this._currentSlideIndex = Number(this._getElementIndex(el, 'data-slideidx'));
		var scroll = this._getRemainingSlideOffset(idx);
		this._scrollTo(scroll);
	},

	/**
	* Selects a slide by clicking on one of the n.th slide containers
	* @param  {Object} evt jquery event object
	*/
	handleSliderSelectSlide: function (evt) {
		evt.preventDefault();
		var el = $(evt.currentTarget);
		if (this._isAnimating || el.parent().is('.ActiveItem'))
			return false;
		var idx = this._currentSlideIndex = Number(this._getElementIndex(el.parent(), 'id'));
		var scroll = this._getRemainingSlideOffset(idx);
		this._scrollTo(scroll);
	},

	/**
	* In case the slider scroll(internal overflow) modifies, the slider should recalculate it's bounds
	* and re-scroll to the necessary position
	*/
	repositionSlider: function () {
		var idx = this._currentSlideIndex;
		var scroll = this._getRemainingSlideOffset(idx);
		this._scrollTo(scroll);
	},

	/**
	* Metrics and various(elements) getters
	*/

	_getTotalSliderWidth: function () {
		return this._getOneSlideCssWidth() * this._getTotalSliderLength();
	},

	_getOneSlideCssWidth: function () {
		var slideLength = this._sliderListEl.find('li.SlideItem:first-child').width() + 6;
		//cl(slideLength)
		return slideLength || 0;
	},

	_getRemainingSlideOffset: function (slideIndex) {
		var oneSlideLength = this._getOneSlideCssWidth();
		var leftScroll = oneSlideLength * parseInt(slideIndex);
		var leftToSlide = oneSlideLength - slideIndex;
		var slideDiff = (leftToSlide * oneSlideLength) - this._getCanvasWidth();
		// dunno what this means :P
		if (slideDiff < oneSlideLength)
			leftScroll = leftScroll - (oneSlideLength - (slideDiff));
		return leftScroll;
	},

	_getElementIndex: function (el, refAttr) {
		return el.attr(refAttr).replace(/[^0-9]+/g, '');
	},

	_getTotalSliderLength: function () {
		return this._sliderListEl.find('li.SlideItem').length; // .length + 1;
	},

	_getCanvasWidth: function () {
		return this._canvasEl.innerWidth();
	},

	/**
	* Css manipulation
	*/

	_activateSlidersCss: function (idx) {
		//cl('_activateSlidersCss : ', idx)
		this._setSlidermenuActive(idx);
		this._setSlideElementActive(idx)
	},

	// aici selectezi itemurile din meniu
	_setSlidermenuActive: function (idx) {
		var $sliderMenu = this.el.find('#sliderMenu');
		$sliderMenu.find('li').removeClass('CurrentNumber').filter('#m-' + idx).addClass('CurrentNumber');
	},

	_setSlideElementActive: function (idx) {
		this._sliderListEl.find('li').removeClass('ActiveItem').filter('#s-' + idx).addClass('ActiveItem');
	},

	/**
	* Animations
	*/

	_scrollTo: function (scrollPos) {
		var self = this;
		this._isAnimating = true;
		// this.fire('scroll:slider');

		this._canvasEl.animate({
			// 'left': '-' + scrollPos
			'scrollLeft': scrollPos
		}, {
			duration: 120,
			// easing: 'easeInExpo',
			complete: function () {
				self._isAnimating = false;
				self._activateSlidersCss(self._currentSlideIndex);
			}
		});
	},

	/**
	* Dummies and event cancelers
	*/

	/**
	* Reacts on li.Active click therefore preventing calls on the active slide
	*/
	handleDummyMenuSelect: function (evt) {
		evt.preventDefault();
	}
};