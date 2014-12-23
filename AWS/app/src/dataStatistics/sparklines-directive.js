/**
 * this directive contains the UI and logic for the sparklines drawn for each numerical column
 */

dataStatsModule.directive('sparkLine',['queryService', 'statisticsService','d3Service',
                                               function factory(queryService, statisticsService, d3Service){
	var directiveDefnObj= {
			restrict: 'E',
			scope : {
				
					//data: '='//data that describes the column breaks and column counts in each bin for each numerical column
			},
			templateUrl: 'src/dataStatistics/sparklines_directive_content.tpl.html',
			controller : function($scope, queryService, statisticsService){
				$scope.statisticsService = statisticsService;
			},
			link: function(scope, elem, attrs){
				//TODO confirm if this is the rightway of doing it. 
			
				scope.data = {breaks:[0,0.25,0.5,0.75,1.0], counts:{"sampleColumn" :[6,2,2,8,2]}};//breaks and counts for a single column
				
				var dom_element_to_append_to = document.getElementById('singleContainer');
				
				//service call for drawing sparklines
				d3Service.drawSparklines(dom_element_to_append_to, scope.data);
				
			}//end of link function
	};
	
	return directiveDefnObj;
}]);

