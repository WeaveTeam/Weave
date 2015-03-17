/**
 *this service contains all the functions needed for D3 visualizations 
 *TODO move to an independent D3 module later 
 */
dataStatsModule.service('d3Service', ['$q','geoService',  function($q, geoService){
	var that = this;
	
	//is a pointer to the geomteries after being loaded the first time
	this.cache = {
			stateTopoGeometries : []
	};
	
	/**
	 * this function renders a map layer
	 * @param filename name if file to load
	 * @param run callback once loaded
	 */
	this.renderLayer = function(dom_element_to_append_to, filename){
		
		//clearing previous rendered stuff
		d3.select(dom_element_to_append_to).selectAll("*").remove();
		
		var margin = {top: 5, right: 5, bottom: 5, left: 5};
		var  width = (dom_element_to_append_to.offsetWidth) - margin.left - margin.right;
	    var height = (dom_element_to_append_to.offsetHeight) - margin.top - margin.bottom;
	    
	    //tooltip
	    var tooltip = d3.select(dom_element_to_append_to)
		.append("div")
		.style("position", "absolute")
		.style("z-index", "10")
		.style("visibility", "hidden")
		.text("")
		.style("color", "red")
		.style("font-weight", 'bold');
		
	    //projection
		var projection = d3.geo.albersUsa()
							   .translate([width/2, height/2])
							   .scale([550]);
		//path generator
		var path = d3.geo.path()
						 .projection(projection);
		
		var zoom = d3.behavior.zoom()
	    .translate(projection.translate())
	    .scale(projection.scale())
	    .scaleExtent([height, 8 * height])
	    .on("zoom", zoomed);
		
		// SVG Creation	
		var mysvg = d3.select(dom_element_to_append_to).append("svg")
		.attr("width", width + margin.left + margin.right)
		.attr("height", height + margin.top + margin.bottom);
		
		var g = mysvg.append("g")
	    .call(zoom);
		
		function zoomed() {
			  projection.translate(d3.event.translate).scale(d3.event.scale);
			  g.selectAll("path").attr("d", path);
		};
		
		function addlayer(geometries){
			//adding map layer
			g.selectAll("path")
			.data(geometries)
			.enter()
			.append("path")
			.attr("d", path)
			.style("fill", "#335555")
			.on('mouseover', function(d){
											tooltip.style('visibility', 'visible' ).text(d.properties.name); 
										})
			//handling selections							
			.on('click', function(d){
										//if it is selected for the first time
										if( $.inArray(d.properties.name, geoService.selectedStates) == -1){
											d3.select(this).style("fill", "yellow");
											geoService.selectedStates.push(d.properties.name);
										}
										//if already selected; remove it
										else{
											var index = $.inArray(d.properties.name, geoService.selectedStates);
											geoService.selectedStates.splice(index, 1);
											d3.select(this).style("fill", "#335555");
										}
										
									})
		    .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
		    .on('mouseout', function(){ tooltip.style('visibility', 'hidden');});
			
		};
		
		//if cached use cache
		if(that.cache.stateTopoGeometries.length > 1){
			
			addlayer(this.cache.stateTopoGeometries);
		}
		//loading for the first time
		else{
			
			d3.json(filename, function(error, geomJson){
				//adding state name property from csv to the topojson
				d3.csv("lib/us_states.csv", function(state_fips){
					
					var features = topojson.feature(geomJson, geomJson.objects.states).features;
					that.cache.stateTopoGeometries= features;
					
					for(i in state_fips){
						
						var fips = parseFloat(state_fips[i].US_STATE_FIPS_CODE);
						
						for(j in features){
							
							var id = features[j].id;
							
							if(fips == id){
								
								features[j].properties.name = state_fips[i].NAME10;
								break;
							}
						}//j loop
					}//i loop
					
					addlayer(features);	
					
				});//end of csv load
				
			});//end of json load
		}
		
		
	};
	
	
	/**
	 * function to draw a heatmap using a matrix computed in R/STATA
	 * @param dom_element_to_append_to: the HTML element to which the heatmap D3 viz is appended
	 * @param data: the computed matrix   
	 * @param columnTitles required for labeling the matrix
	 */
	this.drawCorrelationHeatMap = function(dom_element_to_append_to, data, columnTitles){
		//TODO does scope need to be passed into this service?
		console.log("columnTitles", columnTitles);
		    // If we don't pass any data, return out of the element
		    if (!data) return;
		    
			var margin = {top: 100, right: 20, bottom: 20, left: 100};
			var  width = (dom_element_to_append_to.offsetWidth) - margin.left - margin.right;
		    var height = (dom_element_to_append_to.offsetHeight) - margin.top - margin.bottom;
	
	        // Scaling Functions
			var rowScale = d3.scale.linear().range([0, width]).domain([0,data[0].length]);
	
			var colScale = d3.scale.linear().range([0, height]).domain([0,data.length]);
	
			var colorLow = 'green', colorMed = 'yellow', colorHigh = 'red';
	
			var colorScale = d3.scale.linear()
			     .domain([0, 0.5, 1.0])//TODO parameterize this according to the matrix  
			     .range([colorLow, colorMed, colorHigh]);
	
			
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
			//console.log("row", rowObjects);
			//appending text for row
			rowObjects.append("text")
		      .attr("x", -1)
		      .attr("y", function(d, i) { return colScale(i); })
		      .attr("dy", "1")
		      .attr("text-anchor", "end")
		      .text(function(d, i) { return columnTitles[i]; });
	
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
			             
			
			//console.log("rowCells", rowCells);
	
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
	
	/**
	 * this function draws the sparklines computed in R/STATA (one per column)
	 * @param dom_element_to_append_to :the HTML element to which the sparkline D3 viz is appended
	 * @param sparklineData : the distribution data calculated in R/STATA
	 */
	this.drawSparklines= function(dom_element_to_append_to, sparklineDatum){
		
		//data
		var breaks = sparklineDatum.breaks;
		var counts = sparklineDatum.counts;
		
		var margin = {top: 5, right: 5, bottom: 5, left: 5};
		var width = 60; var height= 60;

		//creating the svg
		var mysvg = d3.select(dom_element_to_append_to).append('svg')
					  .attr('fill', 'black')
					  .attr('width', width)//svg viewport dynamically generated
					  .attr('height', height )
					  .append('g')
					  .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
		//scales
		var heightScale = d3.scale.linear()
				  .domain([0, d3.max(counts)])
				  .range([height, 0]);//output should be between height and 0
		
		var widthScale = d3.scale.linear()
						   .domain([0, d3.max(breaks)])
						   .range([0, width]);
		
		//tooltip
		var tooltip = d3.select(dom_element_to_append_to)
		.append("div")
		.style("position", "absolute")
		.style("z-index", "10")
		.style("visibility", "hidden")
		.text("")
		.style("color", "red")
		.style("font-weight", 'bold');
		
		var barWidth = (width - margin.left - margin.right)/counts.length;
		
		//making one g element per bar 
		var bar = mysvg.selectAll("g")
	      			   .data(counts)
	      			   .enter().append("svg:g")
	      			   .attr("transform", function(d, i) { return "translate(" + (i * barWidth ) + ",0)"; });

		bar.append("rect")
	      .attr("y", function(d) { return heightScale(d); })
	      .attr("height", function(d) { return height - heightScale(d); })
	      .attr("width", barWidth)
	      .on('mouseover', function(d){ tooltip.style('visibility', 'visible' ).text(d); 
			             							   d3.select(this).style('stroke-opacity', 1);})
			             .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
			             .on('mouseout', function(){ tooltip.style('visibility', 'hidden'); 
			             							 d3.select(this).style('stroke-opacity', 0);});
		
	};
	
}]);