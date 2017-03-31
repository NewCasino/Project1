(function ($) {
//Fields
	var itemsCount = 0;
	var settings = [];
//Constructor
	$.fn.smartSearch = function (method) {
	    var searchInput = $(this);

	    if (!searchInput.hasClass('smartSearch')) {
	        var searchWrapper = $("<div class='searchWrapper'></div>");
	        var searchIcon = $("<div class='searchIcon' />");

	        searchInput.wrap(searchWrapper);
	        searchInput.after(searchIcon);

	        searchInput.keyup(function () {
	            changeIconManageEventHandlers($(this), searchIcon);
	        });
	    }
	    
        if (methods[method]) {
            return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
        } else if (typeof method === 'object' || !method) {
            return methods.init.apply(this, arguments);
        } else {
            $.error('Method ' + method + ' does not exist on jQuery.smartSearch');
        }
    };
	
//Avaliable Methods
    var methods = {
        init: function (options) {
            initialize(this, options);
        },
        updateSearchItems: function (items) {
            updateSearchItems(this, items);
        }
        /*show: function () {
            this.show();
        },
        hide: function () {
            this.hide();
        }*/
    };
	
//Private Methods
	function initialize(items, options) {
	    $(items).each(function (index, item) {
	        
			settings[index] = $.extend({
				searchBox: item,
				items: null,
				itemsWithText: [],
				textToSearch: "",
				getSearchItemText: null,
				updateSearched: null,
				updateNotSearched: null,
				update: null,
				keyDown: null
			}, options);
				
			initializeSearchBox(settings[index]);
        });
	}

	function updateSearchItems(searchBox, items) {
	    var index = 0;
	    var setting = null;
	    while (true) {
	        if (settings[index].searchBox == searchBox[0]) {
	            settings[index].items = items;
	            settings[index].itemsWithText = [];

	            $(settings[index].items).each(function (ind, i) {
	                settings[index].itemsWithText.push({ item: i, text: settings[index].getSearchItemText(i) });
	            });
	            break;
	        }
	        index++;
	    }
	}
	
	function initializeSearchBox(setting) {
	    $(setting.items).each(function (ind, i) {
	        
	        setting.itemsWithText.push({ item: i, text: setting.getSearchItemText(i) });
	    });

		var item = $(setting.searchBox);
		
		item.addClass('smartSearch');
	
	    item.keyup(function () {
	        
			var searchResult = search(setting);

		    if (searchResult != null) {
		        if (setting.updateSearched != null) {
		            setting.updateSearched(searchResult.searchItems, searchResult.textToSearch);
		        }
		        if (setting.updateNotSearched != null) {
		            setting.updateNotSearched(searchResult.notSearchItems);
		        }
		        if (setting.update != null) {
		            setting.update();
		        }
		    }
		}).keydown(function (e) {
		    if (setting.keyDown != null) {
		        setting.keyDown(e);
		    }
		});
	}

	function changeIconManageEventHandlers(input, searchIcon) {
	    if (input.val() !== "") {
	        searchIcon.removeClass("searchIcon");
	        searchIcon.addClass("clearIcon");
	        searchIcon.click(function () {
	            input.val("");
	            input.focus();
	            input.keyup();
	        });
	    } else {
	        searchIcon.removeClass("clearIcon");
	        searchIcon.addClass("searchIcon");
	        searchIcon.unbind("click");
	    }
	    
    }
	
	function search(setting){
		var textToSearch = $(setting.searchBox).val().trim();

		if (textToSearch == setting.textToSearch) {
		    return null;
		}

	    

	    setting.textToSearch = textToSearch;

	    var result = { searchItems: [], notSearchItems: [], textToSearch: textToSearch };

		if (textToSearch.length == 0 || setting.getSearchItemText == null) {
		    result.searchItems = setting.items;
			
			return result;
		}
		
		var regExp = new RegExp(textToSearch, 'gi');
		
		$(setting.itemsWithText).each(function (index, item) {
		    if (item.text.match(regExp) != null) {
		        result.searchItems.push(item.item);
		    } else {
		        result.notSearchItems.push(item.item);
		    }
		});

		return result;
	}
})(jQuery);