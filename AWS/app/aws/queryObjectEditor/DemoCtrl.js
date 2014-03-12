angular.module('aws.queryObjectEditor', [])
.controller('DemoCtrl', function($scope, $aside) {
  // Show a basic aside from a controller
	
	
	$scope.currentJson = {
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
			  "ColorColumn": {
			    "enabled": true,
			    "selected": "prev.percent"
			  },
			  "scriptSelected": "Indicator Prevalence by State.R"
			};
});