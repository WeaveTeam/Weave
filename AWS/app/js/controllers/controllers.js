'use strict';

/**
 * Main AWS Application Controller
 * LayoutCtrl - TODO
 * WeaveLaunchCtrl - TODO 
 * PanelGenericCtrl <TODO rename> - Displays the dashboard portlets and their data. 
 */
angular.module("aws.Main", [])
.controller("PanelGenericCtrl", function($scope){
	$scope.typing = "first";
	$scope.panels = [
		{
			panelTitle: "Time Period",
			size: "span2",
			id: "a4"},
		{
			panelTitle: "Query Object",
			size: "span2",
			id: "a5",
			content: 'JSON Query Object <input id="panel6ImportButton"' +
                  'type="submit" value="Import..." /> <input id="panel6SaveButton"' +
                  'type="submit" value="Save" /> <input id="panel6EditButton"' +
                  'type="submit" value="Edit" />'
		},
		{
			panelTitle: "Round Trip Demo",
			size: "span6",
			id: "a6",
			content: 'Script: <select id="scriptCombobox"></select> <br></br>' +
              'Data: <select id="dataCombobox"></select> <br></br>' +
              '<input id="scriptButton"  type="submit" value="Run Script" />'  +
              '<input id="scriptButton2" type="submit" value="CDCforQueries.R" />'
		}
	];
	angular.forEach($scope.panel, function(value){
		 value.id = "a" + Math.floor((Math.random()*1000)+1);
	});
//	aws.stataTest(function(result, queryId){
//		console.log("handleResponse fcn sent to aws.stataTest()");
//		console.log(result);
//		console.log(queryId);
//	});
	$scope.addPanelContent = function(elem){
		//var e = $(elem).find(".portlet-content");
		var e = $("#" + elem.id).find(".portlet-content");
		var f = elem.content;
		e.html(f);
		//return f;
		// $(elem).find(".portlet-content").html(elem.content);
	};

})
.controller("LayoutCtrl", function($scope, queryobj){
	$scope.leftPanelUrl = "./tlps/leftPanel.tlps.html";
	$scope.genericPortlet = "./tlps/genericPortlet.tlps.html";
	$scope.QueryObjectModel = function(){ 
		return JSON.stringify(queryobj, undefined, 2);
	}
	/*$scope.$watch('queryobj.selectedColumns' , function(){
		$scope.$broadcast("requestingQueryObject");
	});*/
	
	
	
})

