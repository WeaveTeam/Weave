/**
 * directive for creating a geo filter
 */

AnalysisModule.directive('geoFilter', ['queryService', 'd3Service',  function factory(queryService, d3Service){
	
	var directiveDefnObject = {
			restrict : 'E',
			templateUrl : 'src/analysis/data_filters/geographyFilter.tpl.html',
			controller : function($scope, queryService, d3Service){
				
				var dom_element_to_append_to = document.getElementById('mapDisplay');
				$scope.topoJsonPath = "lib/us_topojson.json";
				 $scope.geometry = {selected: ""};
				
				//watching geometry layer
				$scope.$watch('geometry.selected', function(){
					if($scope.geometry.selected)
						d3Service.renderLayer(dom_element_to_append_to, $scope.topoJsonPath, $scope.geometry.selected);
				});
				
			},
			link : function(scope, elem, attrs){
			
			}
			
	};
	
	return directiveDefnObject;
}]);

var blah;

AnalysisModule.service('geoService', [function(){
	
	blah = this.selectedStates= {};
	
	
}]);