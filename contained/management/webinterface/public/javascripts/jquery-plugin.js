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
(function($){  
	var timeouts = new Array();
	$.fn.flash_message = function(title, message, suffix, options) {
		var options = $.extend( {
		  direction			: "up",
		  effect			: "slide",
		  show_for 			: 5000,
		  duration_modifier	: 0.5,			// Effect duration modifer (duration*modifier). close effect onClick
		  duration 			: 1000,
		  warning_color 	: "#f33",
		  warning_effect 	: "highlight"		
		},options);
	
		suffix 	= (suffix) ? suffix.toLowerCase() : "notice";

		if($("#js_report_"+suffix).size()>0) {
			$(this).each(function() {
				$("#js_report_"+suffix)
					.effect(options.warning_effect, 
							{color: options.warning_color}, 
							500, 
							function() {
								$(this).remove();
								window.clearTimeout(timeouts[suffix]);
							}	
					);
				window.setTimeout(function() { return show_message($(this), title, message, suffix, options);}, 1000);	
			});
		}
		return show_message($(this), title, message, suffix, options);
	}
	
	function show_message(self, title, message, suffix, options) {
		timeouts[suffix] = window.setTimeout(function() { 
			$("#js_report_"+suffix)
				.hide(options.effect, 
					  {direction: options.direction}, 
					  options.duration, 
					  function() {
						$(this).remove();
						window.clearTimeout(timeouts[suffix]);
					  }
				);
		}, options.show_for + options.duration);
		
		return self
				.before("<div id='js_report_"+suffix+"' class='js_report "+suffix+"'><span id='close_report'></span><b>"+title+"</b><br />Results:<br /><span class='result'>"+message+"</span></div>")
				.prev()
				.find("#close_report")
					.click(function(){ 
						$("#js_report_"+suffix)
							.hide(options.effect, 
								  {direction: options.direction}, 
								  options.duration*options.duration_modifier, 
								  function() {
									$(this).remove();
									window.clearTimeout(timeouts[suffix]);
								  }
						);
					})
				.end()
				.show(options.effect, { direction: options.direction }, options.duration);
	}
})(jQuery);

// Will make a simple input an awesome ajax live search
(function($){  
 var limit_request_timer = null;
 var remove_result_timer = null;
	
  $.fn.is_search_box = function(options) {
	var self 	= $(this);
	var options = $.extend( {
		url			: location.href
	}, options);
	
	return self	 	
		.val("Search..")
		.focus(function(){

			if(self.val()=="Search..") self.val("");
			
			if(remove_result_timer) window.clearTimeout(remove_result_timer);
		})
		.blur(function(){
			self = $(this);
			if(self.val()=="") self.val("Search..");	
			
			remove_result_timer = window.setTimeout(function(){
				 self.nextAll("div.search_results").remove();
			}, 750);
		})
		.keypress(function(){
			self 	= $(this);			
			if(self.val().length>=2) {				
				if(limit_request_timer) window.clearTimeout(limit_request_timer);
				limit_request_timer = window.setTimeout(function(){
					$.get(options.url+"", {query: self.val()}, function(data) { show_search_results(self, data); });
				}, 500);
			} else {
				remove_result_timer = window.setTimeout(function(){
					 self.nextAll("div.search_results").remove();
				}, 750);
			}
		});
	}
	
	function show_search_results($input, data) {
		$input
			.nextAll("div.search_results")
			 .remove()
			.end()
			.after("<div class='ui-helper-reset ui-widget-content search_results' id='search_results'></div>")
			.next()
			.html(data)
			.find("ul li, ul ul li")
			  .click(function() {
				window.location.href = $(this).attr("href");
			 });
	}
})(jQuery);