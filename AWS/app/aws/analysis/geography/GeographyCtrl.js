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
		queryService.getDataSetFromTableId();
	});
	
	$scope.$watch(function() {
		return queryService.dataObject.geographyMetadata;
	}, function() {
		
		geographyMetadata = queryService.dataObject.geographyMetadata;

		
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
				case "FIPS Name":
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
			for(key in geographyMetadata.records) {
				record = geographyMetadata.records[key];
				for(var i in processedMetadata) {
					if(processedMetadata[i].value == record[stateValueKey]) {
						processedMetadata[i].counties.push({value : record[countyValueKey],
							label : record[countyLabelKey]});
					} else {
						// we found a new state
						processedMetadata[i].push({value : record[stateValueKey], 
							label : record[stateLabelKey],
							counties : [{value : record[countyValueKey],
								label : record[countyLabelKey]
							
							}]});
					}
				} 
				
			}
		}
		console.log(processedMetadata);
	});

	var metadata = [ {
		value : "01",
		label : "Alabama",
		counties : [
		            {
		            	value : 001,
		            	label : "Autauga"
		            },
		            {
		            	value : 003,
		            	label : "Baldwin"
		            },
		            {
		            	value : 005,
		            	label : "Barbour"
		            }
		            
		            ]
		},
		{
			value : "02",
			label : "Alaska",
			counties : [
			            {
			            	value : 013,
			            	label : "Aleutians East"
			            },
			            {
			            	value : 016,
			            	label : "Aleutians West"
			            },
			            {
			            	value : 020,
			            	label : "Anchorage"
			            }
			            
			            ]
			},
			{
				value : "04",
				label : "Arizona",
				counties : [
				            {
				            	value : 001,
				            	label : "Apache"
				            },
				            {
				            	value : 003,
				            	label : "Chochise"
				            },
				            {
				            	value : 005,
				            	label : "Coconino"
				            }
				            
				            ]
				}
		
	
	];
	
	$scope.stateOptions = $.map(processedMetadata, function(item){
		return {value : item.value, label : item.label};
	});
	
	$scope.$watch('stateSelection', function() {
		if($scope.stateSelection != undefined && $scope.stateSelection != "") {
			var state = angular.fromJson($scope.stateSelection);
			queryService.queryObject.Geography.state = state;
			console.log(state);
			for(var i in processedMetadata) {
				if(metadata[i].value == state.value) {
					$scope.countyOptions =  processedMetadata[i].counties;
					break;
				}
			}
		}
	});
	
	$scope.$watch('countySelection', function() {
		if($scope.countySelection != undefined && $scope.countySelection != "") {
			queryService.queryObject.Geography.counties = $.map($scope.countySelection, function(item){
				return angular.fromJson(item);
			});
		};
	});
});