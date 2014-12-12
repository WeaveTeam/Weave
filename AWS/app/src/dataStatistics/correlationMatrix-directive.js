/**
 * this directive contains the UI and logic for the correlation Matrix
 */

dataStatsModule.directive('correlationMatrix',['pearsonCoeff','spearmanCoeff','queryService', 'statisticsService',
                                               function factory(pearsonCoeff, spearmanCoeff, queryService, statisticsService){
	var directiveDefnObj= {
			restrict : 'E', //restricts the directive to a specific directive declaration style.in this case as element
			scope : {//isolated scope, its parent is the scope of the correlation matrix tab in dataStatsMain.tpl.html
					data: '='
			},
			templateUrl: 'src/dataStatistics/corr_Matrices_directive_content.tpl.html',
			//this is the scope against the templateUrl i.e.src/dataStatistics/correlationMatrices.tpl.htm
			controller : function($scope, $compile, pearsonCoeff,spearmanCoeff, queryService, statisticsService){
				$scope.correlationMatrix= null;
				$scope.selectedCoeff = {label : "", scriptName : ""};
				
				$scope.availableCoeffList = [pearsonCoeff, spearmanCoeff];
				//the actual matrix that populates the D3 viz
				$scope.statsService = statisticsService;
				
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
				//var mydata = [array1, array2, array3, array4];
				var colNames = ["col1", "col2", "col3","col4"];

				
				var drawCorrelationHeatMap = function(data){
					//TODO remove previous svg
					var margin = {top: 100, right: 40, bottom: 40, left: 100};
					var  width = ($('#corM').width()) - margin.left - margin.right;
				    var height = ($('#corM').height()) - margin.top - margin.bottom;

			        // Scaling Functions
					var rowScale = d3.scale.linear().range([0, width]).domain([0,data[0].length]);
			
					var colScale = d3.scale.linear().range([0, height]).domain([0,data.length]);
			
					var colorLow = 'green', colorMed = 'yellow', colorHigh = 'red';
			
					var colorScale = d3.scale.linear()
					     .domain([0, 0.5, 1.0])//TODO parameterize this according to the matrix  
					     .range([colorLow, colorMed, colorHigh]);
			
					// SVG Creation	
					var mysvg = d3.select("#corM").append("svg")
					    .attr("width", width + margin.left + margin.right)
					    .attr("height", height + margin.top + margin.bottom)
					    .append("g")
					    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
			
					console.log("svg", mysvg);
					
					//tooltip
					var tooltip = d3.select("#corM")
					.append("div")
					.style("position", "absolute")
					.style("z-index", "10")
					.style("visibility", "hidden")
					.text("");
					
					//row creation
					var rowObjects = mysvg.selectAll(".row")//.row is a predefined grid class
					             .data(data)
					             .enter().append("svg:g")
					             .attr("class", "row");
					console.log("row", rowObjects);
					//appending text for row
//					rowObjects.append("text")
//				      .attr("x", -6)
//				      .attr("y", function(d, i) { return colScale(i); })
//				      .attr("dy", "4.96em")
//				      .attr("text-anchor", "end")
//				      .text(function(d, i) { return colNames[i]; });
//			
					var rowCells = rowObjects.selectAll(".cell")
					    .data(function (d,i)
					    		{ 
					    			return d.map(function(a) 
					    				{ 
					    					return {value: a, row: i};} ) ;
    							})//returning a key function
					           .enter().append("svg:rect")
					             .attr("x", function(d, i) {  return rowScale(i); })
					             .attr("y", function(d, i) { return colScale(d.row); })
					             .attr("width", rowScale(1))
					             .attr("height", colScale(1))
					             .style("fill", function(d) { return colorScale(d.value);})
					             .style('stroke', "black")
					             .style('stroke-width', 1)
					             .style('stroke-opacity', 0)
					             .on('mouseover', function(d){ tooltip.style('visibility', 'visible' ).text(d.value); 
					             							   d3.select(this).style('stroke-opacity', 1);})
					             .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
					             .on('mouseout', function(){ tooltip.style('visibility', 'hidden'); 
					             							 d3.select(this).style('stroke-opacity', 0);});
					             ;
					
					console.log("rowCells", rowCells);

//					 var label = rowObjects.selectAll(".label")
//					 .data(function (d,i)
//					    		{ 
//					    			return d.map(function(a) 
//					    				{ 
//					    					return {value: a, row: i};} ) ;
//    							})
//					 .enter().append('svg:text')
//					 .attr('x', function(d,i){return rowScale(i);})
//					 .attr('y', function(d,i) {return colScale(d.row);})
//					 .attr('class','label')
//			         .style('text-anchor','middle')
//			         .text(function(d) {return d.value;});
//					 
//					 console.log("labels", label);
					 
					 
					 
				};
				
				//drawCorrelationHeatMap(mydata);
				
				//**************************************SCOPE WATCHES***********************************
				scope.$watch(function(){
					return scope.statsService.cache.correlationMatrix;
				}, function(){
						data = scope.statsService.cache.correlationMatrix;
						console.log("data", data);
						if(data.length > 0)
						drawCorrelationHeatMap(data[0]);
				});


				//executed when any part of the directive elem is clicked
				// elem.bind('click', function(){
				// console.log("ruuuuuuuuuuun", elem);
				// });
			}
	};
	
	return directiveDefnObj;
}]);

