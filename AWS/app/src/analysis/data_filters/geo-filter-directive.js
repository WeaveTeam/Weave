/**
 * directive for creating a geo filter
 */

AnalysisModule.directive('geoFilter', ['geoService','d3Service',  function factory(geoService, d3Service){
	
	var directiveDefnObject = {
			restrict : 'E',
			templateUrl : 'src/analysis/data_filters/geographyFilter.tpl.html',
			controller : function($scope,geoService, d3Service){
				
				var dom_element_to_append_to = document.getElementById('mapDisplay');
				
				$scope.stateGeometry = {file: "lib/us_topojson.json"};
				$scope.countyGeometry = {file : "lib/us_counties.json"};
				
				//watching state layer
				$scope.$watch('stateGeometry.checked', function(){
					if($scope.stateGeometry.checked){//getting state geojson
						d3Service.renderLayer(dom_element_to_append_to, $scope.stateGeometry.file);
						
					}
				});
				
				//watching county layer
				$scope.$watch('countyGeometry.checked', function(){
					if($scope.countyGeometry.checked)
						d3Service.renderLayer(dom_element_to_append_to, $scope.countyGeometry.file);
				});
			},
			link : function(scope, elem, attrs){
			
			}
			
	};
	
	return directiveDefnObject;
}]);

var blah;

AnalysisModule.service('geoService', [function(){
	
	blah = this.selectedStates= [];
	
	
}]);