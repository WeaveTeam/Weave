GeoModule = angular.module('aws.analysis.geography', []); 
GeoModule.controller('GeographyControl', function($scope, queryService){
	
	queryService.queryObject.GeographyFilter = {
			state : {},
			counties : {}
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
				queryService.queryObject.GeographyFilter.counties = "";
			}
		};
	});
});