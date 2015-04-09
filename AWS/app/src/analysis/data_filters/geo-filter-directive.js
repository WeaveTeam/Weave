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
				
				
				$scope.initialize = function(){
					
					var config = {
									container: dom_element_to_append_to, 
									margin: {top:5,bottom:5,left:5,right:5},
									fileName:$scope.topoJsonPath,
									stateFile:"lib/us_states.csv",
									countyFile:"lib/us_counties.csv"
								};
					
					//d3Service.renderLayer(dom_element_to_append_to, $scope.topoJsonPath, $scope.queryService.queryObject.GeographyFilter.geometrySelected);
					d3Service.createMap(config);
				}();
				
				$scope.$watchCollection(
						'[queryService.queryObject.GeographyFilter.stateColumn,queryService.queryObject.GeographyFilter.countyColumn]', 
						function(){
					
						if($scope.queryService.queryObject.GeographyFilter.geometrySelected){
						//d3Service.renderLayer(dom_element_to_append_to, $scope.topoJsonPath, $scope.queryService.queryObject.GeographyFilter.geometrySelected);
						d3Service.renderMap($scope.queryService);
					}
					if($scope.queryService.queryObject.GeographyFilter.geometrySelected == 'State')
						$scope.queryService.queryObject.GeographyFilter.countyColumn = "";
					else
						$scope.queryService.queryObject.GeographyFilter.stateColumn = '';
					
				});
				
				//renders layer once geography column is selected
				$scope.renderLayer = function(){

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