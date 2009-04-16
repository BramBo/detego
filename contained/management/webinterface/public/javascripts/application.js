$(function() {
	$("#navigation ul ul").each(function() {
		$(this).children("li:last").addClass("ui-corner-bottom");
	});
});

$(function() {
	$("#links")
	.click(function() {
		$(this).children("ul").toggle();
	})	
	.find("a")
	 .attr("target", "_blank");
});