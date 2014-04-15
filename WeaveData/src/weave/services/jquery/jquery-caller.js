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
					weave.jqueryResult(id, btoa ? btoa(data) : data, !!btoa, true);
				}
				catch (e)
				{
					// error encoding base64
					weave.jqueryResult(id, null, false, false);
				}
			},
			error: function (jqXHR, textStatus, errorThrown) {
				try
				{
					//console.log('error', arguments);
					weave.jqueryFault(id, jqXHR, textStatus, errorThrown);
				}
				catch (e)
				{
					console.log("Unable to pass error to Weave", arguments, e);
				}
			}
		});
}
