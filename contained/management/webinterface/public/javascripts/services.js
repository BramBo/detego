var group 		= "span.variable_value span, span.variable_value span input";
var accordions	= [["#methods_section", -1], ["#var_section", -1], ["#operations", -1]]
// Function to bind all the needed handlers, and effects.
function kickoff_services() {
	$("span.variable_value span").click(to_input);
	
	for(a in accordions) {
		$(accordions[a][0])
			.accordion({collapsible: true, active: accordions[a][1], icons: { 'header': 'ui-icon-plus', 'headerSelected': 'ui-icon-minus' }, header: "h3" })
			.bind('accordionchange', set_open_accordion);
	}

	$(".runnable_method").each(function() { 
		if($(this).attr("click")) {
			$(this).click(function() {
				eval($(this).attr("click"));
			});
		} else {
			$(this).click(invoke_handler);
		}
	});
	
	$("img.var_control").click(invoke_method_w_parameters);		
}


// Convert the value inside an span into an input box
function to_input() {
	value = $(this).html();

	if(value =="-----") value = ""; 
	$(this)
		.html("<input type='text' value='"+value+"' \>")
		.find("input:first")
		 .keydown(function(e) { 
			if(e.keyCode==13) { $(this.parentNode).next().trigger("click"); } 
			else if(e.keyCode==27) {$(this).trigger("blur"); }
		});
	
	$(group)
		.unbind("click", to_input)
		.focus();
	
	e = this;
	$(this).children("input").blur(function() {		
		to_text(e) 
	});
	$(this).next().show("puff", {}, 500);
}

// Convert the input box back to a span
function to_text(self) {
	if (self == null) self = this;
	
	window.setTimeout(function(){ 
		value = $(self).children("input").val();

		if(value=="") value ="-----";
		$(self).html(value);	

		$(group).click(to_input);		
		
		
		$(self).next().hide("puff", {}, 750); 
		
	}, 1000);
}

// Default handler for a service method call, bound through class='runnable'
function invoke_handler() {
	self 		= $(this);
	in_method	=  self.parent().parent().children("span").next().html();
	
	self.show("pulsate", { times:100 }, 500);
	method_request(location.href+"/invoke", {method: in_method}, null, function() {
			self.stop(true, true).show("pulsate", { times:1 }, 1);			
			update_status();
			update_details();
		}	
	);
}

// Wrapper for method_request: special case: Remove a service from the server
function remove_service(el){
	if (window.confirm("Are you sure you want to delete this service?")) {
		self 		= $(el);
		// <span><span></span><span>method_name</span><span><img !clicked! /></span></span>
		in_method	=  self.parent().parent().children("span").next().html();
	
		console.log("Element: " + self);
		console.log("Executing: " + in_method);
	
		self.show("pulsate", { times:100 }, 500);
		method_request(location.href+"/invoke", {method: in_method}, function() {
			window.location.href = window.location.href.replace(/(^.+?)\/[^\/]+\/[^\/]+?$/, "$1");
		});
	}
}

// wrapper for method_request: special case: var_control img clicked !
function invoke_method_w_parameters() { 
	self = $(this);
	// <span><span></span><span>method_name</span><span><img !clicked! /></span></span>
	in_method		=  self.parents("span").parent().children("span").next().html();
	parameter_value	=  self.parents("span").children("span").html();
	
	// Silly effect fix, while this is being executed the <input> is still active!
	if(parameter_value.match(/\<input/i)) parameter_value = self.parents("span").children("span").children("input").val();
	
	invoke 			= ""+in_method+"('"+parameter_value+"')"
	method_request(location.href+"/invoke", {method: invoke}, null, function() {
		update_status();
		update_details();		
	});
}


// Gets a new service status.
function update_status() {
	$.get(window.location.href.replace(/\#.*?$/i, "")+"/status", {}, function(data) {
		$("#service_status").html(data);
	}, "text");
}

// Easy ajax get and replace
function update_details() {
	$.get(window.location.href.replace(/\#.*?$/i, "")+"/update_details", function(data) {
		$("#service_details").html(data);
	});
}

// Execute method with (a) parameter(s)
function w_parameters(element, params) {
	if(($e = $(element)).hasClass("runnable_method")) {
		
		in_method			=  $e.parent().parent().children("span").next().html();
		dialog_html_string 	= "<input type='hidden' name='method' value='"+in_method+"' />";	
		$.each(params, function(i,e){
			dialog_html_string += "<label for='param"+i+"'>"+e+"</label><input type='text' class='param' id='param"+i+"' name='param"+i+"' /><br />";
		});

		$('#mask')
			.css({'width': $(document).width(),'height': $(document).height()})
			.fadeIn(750)	
			.fadeTo("fast",0.8);	
              
		($d = $("#dialog"))
			.css('top',  $(window).height()/2 - $d.height()/2)
			.css('left', $(window).width() /2 - $d.width()/2)
			.fadeIn(2000)
			.find("form")
				.empty()
				.html(dialog_html_string)
					.find("input[type=text]:first")
					 .focus();
	} 
	return false;
}

