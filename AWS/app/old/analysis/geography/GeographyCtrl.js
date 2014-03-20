GeoModule = angular.module('aws.analysis.geography', []); 
GeoModule.controller('GeographyControl', function($scope, queryService){
	
	queryService.queryObject.GeographyFilter = {
			state : {},
			counties : {},
			stateColumn : {},
			stateColumn : {}
	};
	var stateValueKey = null;
	var stateLabelKey = null;
	var countyValueKey = null;
	var countyLabelKey = null;
	var processedMetadata = [];
	var geographyMetadata = null;
	
	$scope.$watch('geographyMetadataTableId', function() {
		queryService.queryObject.GeographyFilter.geographyMetadataTableId = $scope.geographyMetadataTableId;
		queryService.getDataSetFromTableId(2825);
	});
	
	$scope.$watch(function() {
		return queryService.dataObject.geographyMetadata;
	}, function() {
		
		geographyMetadata = queryService.dataObject.geographyMetadata;
		if(geographyMetadata) {
			
			// would need to be generalized later...
			for(var key in geographyMetadata.columns) {
				switch(geographyMetadata.columns[key].title) {
					case "FIPS State":
						stateValueKey = key;
						break;
					case "State":
						stateLabelKey = key;
						break;
					case "FIPS County":
						countyValueKey = key;
						break;
					case "County Name":
						countyLabelKey = key;
						break;
					default:
						break;
				}
			}	
			
			if(stateValueKey == null ||
			   stateLabelKey == null ||
			   countyValueKey == null ||
			   countyLabelKey == null) {
			   console.log("Could not find all the geography columns");
			} else {
				var records = geographyMetadata.records["US_FIPS_Codes"];
				for(key in records) {
					var record = records[key];
					// push the first state
					if(!processedMetadata.length) {
						processedMetadata.push({value : record[stateValueKey], 
							label : record[stateLabelKey],
							counties : []});
					}
					
					for(var i = 0; i < processedMetadata.length; i++) {
						if(record[stateValueKey] == processedMetadata[i].value) {
							processedMetadata[i].counties.push({value : record[countyValueKey],
								label : record[countyLabelKey]});
						break;
						}
						
						else if( record[stateValueKey] != processedMetadata[i].value ) {
							
							if (i == processedMetadata.length - 1){
						
								// we r	eached the end of the processedMetadata array without finding the corresponding state,
								// which means it's a new state
								processedMetadata.push({value : record[stateValueKey], 
									label : record[stateLabelKey],
									counties : [{value : record[countyValueKey],
									label : record[countyLabelKey]
								
								}]});
							} else {
								//continue the search
								continue;
							}
						}
					} 
					
				}
			}
		}
		
	});

	$scope.stateOptions = processedMetadata;
	
	$scope.$watch('stateSelection', function() {
		if($scope.stateSelection != undefined && $scope.stateSelection != "") {
			var state = angular.fromJson($scope.stateSelection);
			queryService.queryObject.GeographyFilter.state = { value : state.value, label : state.label};
			for(var i in processedMetadata) {
				if(processedMetadata[i].value == state.value) {
					$scope.countyOptions =  processedMetadata[i].counties;
					break;
				}
			}
		}
	});
	
	$scope.$watch('countySelection', function() {
		if($scope.countySelection != undefined) {
			if( $scope.countySelection != "") {
				queryService.queryObject.GeographyFilter.counties = $.map($scope.countySelection, function(item){
					return angular.fromJson(item);
				});
			} else {
				queryService.queryObject.GeographyFilter.counties = [];
			}
		};
	});
	
	$scope.$watch(function() {
		return queryService.queryObject.dataTable;
	}, function() {
		if(queryService.queryObject.dataTable.hasOwnProperty("title")) {
			$scope.dataTableTitle = queryService.queryObject.dataTable.title;
		}
	});
	
	$scope.$watch(function() {
		return queryService.dataObject.columns;
	}, function() {
		if(queryService.dataObject.columns != undefined) {
			
			$scope.stateDBOptions = $.map(queryService.dataObject.columns, function(column) {
					var aws_metadata = angular.fromJson(column.publicMetadata.aws_metadata);
					if(aws_metadata != undefined){
						if(aws_metadata.hasOwnProperty("columnType")) {
							if(aws_metadata.columnType == "geography") {
								return { id : column.id , title : column.publicMetadata.title};
							} else {
								// skip
							}
						}
					}
				});
			$scope.countyDBOptions = $scope.stateDBOptions;
		};
	});
	
	$scope.$watch('stateDBSelection', function() {
		if($scope.stateDBSelection != undefined) {
			if($scope.stateDBSelection != "") {
				queryService.queryObject.GeographyFilter.stateColumn = angular.fromJson($scope.stateDBSelection);
			} else {
				queryService.queryObject.GeographyFilter.stateColumn = {};
			}
		}
	});
	
	$scope.$watch('countyDBSelection', function() {
		if($scope.stateDBSelection != undefined) {
			if($scope.stateDBSelection != "") {
				queryService.queryObject.GeographyFilter.countyColumn = angular.fromJson($scope.countyDBSelection);
			} else {
				queryService.queryObject.GeographyFilter.countyColumn = {};
			}
		}
	});
});