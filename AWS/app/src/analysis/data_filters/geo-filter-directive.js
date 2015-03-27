/**
 * directive for creating a geo filter
 */

AnalysisModule.directive('geoFilter', ['queryService', 'd3Service',  function factory(queryService, d3Service){
	
	var directiveDefnObject = {
			restrict : 'E',
			require : 'ngModel',
			templateUrl : 'src/analysis/data_filters/geographyFilter.tpl.html',
			controller : function($scope, queryService, d3Service){
				
				
				
				var dom_element_to_append_to = document.getElementById('mapDisplay');
				$scope.topoJsonPath = "lib/us_topojson.json";
				
				$scope.queryService = queryService;
				
				$scope.geometry = {selected: ""};
				
				//renders layer once geography column is selected
				$scope.renderLayer = function(){
					if($scope.geometry.selected)
						d3Service.renderLayer(dom_element_to_append_to, $scope.topoJsonPath, $scope.geometry.selected);
					if($scope.geometry.selected == 'State')
						$scope.queryService.queryObject.GeographyFilter.countyColumn = "";
					else
						$scope.queryService.queryObject.GeographyFilter.stateColumn = '';
					//console.log("ng-model", $scope.queryService.queryObject.GeographyFilter);
				};
				
			},
			link : function(scope, elem, attrs){
			
			}
			
	};
	
	return directiveDefnObject;
}]);

var blah;
var blha2;

AnalysisModule.service('geoService', [function(){
	
	blah = this.selectedGeographies= {};
	
	blah2 = this.selectedStatesWithCounties = {};
	
	
}]);