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
			$(this).click(eval($(this).attr("click")));
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
	
	$(group).unbind("click", to_input)
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
		console.debug(value);

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
	method_request({method: in_method}, null, function() {
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
		method_request({method: in_method}, function() {
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
	
	if(parameter_value.match(/\<input/i)) parameter_value = self.parents("span").children("span").children("input").val();
	
	invoke 			= ""+in_method+"('"+parameter_value+"')"
	method_request({method: invoke}, null, function() {
		update_status();
		update_details();		
	});
}

// Sent an AJAX GET request to the service controller: domains/__domain__/services/__service__/invoke/__method__
function method_request(paramaters, on_success, on_complete, on_error) {
	$.ajax({
	  type				: "GET",
	  url				: window.location.href+"/invoke",
	  data 				: (paramaters),
	  dataType			: "html",
	  success			: function(data, status) {	
		if(data.match(/^error;/i)) {
			$("#content").children(":first").flash_message("Error invoking "+in_method+"!", data.replace(/error\;(.+?$)/i, "$1"), "error");
		} else {
			$("#content").children(":first").flash_message("Succesfully invoked "+in_method+"!", data, "success");
		}
		if(on_success) on_success();
	  },
	  error				: function(XMLHttpRequest, textStatus, errorThrown) {
		$("#content").children(":first").flash_message("Error invoking "+in_method+"!", XMLHttpRequest.responseText, "error");
		
		if(on_error) on_error();				
	  },
	  complete 			: function() { 
		if(on_complete) on_complete();
	  }
	});	
	
}

// Gets a new service status.
function update_status() {
	$.get(window.location.href+"/status", {}, function(data) {
		$("#service_status").html(data);
	}, "text");
}

// Easy ajax get and replace
function update_details() {
	$.get(window.location.href+"/update_details", function(data) {
		$("#service_details").html(data);
	});
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