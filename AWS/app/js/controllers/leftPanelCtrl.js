/**
 * Left Panel Module LeftPanelCtrl - Manages the model for the left panel.
 */
angular.module("aws.leftPanel", []).controller("LeftPanelCtrl",
		function($scope, $location, queryobj, $q) {
			$scope.isActive = function(route) {
				return route == $location.path();
			};
			$scope.uploadQuery = function(){
						
			};
			$("#queryImport").fileReader({"debugMode":true,"filereader":"lib/jquery/filereader.swf"});
			$("#queryImport").on("change", function(evt){
				console.log(evt.target.files);
				var file = evt.target.files[0];
				var reader = new FileReader();
				reader.onload = function(e) {
					//importedobjectfromjson = $.parseJSON(e.target.result);
					console.log(e.target.result);
					//var qh = new aws.QueryHandler(importedobjectfromjson);
					//qh.runQuery();
				}
				reader.readAsText(file);
			});
			
			$scope.shouldShow = false;
			
			var setCount = function(res){
				$scope.shouldShow = res;
			};
			
			
			aws.addBusyListener(setCount);
		
});

function saveJSON(query) {
	var blob = new Blob([ JSON.stringify(query, undefined, 2) ], {
		type : "text/plain;charset=utf-8"
	});
	saveAs(blob, "Query Object.txt");
}
