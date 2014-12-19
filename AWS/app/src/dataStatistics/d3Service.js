/**
 *this service contains all the functions needed for D3 visualizations 
 *TODO move to an independent D3 module later 
 */

dataStatsModule.service('d3Service', ['$q', function($q){
	
	/**
	 * function to draw a heatmap using a matrix computed in R/STATA
	 * @param dom_element_to_append_to: the HTML element to which the heatmap D3 viz is appended
	 * @param data: the computed matrix   
	 */
	this.drawCorrelationHeatMap = function(dom_element_to_append_to, data){
		
		    // If we don't pass any data, return out of the element
		    if (!data) return;
		    
			var margin = {top: 100, right: 40, bottom: 40, left: 100};
			var  width = (dom_element_to_append_to.offsetWidth) - margin.left - margin.right;
		    var height = (dom_element_to_append_to.offsetHeight) - margin.top - margin.bottom;
	
	        // Scaling Functions
			var rowScale = d3.scale.linear().range([0, width]).domain([0,data[0].length]);
	
			var colScale = d3.scale.linear().range([0, height]).domain([0,data.length]);
	
			var colorLow = 'green', colorMed = 'yellow', colorHigh = 'red';
	
			var colorScale = d3.scale.linear()
			     .domain([0, 5, 10])//TODO parameterize this according to the matrix  
			     .range([colorLow, colorMed, colorHigh]);
	
			// SVG Creation	
			var mysvg = d3.select(dom_element_to_append_to).append("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom)
			.append("g")
			.attr("transform", "translate(" + margin.left + "," + margin.top + ")");
			// remove all previous items before render
		    //mysvg.selectAll('*').remove();
			
			//tooltip
			var tooltip = d3.select(dom_element_to_append_to)
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
	//		rowObjects.append("text")
	//	      .attr("x", -6)
	//	      .attr("y", function(d, i) { return colScale(i); })
	//	      .attr("dy", "4.96em")
	//	      .attr("text-anchor", "end")
	//	      .text(function(d, i) { return colNames[i]; });
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
	
			//labels for every cell
	//		 var label = rowObjects.selectAll(".label")
	//		 .data(function (d,i)
	//		    		{ 
	//		    			return d.map(function(a) 
	//		    				{ 
	//		    					return {value: a, row: i};} ) ;
	//					})
	//		 .enter().append('svg:text')
	//		 .attr('x', function(d,i){return rowScale(i);})
	//		 .attr('y', function(d,i) {return colScale(d.row);})
	//		 .attr('class','label')
	//         .style('text-anchor','middle')
	//         .text(function(d) {return d.value;});
	//		 
	//		 console.log("labels", label);
		 
		 
		 
	};
	
}]);