	// Copyright (c) 2009 Bram Wijnands
//                                                                     
// Permission is hereby granted, free of charge, to any person         
// obtaining a copy of this software and associated documentation      
// files (the "Software"), to deal in the Software without             
// restriction, including without limitation the rights to use,        
// copy, modify, merge, publish, distribute, sublicense, and/or sell   
// copies of the Software, and to permit persons to whom the           
// Software is furnished to do so, subject to the following      
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


// flash_message shows a message div above the given element, much like a rails flash message
// 
// flash_message takes atleast 2 paramaters; The title and message of the "report"
// the suffix can be left blank but only one report of each suffix may be created
//
(function($){  // Flash Message
	var timeout 			= null;
	var js_report_styles	= {top: 0, position: "absolute"};
	
	// Calculate the css properties by adding and removing a element with the given js_reports class. (only do this once!)
	$(function(){
		$e = $("body").children(":last").after("<div class='js_report'></div>").next();
		js_report_styles.top  		= $e.css("top");
		js_report_styles.position  	= $e.css("position");
		$e.remove();		
	})
	
	$.fn.flash_message = function(title, message, suffix, options) {	
		var options = $.extend( {
		  direction			: "up",
		  effect			: "slide",
		  show_for 			: 5000,
		  duration_modifier	: 0.5,			// Effect duration modifer (duration*modifier). close effect onClick
		  duration 			: 1000
		},options);
	
		cleaner(options);
		suffix 	= (suffix) ? suffix.toLowerCase() : "notice";
		self	= $(this);
		ex 		= parseInt((new Date().getTime()))+options.show_for;
		
		// Calculate the position
		var y = parseInt(js_report_styles.top);
		if((cur_size = $(".js_report").size()) > 0) {
			$e 	= $(".js_report:last");
			top = (parseInt($e.css("top")) < 0) 
							? ((Math.round(parseInt($e.css("top"))/y)+1)*y)
							: parseInt($e.css("top"))		
			y 	= top + parseInt(parseInt($e.height()) + parseInt($e.css("margin-top")) + parseInt($e.css("margin-bottom")));
		}

		self
			.before("<div expires='"+ex+"' class='js_report "+suffix+"'><span class='close_report'></span><b>"+title+"</b><br />Results:<br /><span class='result'>"+message+"</span></div>")
			.prev()
			.css("top", y)
			.find(".close_report")
				.click(function(){ 
					$(this).parents(".js_report")
						.hide(options.effect, 
							  {direction: options.direction}, 
							  options.duration*options.duration_modifier, 
							  function() {
								$(this).remove();
							  }
					);
				});
				
		return self.prev().show(options.effect, { direction: options.direction }, options.duration);
	}
	
	// Interval, clean up the expired messages.
	function cleaner(options) {
		if(timeout) return;
		
		timeout = window.setInterval(function() {
			$('.js_report').each(function() { 
				if($(this).attr("expires")<=(new Date().getTime())) {
					 $(this)
						.hide(options.effect,
						   {direction: options.direction}, 
							options.duration,
							function() {
								$(this).remove();
							 }
						);		
				}
			});
		}, 1000);
	}
})(jQuery);

(function($){  // Live Search
 var limit_request_timer = null;
 var remove_result_timer = null;
 var selected 			 = null;

  // Add some handlers to the given element
  $.fn.is_search_box = function(options) {
	limit_request_timer = null;
	remove_result_timer = null;
	selected 			= null;	
	
	var self 	= $(this);
	var options = $.extend( {
		url			: location.href,
		min_length	: 1,
		close_timer	: 750,
		search_timer: 250
	}, options);
	
	return self	 	
		.val("Search..")
		.focus(function(){
			if(self.val()=="Search..") self.val("");		
			if(remove_result_timer) window.clearTimeout(remove_result_timer);
			
			if(self.val().length>=options.min_length) {
				$.get(options.url+"", {query: self.val()}, function(data) { show_search_results(self, data); });		
			}
		})
		.blur(function(){
			self = $(this);
			if(self.val()=="") self.val("Search..");	
			
			remove_result_timer = window.setTimeout(function(){
				 self.nextAll("div.search_results").remove();
			}, options.close_timer);
		})
		.keypress(function(e){
			self 	= $(this);
			if(e.keyCode == 38 || e.keyCode == 40)	return navigate(self, e);  	// Next on arrow down/up
			if(e.keyCode == 13 && selected)			return go(self, e);			// goto href=URL on enter
			if(e.keyCode == 27)						return close(self);			// close on esc
									
			if(self.val().length>=1) {				
				if(limit_request_timer) window.clearTimeout(limit_request_timer);
				limit_request_timer = window.setTimeout(function(){
					$.get(options.url+"", {query: self.val()}, function(data) { show_search_results(self, data); });
				}, options.search_timer);
			} else {
				remove_result_timer = window.setTimeout(function(){
					 self.nextAll("div.search_results").remove();
				}, options.close_timer);
			}
			if(e.keyCode == 38 || e.keyCode == 40) return false;	
		});
	}
	
	function close($input) {
		if(limit_request_timer) window.clearTimeout(limit_request_timer);
		$input
			.val("Search..")
			.blur()
			.nextAll("div.search_results").remove();
		
		selected = null;
		return false;
	}	
	// Navigate with the arrow keys
	function navigate($input, event) {
		var direction  	= (event.keyCode==40) //#  \/ => 40   /\ => 38
		var $targets 	= $input.next(".search_results").find("ul li, ul ul li, ul ul ul li");
		
		if (selected==null) {
				selected = (direction) ? 0: $targets.size()-1;
		} else {
			cur_size = $targets.size();
			$targets.eq(selected).removeClass("active");
			selected = (direction) 
							? (selected<(cur_size-1)) ? selected+1 : 0 
							: (selected>0) ? selected-1 : cur_size-1;
		}
		
		$targets.eq(selected).addClass("active");
		return false;
	}
	
	// go to the selected element
	function go($input, event) {
		window.location.href = $input.next(".search_results").find("ul li, ul ul li, ul ul ul li").eq(selected).attr("href");
	}
	
	// Nice jQuery chain which deletes previous results, adds a new resultcontainer, inserts the responeText and alters this so the li's are clickable.
	function show_search_results($input, data) {
		$input
		 .nextAll("div.search_results")
		  .remove()
		 .end()
		 .after("<div class='ui-helper-reset ui-widget-content search_results' id='search_results'></div>")
		 .next()
		 .html(data)
		 .find("ul li, ul ul li, ul ul ul li")
		  .click(function() {
			window.location.href = $(this).attr("href") || "#";
		});
	}
})(jQuery);

(function($){
	$(function(){
		$('.window .close').click(function(){ hide_mondal(); });
		$('#mask').click(function(){ hide_mondal(); });
		
		$(window).keydown(function(e){
			if(e.keyCode==27) hide_mondal();
		});
	});
	
	function hide_mondal() {
		$('#mask').fadeOut("fast");
		$('.window').hide();
	}
})(jQuery);