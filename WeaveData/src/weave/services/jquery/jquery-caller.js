//$.support.cors = true;
WeaveJQueryCaller = {};
WeaveJQueryCaller.getFile = function (url, id) {
	$.ajax({
			url: url,
			type: "GET",
			dataType: "text",
			success: function( data, textStatus, jqXHR ) {
				weave.jqueryResult(id, data);
			},
			error: function (qXHR, textStatus, errorThrown) {
				weave.jqueryFault(id, errorThrown);
			}
		});
}