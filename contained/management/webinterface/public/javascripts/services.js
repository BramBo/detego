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
	method_request(in_method, function() {
		self.stop(true, true).show("pulsate", { times:1 }, 1);
		update_status();
	});
}

// Wrapper for method_request: special case: Remove a service from the server
function remove_service(){
	if (window.confirm("Are you sure you want to delete this service?")) {
		self 		= $(this);
		in_method	=  self.parent().parent().children("span").next().html();
	
		self.show("pulsate", { times:100 }, 500);
		method_request(in_method, function() {
			window.location.href=window.location.href.replace(/(^.+?)\/[^\/]+\/[^\/]+?$/, "$1");
		});
	}
}

function method_request(in_method, on_complete) {
	$.ajax({
	  type				: "GET",
	  url				: window.location.href+"/invoke",
	  data 				: ({method: in_method}),
	  dataType			: "html",
	  success			: function(data, status) {	
		if(data.match(/^error;/i)) {
			report("<b>Error invoking "+in_method+"!</b><br />Results:<span class='result'>"+data.replace(/error\;(.+?$)/i, "$1")+"</span>", "error")
		} else {
			report("<b>Succesfully invoked "+in_method+"!</b><br />Results:<span class='result'>"+data+"</span>", "success")			
		}
			
	  },
	  error				: function(XMLHttpRequest, textStatus, errorThrown) {
		report("<b>Error invoking "+in_method+"!</b><br />Results:<span class='result'>"+XMLHttpRequest.responseText+"</span>", "error")
	  },
	  complete 			: on_complete()
	});	
	
}

function update_status() {
	$.get(window.location.href+"/status", {}, function(data) {
		$("#service_status").html(data);
	}, "text");
}

// Simple function to report the received message
var timeouts = new Array();
function report(what, type) {
	var type = (type) ? type.toLowerCase() : "notice"	
	if($("#js_report_"+type).size()>0) {
		$("#js_report_"+type).remove();
		window.clearTimeout(timeouts[type]);
	}
	
	$("#content").children(":first").before("<div id='js_report_"+type+"' class='js_report "+type+"'>"+what+"</div>");
	$("#js_report_"+type).show("slide", { direction: "up" }, 1000);

	timeouts[type] = window.setTimeout(function(){$("#js_report_"+type).hide("slide", {direction: "up"}, 1000);}, 10000)
}