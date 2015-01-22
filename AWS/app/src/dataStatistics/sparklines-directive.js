/**
 * this directive contains the UI and logic for the sparklines drawn for each numerical column
 */

dataStatsModule.directive('sparkLines',['queryService', 'statisticsService','d3Service',
                                               function factory(queryService, statisticsService, d3Service){
	var directiveDefnObj= {
			restrict: 'EA',
			scope : {
				
					data: '='//data that describes the column breaks and column counts in each bin for each numerical column !! gets populated asyncronously
			},
			templateUrl: 'src/dataStatistics/sparklines_directive_content.tpl.html',
			controller : function($scope, queryService, statisticsService){
				$scope.statisticsService = statisticsService;
				
				
			},
			link: function(scope, elem, attrs){
				//TODO confirm if this is the rightway of doing it. 
			
				//scope.data = {breaks:[0,0.25,0.5,0.75,1.0], counts:{"sampleColumn" :[6,4,2,8]}};//breaks and counts for a single column
				
				var dom_element_to_append_to = document.getElementById('singleContainer');
				
				scope.$watch(function(){
					return scope.data;//the data used for  creatign sparklines
				}, function(){
					if(scope.data){
						if(scope.data.breaks.length > 1){
							console.log("got it", scope.data);
							for(var i in scope.data.counts){
								
								//service call for drawing one sparkline one/column
								d3Service.drawSparklines(dom_element_to_append_to,{breaks: scope.data.breaks, counts : scope.data.counts[i], title:i});
							}
						}
					}
				});
								
			}//end of link function
	};
	
	return directiveDefnObj;
}]);

