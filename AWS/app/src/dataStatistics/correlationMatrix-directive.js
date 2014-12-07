/**
 * this directive contains the UI and logic for the correlation Matrix
 */

dataStatsModule.directive('correlationMatrix', function factory(){
	var directiveDefnObj= {
			restrict : 'E', //restricts the directive to a specific directive declaration style.in this case as element
			scope : {//isolated scope, its parent is the scope of the correlation matrix tab in dataStatsMain.tpl.html
					data: '='
			},
			templateUrl: 'src/dataStatistics/correlationMatrices.tpl.html',
			//this is the scope against the templateUrl i.e.src/dataStatistics/correlationMatrices.tpl.htm
			controller : function($scope, $compile, pearsonCoeff,spearmanCoeff, queryService){

				$scope.selectedCoeff = {label : "", scriptName : ""};
				
				$scope.availableCoeffList = [pearsonCoeff, spearmanCoeff];
				$scope.correlationMatrix = [];
				
				
				//calculates the correlation coefficient in R
				$scope.calculateCoefficient = function(scriptName){
					
					queryService.getDataFromServer($scope.data).then(function(sucess){
						
						if(success){
							queryService.runScript(scriptName).then(function(resultData){
								if(resultData){
									that.cache.calculatedStats = resultData;
								}
							});
						}
					});
				};
				
			},
			//scope: the isolated scope against the template url
			//elem :The jQLite wrapped element on which the directive is applied.  
			//attrs : any attributes that may have been applied on the directive element for e.g.<aws-select-directive style = "padding-top: 5px"></aws-select-directive>
			link: function(scope, elem, attrs){
				var array1 = [1,6,9,4,5];
				var array2= [2,7,8,3,10];
				var data = [array1, array2];
				
				var margin = {top: 20, right: 20, bottom: 20, left: 20},
			    width = 250 - margin.left - margin.right,//260
			    height = 250 - margin.top - margin.bottom;

		
				var rowScale = d3.scale.linear()
				    .range([0, width])
				    .domain([0,data[0].length]);
		
				var colScale = d3.scale.linear()
				    .range([0, height])
				    .domain([0,data.length]);
		
				var colorLow = 'green', colorMed = 'yellow', colorHigh = 'red';
		
				var colorScale = d3.scale.linear()
				     .domain([0, 5, 10])
				     .range([colorLow, colorMed, colorHigh]);
		
		
				var mysvg = d3.select("#corM").append("svg")
				    .attr("width", width + margin.left + margin.right)
				    .attr("height", height + margin.top + margin.bottom)
				    .append("g")
				    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
		
				var rows = mysvg.selectAll(".row")
				             .data(data)
				           .enter().append("svg:g")
				             .attr("class", "row"); 
		
				var cols = rows.selectAll(".cell")
				    .data(function (d,i) { return d.map(function(a) { return {value: a, rows: i}; } ) })
				           .enter().append("svg:rect")
				             .attr("x", function(d, i) { return rowScale(i); })
				             .attr("y", function(d, i) { return colScale(d.rows); })
				             .attr("width", rowScale(1))
				             .attr("height", colScale(1))
				             .style("fill", function(d) { return colorScale(d.value); });

//				var sampleSVG = d3.select("#corM")
//			    .append("svg")
//			    .attr("width", 100)
//			    .attr("height", 100);    
//			
//				sampleSVG.append("circle")
//			    .style("stroke", "gray")
//			    .style("fill", "white")
//			    .attr("r", 40)
//			    .attr("cx", 50)
//			    .attr("cy", 50)
//			    .on("mouseover", function(){d3.select(this).style("fill", "red");})
//			    .on("mouseout", function(){d3.select(this).style("fill", "white");});
				
				/****************************************************the Actual HEATMAP visualization********************************************/
				
				
				//executed when any part of the directive elem is clicked
				// elem.bind('click', function(){
				// console.log("ruuuuuuuuuuun", elem);
				// });
			}
	};
	
	return directiveDefnObj;
});

