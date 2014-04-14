//$.support.cors = true;
WeaveJQueryCaller = {};
WeaveJQueryCaller.getFile = function (url, id) {
	$.ajax({
			url: url,
			type: "GET",
			dataType: "text",
			success: function( data, textStatus, jqXHR ) {
				try
				{
					//console.log('success', arguments);
					weave.jqueryResult(id, data);
				}
				catch (e)
				{
					console.log("Unable to pass result to Weave", arguments, e);
				}
			},
			error: function (qXHR, textStatus, errorThrown) {
				try
				{
					//console.log('error', arguments);
					weave.jqueryFault(id, qXHR, textStatus, errorThrown);
				}
				catch (e)
				{
					console.log("Unable to pass error to Weave", arguments, e);
				}
			}
		});
}