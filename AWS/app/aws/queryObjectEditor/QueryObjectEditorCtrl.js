/**
 * This controller controls the queryObject (json ) Editor
 */
angular.module('aws.queryObjectEditor', [])
.controller("QueryObjectEditorCtrl", function($scope, queryService){

	$scope.checkJson = {
			  "title": "Alpha Query Object",
			  "date": "2014-02-27T14:57:29.037Z",
			  "author": "",
			  "ComputationEngine": "R",
			  "dataTable": {
			    "id": 4327,
			    "title": "test2010"
			  },
			  "FilteredColumnRequest": [
			    {
			      "column": {
			        "id": 4624,
			        "title": "X_FINALWT"
			      }
			    },
			    {
			      "column": {
			        "id": 4362,
			        "title": "DIABETE2"
			      }
			    }
			  ],
			  "MapTool": {
			    "enabled": true,
			    "selected": {
			      "id": 5008,
			      "title": "us_geometry",
			      "keyType": "prevalence"
			    }
			  },
			  "BarChartTool": {
			    "enabled": false,
			    "heights": [],
			    "sort": "",
			    "label": ""
			  },
			  "ColorColumn": {
			    "enabled": true,
			    "selected": "prev.percent"
			  },
			  "scriptSelected": "Indicator Prevalence by State.R"
			};
	console.log("queryServicequeryObject", queryService.queryObject);
});