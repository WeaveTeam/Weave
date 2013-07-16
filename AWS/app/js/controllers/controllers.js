'use strict';

/**
 * Main AWS Application Controller
 * LayoutCtrl - TODO
 * WeaveLaunchCtrl - TODO 
 * PanelGenericCtrl <TODO rename> - Displays the dashboard portlets and their data. 
 */
function PanelGenericCtrl($scope){
	$scope.typing = "first";
	$scope.b = [
		{
			panelTitle: "Indicator",
			x: "span3",
			y: 1,
			content: '<input type="text" ng-model="typing">'
		},
		{
			panelTitle: "Geography",
			x: "span4",
			y: 2,
			content: '{{typing}}'
		},
		{
			panelTitle: "By-Variables",
			x: "span6",
			y: 1,
			content: 'JSON Query Object <input id="panel6ImportButton"' +
                  'type="submit" value="Import..." /> <input id="panel6SaveButton"' +
                  'type="submit" value="Save" /> <input id="panel6EditButton"' +
                  'type="submit" value="Edit" />'
		},
		{
			panelTitle: "Time Period",
			x: "span2",
			y: 2},
		{
			panelTitle: "Query Object",
			x: "span2",
			y: 1,
			content: 'JSON Query Object <input id="panel6ImportButton"' +
                  'type="submit" value="Import..." /> <input id="panel6SaveButton"' +
                  'type="submit" value="Save" /> <input id="panel6EditButton"' +
                  'type="submit" value="Edit" />'
		},
		{
			panelTitle: "Round Trip Demo",
			x: "span6",
			y: 2,
			content: 'Script: <select id="scriptCombobox"></select> <br></br>' +
              'Data: <select id="dataCombobox"></select> <br></br>' +
              '<input id="scriptButton"  type="submit" value="Run Script" />'  +
              '<input id="scriptButton2" type="submit" value="CDCforQueries.R" />'
		}
	];
	angular.forEach($scope.b, function(value){
		 value.id = "a" + Math.floor((Math.random()*1000)+1);
	});
	$scope.leftPanelUrl = "./partials/leftPanel.tlps.html";
	$scope.addContent = function(elem){
		//var e = $(elem).find(".portlet-content");
		var e = $("#" + elem.id + "-panel").find(".portlet-content");
		var f = elem.content;
		e.html(f);
		//return f;
		// $(elem).find(".portlet-content").html(elem.content);
	};
	/*$scope.openDialog = function() {
		
		var msg = 'Hello World!';
    var options = {
      resolve: {
        msg: function () { return msg; }
      }
    };
    var d = $dialog.dialog(options);

		d.open('partials/dialog.html', 'dialogCtrl');
	};*/
    

	$scope.panelTitle = "Generic Panel";
	$scope.controls = [
		{
			name : 'slider'
		},
		{
			name : 'combobox'
		}

	];
}

