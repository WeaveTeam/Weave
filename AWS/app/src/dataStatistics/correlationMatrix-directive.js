/**
 * this directive contains the UI and logic for the correlation Matrix
 */

dataStatsModule.directive('correlationMatrix',['pearsonCoeff','spearmanCoeff','queryService', 'statisticsService','d3Service',
                                               function factory(pearsonCoeff, spearmanCoeff, queryService, statisticsService, d3Service){
	var directiveDefnObj= {
			restrict : 'E', //restricts the directive to a specific directive declaration style.in this case as element
			scope : {//isolated scope, its parent is the scope of the correlation matrix tab in dataStatsMain.tpl.html
					data: '='
			},
			templateUrl: 'src/dataStatistics/corr_Matrices_directive_content.tpl.html',
			//this is the scope against the templateUrl i.e.src/dataStatistics/correlationMatrices.tpl.htm
			controller : function($scope, pearsonCoeff,spearmanCoeff, queryService, statisticsService){
				$scope.statsService = statisticsService;
				
				$scope.selectedCoeff = {label : "", scriptName : ""};
				$scope.availableCoeffList = [pearsonCoeff, spearmanCoeff];
				
				//calculates the correlation coefficient in R
				$scope.calculateCoefficient = function(scriptName){
					
					statisticsService.calculateStats(scriptName, queryService.cache.numericalColumns, "CorrelationMatrix", true);

				};
				
			},
			//scope: the isolated scope against the template url
			//elem :The jQLite wrapped element on which the directive is applied.  
			//attrs : any attributes that may have been applied on the directive element for e.g.<aws-select-directive style = "padding-top: 5px"></aws-select-directive>
			link: function(scope, elem, attrs){
				
				//**************************************CORRELATON MATRIX VIZ ***********************************
				
				var array1 = [1,6,9,4,5];
				var array2= [6.6,2,5,3,10];
				var array3= [2,7,8,6.3,1];
				var array4= [4,2,5,3,1.9];
				var array5= [1,3.4,5,3,10];
				var mydata = [array1, array2, array3, array4];
			
				
				var dom_element_to_append_to = document.getElementById('corM');
				//d3Service.drawCorrelationHeatMap(dom_element_to_append_to, mydata);
				
				//**************************************SCOPE WATCHES***********************************
				scope.$watch(function(){
					return scope.statsService.cache.correlationMatrix;
				}, function(){
						data = scope.statsService.cache.correlationMatrix;
						console.log("data", data);
						if(data.resultData)
							{
								if(data.resultData.length > 0)
								d3Service.drawCorrelationHeatMap(dom_element_to_append_to,data.resultData[0], scope.statsService.cache.columnTitles);
							}
				});

			}
	};
	
	return directiveDefnObj;
}]);

