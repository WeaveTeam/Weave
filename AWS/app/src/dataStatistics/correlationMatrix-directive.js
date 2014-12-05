/**
 * this directive contains the UI and logic for the correlation Matrix
 */

dataStatsModule.directive('correlationMatrix', function factory(){
	var directiveDefnObj= {
			restrict : 'E', //restricts the directive to a specific directive declaration style.in this case as element
			template: '<div id="corM" style ="width:200px;height:200px; background-color:blue"></div>',
			//the scope is that of the parent controller
			//elem :The jQLite wrapped element on which the directive is applied.  
			//attrs : any attributes that may have been applied on the directive element for e.g.<aws-select-directive style = "padding-top: 5px"></aws-select-directive>
			link: function(scope, elem, attrs){
				
				 elem.bind('click', function(){
				  console.log("ruuuuuuuuuuun", elem);
				  });
				
				
				var sampleSVG = d3.select("#corM")
			    .append("svg")
			    .attr("width", 100)
			    .attr("height", 100);    
			
				sampleSVG.append("circle")
			    .style("stroke", "gray")
			    .style("fill", "white")
			    .attr("r", 40)
			    .attr("cx", 50)
			    .attr("cy", 50)
			    .on("mouseover", function(){d3.select(this).style("fill", "red");})
			    .on("mouseout", function(){d3.select(this).style("fill", "white");});
			}
	};
	
	return directiveDefnObj;
});
