/**
 * buttonBarController. This controller manages query import and exports.
 */
var QueryObject = angular.module("aws.queryObject", []);

QueryObject.controller("buttonBarController", function($scope, $modal, queryService, WeaveService,projectService, QueryHandlerService) {
	
	$scope.queryService = queryService;
	$scope.WeaveService = WeaveService;
	$scope.projectService = projectService;
	$scope.QueryHandlerService = QueryHandlerService;
	
	//structure for file upload
	$scope.queryObjectUploaded = {
			file : {
				content : "",
				filename : ""
			}
	};
	
	//options for the dialog for saving output visuals
	$scope.opts = {
			 backdrop: false,
	          backdropClick: true,
	          dialogFade: true,
	          keyboard: true,
	          templateUrl: 'src/analysis/savingOutputsModal.html',
	          controller: 'DialogInstanceCtrl',
	          resolve:
	          {
	                      projectEntered: function() {return $scope.projectEntered;},
	                      queryTitleEntered : function(){return $scope.queryTitleEntered;},
	                      userName : function(){return $scope.userName;}
	          }
		};


	//Handles the download of a query object
	$scope.exportQuery = function() {
		if(WeaveService.weave)
		{
			$scope.queryService.queryObject.sessionState = WeaveService.weave.path().getState();
		}
		
		var blob = new Blob([ angular.toJson(queryService.queryObject, true) ], {
			type : "text/plain;charset=utf-8"
		});
		saveAs(blob, "QueryObject.json");//TODO add a dialog to allow saving file name
	};
	 
	//cleans the queryObject
	$scope.cleanQueryObject = function(){
		queryService.queryObject = {
				title : "Beta Query Object",
				date : new Date(),
	    		author : "",
	    		dataTable : "",
				ComputationEngine : "R",
				Indicator : "",
				columnRemap : {},
				filters : [],
				treeFilters : [],
				GeographyFilter : {
					stateColumn:{},
					nestedStateColumn : {},
					countyColumn:{},
					geometrySelected : null,
					selectedStates : null,
					selectedCounties : null
				},
				openInNewWindow : false,
				Reidentification : {
					idPrevention :false,
					threshold : 0
				},
				scriptOptions : {},
				scriptSelected : "",
				properties : {
					linkIndicator : false,
					validationStatus : "test",
					isQueryValid : false
				},
				filterArray : [],
				treeFilterArray : [],
				visualizations : {
					MapTool : {
						title : 'MapTool',
						template_url : 'src/visualization/tools/mapChart/map_chart.tpl.html',
						enabled : false
					},
					BarChartTool : {
						title : 'BarChartTool',
						template_url : 'src/visualization/tools/barChart/bar_chart.tpl.html',
						enabled : false
					},
					DataTableTool : {
						title : 'DataTableTool',
						template_url : 'src/visualization/tools/dataTable/data_table.tpl.html',
						enabled : false
					},
					ScatterPlotTool : {
						title : 'ScatterPlotTool',
						template_url : 'src/visualization/tools/scatterPlot/scatter_plot.tpl.html',
						enabled : false
					},
					AttributeMenuTool : {
						title : 'AttributeMenuTool',
						template_url : 'src/visualization/tools/attributeMenu/attribute_Menu.tpl.html',
						enabled: false
					},
					ColorColumn : {
						title : "ColorColumn",
						template_url : 'src/visualization/tools/color/color_Column.tpl.html'
					},
					KeyColumn : {
						title : "KeyColumn",
						template_url : 'src/visualization/tools/color/key_Column.tpl.html'
					}
				},
				resultSet : [],
				weaveSessionState : null
		};//TODO fix this   		
	};
	
    $scope.saveVisualizations = function (projectEntered, queryTitleEntered, userName) {
    	
    	var saveQueryObjectInstance = $modal.open($scope.opts);
    	saveQueryObjectInstance.result.then(function(params){//this takes only a single object
    	//console.log("params", params);
    		$scope.projectService.getBase64SessionState(params);
    		
    	});
    };
    
    	
	//chunk of code that runs when a QO is imported
	$scope.$watch('queryObjectUploaded.file', function(n, o) {
		if($scope.queryObjectUploaded.file.content)
		{
			$scope.queryService.queryObject = angular.fromJson($scope.queryObjectUploaded.file.content);
			if(WeaveService.weave)
			{
				WeaveService.weave.path().state($scope.queryService.queryObject.sessionState);
				delete $scope.queryService.queryObject.sessionState;
			}
		}
    }, true);
});

QueryObject.controller('DialogInstanceCtrl', function ($scope, $modalInstance, projectEntered, queryTitleEntered, userName) {
	  $scope.close = function (projectEntered, queryTitleEntered, userName) {
		  var params = {
				  projectEntered : projectEntered,
				  queryTitleEntered : queryTitleEntered,
				  userName :userName
		  };
		  $modalInstance.close(params);
};
});
