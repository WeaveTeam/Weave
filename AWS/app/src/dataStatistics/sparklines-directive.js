/**
 * this directive contains the UI and logic for the sparklines drawn for each numerical column
 */

dataStatsModule.directive('sparkLine',['queryService', 'statisticsService',
                                               function factory(queryService, statisticsService){
	var directiveDefnObj= {
			restrict: 'E',
			scope : {
				
					//data: '='//data that describes the column breaks and column counts in each bin for each numerical column
			},
			templateUrl: 'src/dataStatistics/sparklines_directive_content.tpl.html',
			controller : function($scope, queryService, statisticsService){
				
			},
			link: function(scope, elem, attrs){
			
			}//end of link function
	};
	
	return directiveDefnObj;
}]);

