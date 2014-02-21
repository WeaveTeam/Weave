angular.module("aws.analysis.geography", [])
.controller("GeographyCtrl", function($scope, queryService){
	
	queryService.queryObject.Geography = {
			state : {},
			counties : {}
	};
	
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
	
	$scope.stateOptions = $.map(metadata, function(item){
		return {value : item.value, label : item.label};
	});
	
	$scope.$watch('stateSelection', function() {
		if($scope.stateSelection != undefined && $scope.stateSelection != "") {
			var state = angular.fromJson($scope.stateSelection);
			queryService.queryObject.Geography.state = state;
			console.log(state);
			for(var i in metadata) {
				if(metadata[i].value == state.value) {
					$scope.countyOptions =  metadata[i].counties;
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