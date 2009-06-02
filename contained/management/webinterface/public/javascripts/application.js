// Add corners to the navigation (jQuery UI)
$(function() {
	$("#navigation ul ul").each(function() {
		$(this).children("li:last").addClass("ui-corner-bottom");
	});
});

// Hide the unordered link list(s), make the li's links and add a target to the A (XHTML..).
$(function() {
	$("#links")
	.click(function() {
		$(this).children("ul").toggle();
	})
	.find("li")
	 .click(function(e) { 
		e.stopPropagation();
		window.open($(this).find("a:first").attr("href"));
	 })
	.find("a")
	 .click(function(e) { e.stopPropagation(); })
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