// When an accordion header gets clicked set the array to the current active one, Really should be easily fetchable through 'option', 'active' !
function set_open_accordion(event, ui) {
	i=0;

	ui.newHeader.parent().children("h3").each(function(){
		if(ui.newHeader[0] === this) {
			// works outside the binding context so.. :
			for(ac in accordions) {
				if(accordions[ac][0]=="#"+$(this).parent()[0].id) {
				 	accordions[ac][1] = i;
					break;
				}
			}
		}
		i++;
	});
	
	if(ui.newHeader.size()==0) {
		for(ac in accordions) {	
			if(accordions[ac][0]=="#"+this.id) {
			 	accordions[ac][1] = -1;
				break;
			}
		}
	}
}


// Hot Keys (Meta) + G to search See var hot_key_elements for bindings (line: ~264)
var acc_opened = null;
$(function(){
	$("#methods_section h3, #operations h3, #var_section h3").click(function() {
		var clicked	= this; 
		var ind 	= 0;
		$(this.parentNode).find("h3").each(function(i){
			if(this==clicked) ind = i;
		});
		
		if(acc_opened == "#"+this.parentNode.id + " h3:eq("+ind+")")	{ acc_opened = null; }
		else 														 	{ acc_opened = "#"+this.parentNode.id + " h3:eq("+ind+")"; }
	});
});

// Bind document key listener, shot HotKeys, remove Hoykeys and the hotkeys it self
(function($) {
 $(function() {
  $(document)
	.keyup(function(){ remove_hot_keys();})
	.blur(function(){  remove_hot_keys();})
	.keydown(function(e) {		// Nasty switch! Just here not to use eval()...
		remove_hot_keys();
		
		var e = (e) ? e : window.event;
		if(!e.metaKey) return;
		show_hot_keys();

		switch(e.keyCode) {
		 case 83:
			e.preventDefault();
			e.stopPropagation();
	
			hot_key_elements.e83.func();
		 break;
		 case 69:
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e69.func();
		 break;
		 case 70:
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e70.func();
		 break;
		 case 66:
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e66.func();
		 break;		
		 case 87:
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e87.func();
		 break;	
		 case 75: 
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e75.func();
		 break;	
		 case 71: 	
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.e71.func();
		 break;
		 case 48: case 49: case 50: case 51: case 52: 
		 case 53: case 54: case 55: case 56: case 57:
			e.preventDefault();	
			e.stopPropagation();
			
			hot_key_elements.number.func(e.keyCode);
		 break;	
		}
 	})
 });

 var hot_key_elements = {
	e83 	: { element: "#operations h3:eq(0)"		, func : function() { open_accordion(this.element); } },
	e69 	: { element: "#methods_section h3:eq(0)", func : function() { open_accordion(this.element); } },
	e70 	: { element: "#methods_section h3:eq(1)", func : function() { open_accordion(this.element); } },
	e66 	: { element: "#var_section h3:eq(0)"	, func : function() { open_accordion(this.element); } },
	e87 	: { element: "#var_section h3:eq(1)"	, func : function() { open_accordion(this.element); } },
	e75 	: { element: "#var_section h3:eq(2)"	, func : function() { open_accordion(this.element); } },
	e71 	: { element: "#search_tip"				, func : function() { $(".search_box:eq(0)").find("input").focus(); } },
	number  : { element: null						, func : function(nr) { execute_func(nr); } }	
 };

 // When a number is entered (Meta+[0..9]) execute the proper action related to this element i.e. invoke a getter
function execute_func(nr) {
	$(acc_opened)
	 .next()
	  .children("li:eq("+(nr-49)+")")
		.find(".runnable_method, .variable_value span")
			.trigger("click");
}

 // Display small tooltips to show the keys and the related elements in place
 var hot_key_timer = null;
 function show_hot_keys() {
	hot_key_timer = window.setTimeout(function() {
		$.each(hot_key_elements, function(i, f) {
			if(f.element != null) {
				html = $(f.element).html();	
			
				if(!html.match(/tiny\_tip/i))
			 	{	$(f.element).html("<div class='tiny_tip'> Hotkey: "+String.fromCharCode(i.replace(/\w/i, ""))+"</div>" + html); }
			}
		});
	}, 500);
 }

 function remove_hot_keys() {
	window.clearTimeout(hot_key_timer);
	hot_key_timer = null;
		
	$.each(hot_key_elements, function(i, f) {
		$(f.element).find(".tiny_tip").remove();
	});	
 }

 function open_accordion(element) { $(element).trigger("click"); }
})(jQuery);
