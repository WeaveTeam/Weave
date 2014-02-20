/**
 *  Individual Panel Type Controllers
 *  These controllers will be specified via the panel directive
 */
angular.module("aws.panelControllers", [])
.controller("ScriptCtrl", function($scope, queryService){
	
	// array of column selected
	$scope.selection = []; 
	
	// array of filter types, can either be categorical (true) or continuous (false).
	$scope.filterType = [];
	
	// array of boolean values, true when the column it is possible to apply a filter on the column, 
	// we basically check if the metadata has varType, min, max etc...
	$scope.show = [];
	
	// the slider options for the columns, min, max etc... Array of object, comes from the metadata
	$scope.sliderOptions = [];
	
	// the categorical options for the columns, Array of string Arrays, comes from metadata, 
	// this is provided in the ng-repeat for the select2
	$scope.categoricalOptions = [];
	
	// array of filter values. This is used for the model and is sent to the queryObject, each element is either
	// [min, max] or ["a", "b", "c", etc...]
	$scope.filterValues = [];
	
	// array of booleans, either true of false if we want filtering enabled
	$scope.enabled = [];
	
	$scope.scriptList = queryService.getListOfScripts();
	
	
	$scope.$watch('scriptSelected', function() {
		if($scope.scriptSelected != undefined && $scope.scriptSelected != "") {
				queryService.queryObject.scriptSelected = $scope.scriptSelected;
				queryService.getScriptMetadata($scope.scriptSelected, true);
		}
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.scriptSelected;
	}, function() {
		$scope.scriptSelected = queryService.queryObject.scriptSelected;
	});
	
	$scope.inputs;
	$scope.$watch(function(){
		return queryService.dataObject.scriptMetadata;
	}, function() {
		if(queryService.dataObject.hasOwnProperty("scriptMetadata")) {
			$scope.inputs = [];
			if(queryService.dataObject.scriptMetadata.hasOwnProperty("inputs")) {
					$scope.inputs = queryService.dataObject.scriptMetadata.inputs;
			}
		}
	});
	
	$scope.columns = [];
	
	$scope.$watch(function(){
		return queryService.queryObject.dataTable;
	}, function(){
		queryService.getDataColumnsEntitiesFromId(queryService.queryObject.dataTable.id, true);
		// reset these values when the data table changes
	});
	

	$scope.$watch(function(){
		return queryService.dataObject.columns;
	}, function(){
		if ( queryService.dataObject.columns != undefined ) {
			var columns = queryService.dataObject.columns;
			var orderedColumns = {};
			orderedColumns.all = [];
			for(var i = 0; i  < columns.length; i++) {
				if (columns[i].publicMetadata.hasOwnProperty("aws_metadata")) {
					var column = columns[i];
					orderedColumns.all.push({ id : column.id , title : column.publicMetadata.title } );
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata.hasOwnProperty("columnType")) {
						var key = aws_metadata.columnType;
						if(!orderedColumns.hasOwnProperty(key)) {
							orderedColumns[key] = [ { id : column.id, title : column.publicMetadata.title }];
						} else {
							orderedColumns[key].push({
														id : column.id,
														title : column.publicMetadata.title
							});
						}
					}
				}
			}
			$scope.columns = orderedColumns;
		}
	});
	
	queryService.queryObject.FilteredColumnRequest = [];

	$scope.$watchCollection('selection', function(newVal, oldVal){
		for(var i = 0; i < $scope.selection.length; i++) {
				if($scope.selection != undefined) {
					if ($scope.selection[i] != undefined){
						var selection = angular.fromJson($scope.selection[i]);
						if(queryService.queryObject.FilteredColumnRequest[i]){
							queryService.queryObject.FilteredColumnRequest[i].column = selection;
						} else {
							queryService.queryObject.FilteredColumnRequest[i] = {column : selection};
						}
						var columnSelected = selection;
						var allColumns = queryService.dataObject.columns;
						var column;
						for (var j = 0; j < allColumns.length; j++) {
							if(columnSelected != undefined) {
								if (columnSelected.id == allColumns[j].id) {
									column = allColumns[j];
								}
							}
						}
						if(column != undefined) {
							if(column.publicMetadata.hasOwnProperty("aws_metadata")) {
								var metadata = angular.fromJson(column.publicMetadata.aws_metadata);
								if (metadata.hasOwnProperty("varType")) {
									if (metadata.varType == "continuous") {
										$scope.filterType[i] = "continuous";
										if(metadata.hasOwnProperty("varRange")) {
											$scope.show[i] = true;
											$scope.sliderOptions[i] = { range:true, min: metadata.varRange[0], max: metadata.varRange[1]};
										}
									} else if (metadata.varType == "categorical") {
										$scope.show[i] = true;
										$scope.filterType[i] = "categorical";
										if(metadata.hasOwnProperty("varValues")) {
											//console.log(metadata.varValues);
											$scope.categoricalOptions[i] = queryService.getDataMapping(metadata.varValues);
										}
									}
								}
							} 
						}
					} // end if ""
				} // end if undefined
			}
	});
		
	$scope.$watchCollection('filterValues', function(){
		//console.log($scope.filterValues);
		for(var i = 0; i < $scope.filterValues.length; i++) {
			if(($scope.filterValues != undefined) && $scope.filterValues != "") {
				if($scope.filterValues[i] != undefined && $scope.filterValues[i] != []) {
					
					var temp = $.map($scope.filterValues[i],function(item){
						return angular.fromJson(item);
					});
					
					if(!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
						queryService.queryObject.FilteredColumnRequest[i].filters = {};
					}
					
					if ($scope.filterType[i] == "categorical") { 
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = temp;
					} else if ($scope.filterType[i] == "continuous") { // continuous, we want arrays of ranges
						queryService.queryObject.FilteredColumnRequest[i].filters.filterValues = [temp];
					}
				} 
			}
		}
	});
	$scope.$watchCollection('enabled', function(){
		if($scope.enabled != undefined) {
			for(var i = 0; i < $scope.enabled.length; i++) {
				if(!queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
					queryService.queryObject.FilteredColumnRequest[i].filters = {};
				}
				
				if($scope.enabled[i] != undefined) {
					queryService.queryObject.FilteredColumnRequest[i].filters.enabled = $scope.enabled[i];
				}
				
//				console.log($scope.enabled);
//				console.log($scope.filterType);
//				console.log($scope.show);
			}
		}
	});
	
	$scope.$watchCollection(function(){
			return queryService.queryObject.FilteredColumnRequest;
	}, function() {
		if(queryService.queryObject.FilteredColumnRequest != undefined) {
			for(var i = 0; i < queryService.queryObject.FilteredColumnRequest.length; i++) {
				if (queryService.queryObject.FilteredColumnRequest[i] != undefined && queryService.queryObject.FilteredColumnRequest[i] != "") {
					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("column")) {
						$scope.selection[i] = angular.toJson(queryService.queryObject.FilteredColumnRequest[i].column);
					}
					
					if (queryService.queryObject.FilteredColumnRequest[i].hasOwnProperty("filters")) {
						
						if(queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("filterValues")) {

							$scope.show[i] = true;
							
							if(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Object) {
								
								$scope.filterType[i] = "categorical";
								var temp =  $.map(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues, function(item){
									return angular.toJson(item);
								});
								$scope.filterValues[i] = temp;
								
							} else if(queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0].constructor == Array) {
								$scope.filterType[i] = "continuous";
								$scope.filterValues[i] = queryService.queryObject.FilteredColumnRequest[i].filters.filterValues[0];
							}
						} 
						if(queryService.queryObject.FilteredColumnRequest[i].filters.hasOwnProperty("enabled")) {
							$scope.enabled[i] = queryService.queryObject.FilteredColumnRequest[i].filters.enabled;
						} 
					} 
				}
			}
		}
	});
})