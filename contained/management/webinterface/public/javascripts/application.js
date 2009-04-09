$(function() {
	$("#navigation ul ul").each(function() {
		$(this).children("li:last").addClass("ui-corner-bottom");
	});
});