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
	
	value = $(self).children("input").val()
	
	if(value=="") value ="-----";
	$(self).html(value);	
	
	$(group).click(to_input);		
	
	$(self).next().hide("puff", {}, 500);
}

// Default handler for a service method call, bound through class='runnable'
function invoke_handler() {
	self 		= $(this);
	in_method	=  self.parent().parent().children("span").next().html();
	
	self.show("pulsate", { times:100 }, 500);
	method_request({method: in_method}, null, function() {
			self.stop(true, true).show("pulsate", { times:1 }, 1);			
			update_status();
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
	
	invoke 			= ""+in_method+"('"+parameter_value+"')"
	self.show("pulsate", { times:100 }, 500);
	method_request({method: invoke}, null, function() {
		self.stop(true, true).show("pulsate", { times:1 }, 1);			
		update_status();
	});
}

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

function update_status() {
	$.get(window.location.href+"/status", {}, function(data) {
		$("#service_status").html(data);
	}, "text");
}
