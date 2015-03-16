/**
 * directive for creating a geo filter
 */

AnalysisModule.directive('geoFilter', ['geoService','d3Service',  function factory(geoService, d3Service){
	
	var directiveDefnObject = {
			restrict : 'E',
			templateUrl : 'src/analysis/data_filters/geographyFilter.tpl.html',
			controller : function($scope,geoService, d3Service){
				
				var dom_element_to_append_to = document.getElementById('mapDisplay');
				
				$scope.stateGeometry = {file: "lib/us_states.json"};
				
				$scope.$watch('stateGeometry.checked', function(){
					if($scope.stateGeometry.checked){//getting state geojson
						d3Service.loadJson(dom_element_to_append_to, $scope.stateGeometry.file);
						
					}
				} );
			},
			link : function(scope, elem, attrs){
			
			}
			
	};
	
	return directiveDefnObject;
}]);


AnalysisModule.service('geoService', [function(){
	
	this.selectedStates= [];
	
}]);