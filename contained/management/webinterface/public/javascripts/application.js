// Add corners to the navigation (jQuery U)
$(function() {
	$("#navigation ul ul").each(function() {
		$(this).children("li:last").addClass("ui-corner-bottom");
	});
});

// Hide the links easily, and add a target.
$(function() {
	$("#links")
	.click(function() {
		$(this).children("ul").toggle();
	})	
	.find("a")
	 .attr("target", "_blank");
});

// Sent an AJAX GET request to the service controller: domains/__domain__/services/__service__/invoke/__method__
function method_request(url, paramaters, on_success, on_complete, on_error) {
	$.ajax({
	  type				: "GET",
	  url				: url.replace(/\#[^\/]*?(?=\/|$)/i, ""),
	  data 				: (paramaters),
	  dataType			: "html",
	  success			: function(data, status) {	
		if(data.match(/^error;/i)) {
			$("#content").children(":first").flash_message("Error invoking "+paramaters.method+"!", data.replace(/error\;(.+?$)/i, "$1"), "error");
		} else {
			$("#content").children(":first").flash_message("Succesfully invoked "+paramaters.method+"!", data, "success");
		}
				
		if(on_success) on_success();
	  },
	  error				: function(XMLHttpRequest, textStatus, errorThrown) {
		$("#content").children(":first").flash_message("Error invoking "+paramaters.method+"!", XMLHttpRequest.responseText, "error");
		
		if(on_error) on_error();				
	  },
	  complete 			: function() { 
		if(on_complete) on_complete();
	  }
	});	
}