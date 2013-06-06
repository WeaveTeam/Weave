<!DOCTYPE html>
<html>
<head>
<meta charset="ISO-8859-1">
<title>Insert title here</title>
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
</head>
<body>
<button onClick = "stata('getRResult')" style = "padding-top:5px;
		                padding-left: 5px;
						padding-right:5px;
						padding-bottom:5px">Execute</button>
<div id=patrick></div>
<script language="JavaScript" type="text/javascript">
// Disable caching of AJAX responses
$.ajaxSetup({
    cache: false
});


// this function gets called when the weave instance is ready.
function weaveReady(weave)
{
	//disableButtons(false);
	document.getElementById('versionSpan').innerHTML = weave.getSessionState(['WeaveProperties','version']);
	resulttextarea.value = 'Weave JavaScript API is ready (id="'+(weave && weave.id)+'").';
}

//calling Rservice on Weave
function queryRService(method,params,callback,queryID)
{
	console.log('queryRService',method,params);
	var url = "..\\..\\..\\git\\Weave\\WeaveServices\\RServiceUsingRserve";
	var request = {
					jsonrpc:"2.0",
					id:queryID || "no_id",
					method : method,
					params : params
	};
	
	$.post(url,JSON.stringify(request), callback, "json");
	resulttextarea.value = 'Awaiting Response for ' + method + ' request....';
	
}

function stata(method){
	var url = "StataRoundTrip";
	var response = $.post(url,function(data){
 		var content = $(data).toString();
 		console.log(content);
 		$('#patrick').html(content);
 	}).success(function(data){
 		var content = $(data).toString();
 		console.log(content);
 		$('#patrick').html(content);
 	});
	//response.responseText;
	//console.log(response);
	//handleStataResult(response);
	console.log("End of Round Trip");
}

function handleStataResult(response){
	var content = response.responseText;
	console.log(content);
	$('#patrick').html(response.responseText);
	console.log("success");
	
}

//calling testServerQuery
function testServerQuery(secondMethodName)
{
	var inNames = "x";
	var inValues = 5;
	queryRService(
	//method
	'runScript',
	{
		//params
		docrootPath :"",
		inputNames: [inNames],
		inputValues:[inValues],
		outputNames:["y"],
		script: "y <- x + 2\n",
		plotScript : "",
		showIntermediateResults : false,
		showWarnings: false
	},
	//callback
	handleRResult
	);
	
	
	function handleRResult(response)
	{
		if(response.error)
		{
			resulttextarea.value = JSON.stringify(response,null,3);
			return;
		}
		else
		{
			var rResult = response.result;
			console.log("retrieved " + rResult.length + "results");
			resulttextarea.value = "Success";
			return;
		}
		
		
	}
}

</script>
</body>
</html>