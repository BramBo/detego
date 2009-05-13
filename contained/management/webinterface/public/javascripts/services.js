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
				eval($(this).attr("click"))
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
	$(this).html("<input type='text' value='"+value+"' \>");
	
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
function remove_service(){
	if (window.confirm("Are you sure you want to delete this service?")) {
		self 		= $(this);
		// <span><span></span><span>method_name</span><span><img !clicked! /></span></span>
		in_method	=  self.parent().parent().children("span").next().html();
	
		self.show("pulsate", { times:100 }, 500);
		method_request(location.href+"/invoke", {method: in_method}, function() {
			window.location.href=window.location.href.replace(/(^.+?)\/[^\/]+\/[^\/]+?$/, "$1");
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
		
		dialog_html_string = "";	
		$.each(params, function(i,e){
			dialog_html_string += "<label>"+e+"</label><input type='text' class='param' id='param"+i+"' /><br />";
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
				.html(dialog_html_string);
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