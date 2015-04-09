/**
 *this service contains all the functions needed for D3 visualizations 
 *TODO move to an independent D3 module later 
 */
dataStatsModule.service('d3Service', ['$q','geoService',   function($q, geoService){
	var that = this;
	
	this.mapT = new  d3_viz.mapTool();
	
	this.createMap = function(config){
		this.mapT.intializeChart(config);
	};
	this.renderMap = function(queryService){
		
		this.mapT.renderLayer(queryService.queryObject.GeographyFilter.geometrySelected,
							  queryService.queryObject.GeographyFilter.selectedStates,
							  queryService.queryObject.GeographyFilter.selectedCounties	);
		
	};
	
	//is a pointer to the geomteries after being loaded the first time
	this.cache = {
			stateTopoGeometries : [],
			countyTopoGeometries : [],
			US: []
	};
	
	/**
	 * this function renders a map layer
	 * @param filename name if file to load
	 * @param run callback once loaded
	 */
	this.renderLayer = function(dom_element_to_append_to, filename, heirarchyLevel){
		
		//clearing previous rendered stuff
		d3.select(dom_element_to_append_to).selectAll("*").remove();
		
		var margin = {top: 5, right: 5, bottom: 5, left: 5};
		var  width = (dom_element_to_append_to.offsetWidth) - margin.left - margin.right;
	    var height = (dom_element_to_append_to.offsetHeight) - margin.top - margin.bottom;
	    var centered;

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
		
		
		if(that.cache.US.length == 0)
		{//first time call
			d3.json(filename, function(error, USGeometries){
				
				that.cache.US = USGeometries;
				
				var states = topojson.feature(USGeometries, USGeometries.objects.states);
				that.cache.stateTopoGeometries = states;
				
				var counties = topojson.feature(USGeometries, USGeometries.objects.counties);
				that.cache.countyTopoGeometries = counties;
				
				
				if(heirarchyLevel == 'State'){//handling state level geometries
					handleStateLayer();
				}
				else if(heirarchyLevel == 'County'){ //handling county level
					
					handleCountyLayer();
				}
				else{
					//handling country level
				}
			});
		}
		else//use cache
		{
			if(heirarchyLevel == 'State'){
				
				addStatelayer(that.cache.stateTopoGeometries.features);	
			}
			else if(heirarchyLevel == 'County'){
				
				if('name' in that.cache.countyTopoGeometries.features[0].properties)//if this property has been assigned add it
					addCountyLayer(that.cache.countyTopoGeometries.features);
				else
					handleCountyLayer();
			}
			else{
				//handling country level
			}
			
		}
		
		
		function handleStateLayer(){
			//adding state name property from csv to the topojson
			d3.csv("lib/us_states.csv", function(state_fips){
				
				for(i in state_fips){
					
					var fips = parseFloat(state_fips[i].US_STATE_FIPS_CODE);
					
					for(j in that.cache.stateTopoGeometries.features){
						
						var id = that.cache.stateTopoGeometries.features[j].id;
						
						if(fips == id){
							
							that.cache.stateTopoGeometries.features[j].properties.name = state_fips[i].NAME10;
							break;
						}
					}//j loop
				}//i loop
				
				addStatelayer(that.cache.stateTopoGeometries.features);	
				
			});//end of csv load
		}
		
		function handleCountyLayer(){
			//adding county name property from csv to topojson
			d3.csv("lib/us_counties.csv", function(county_fips){
				
				for(i in county_fips){
					
					var county_fips_code = parseFloat(county_fips[i].FIPS);
					
					for(j in that.cache.countyTopoGeometries.features){
						
						var id = that.cache.countyTopoGeometries.features[j].id;
						
						if(county_fips_code == id){
							that.cache.countyTopoGeometries.features[j].properties.name = county_fips[i].County_Name;
							that.cache.countyTopoGeometries.features[j].properties.state = county_fips[i].State_Name;
							that.cache.countyTopoGeometries.features[j].properties.stateAbbr = county_fips[i].State_Abbr;
							that.cache.countyTopoGeometries.features[j].properties.stateId = parseFloat(county_fips[i].STFIPS);
							break;
						}
					}//j loop
				}//i loop
				
				addCountyLayer(that.cache.countyTopoGeometries.features);
				
			});//end of csv load
		}
					
		
		//d3 code for state level
		function addStatelayer(geometries){
			
			// SVG Creation	
			var stateSvg = d3.select(dom_element_to_append_to).append("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom);
			
			//clearing previous layers
			//mysvg.selectAll("*").remove();
			
			var zoom = d3.behavior.zoom()
		    .translate(projection.translate())
		    .scale(projection.scale())
		    .scaleExtent([height, 8 * height])
		    .on("zoom", zoomed);
			
			var g = stateSvg.append("g")
		    .call(zoom);
			
			function zoomed() {
				  projection.translate(d3.event.translate).scale(d3.event.scale);
				  g.selectAll("path").attr("d", path);
			};
			
			
			//adding map layer
			this._states = g.selectAll("path")
			.data(geometries)
			.enter()
			.append("path")
			.attr("d", path)
			.style("fill", "#335555");
			
			//handling selections							
			this._states
			.on('click', function(d){
				//if it is selected for the first time
				if(!(d.id in geoService.selectedGeographies)){
					d.selected = true;
					//d3.select(this).style("fill", "yellow");
					geoService.selectedGeographies[d.id] = { title: d.properties.name };
				}
				//if already selected; remove it
				else{
					d.selected = false;
					delete geoService.selectedGeographies[d.id];
					//d3.select(this).style("fill", "#335555");
				}
				
				this._states.classed("selected", function(d){
					return d.selected;
				})
				
			})
			.on('mouseover', function(d){
											tooltip.style('visibility', 'visible' ).text(d.properties.name); 
										})
		    .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
		    .on('mouseout', function(){ tooltip.style('visibility', 'hidden');});
			
		};
		
		//d3 code for county level
		/*used parts of mbostock's demo @http://bl.ocks.org/mbostock/2206590 */
		function addCountyLayer(geometries){
			var counties = {};
			// SVG Creation	
			var countySvg = d3.select(dom_element_to_append_to).append("svg")
			.attr("width", width + margin.left + margin.right)
			.attr("height", height + margin.top + margin.bottom);
			
			
			//clearing previous layers
			//mysvg.selectAll("*").remove();
			
			countySvg.append("rect")
				 .attr("class", "background")
				 .attr("width", width)
				 .attr("height", height)
				 .on("click", clicked);
			var f = countySvg.append('g');
			
			f.append("g")
			 .attr("id", "states")
			 .selectAll("g")
			 .data(that.cache.stateTopoGeometries.features)
			 .enter()
			 .append("g").on('click', function(d){clicked(this, d);})
			 .append("path")
			 .attr("d", path);
			
			f.append("path")//just for the borders
		      .datum(topojson.mesh(that.cache.US, that.cache.US.objects.states, function(a, b) { return a !== b; }))
		      .attr("id", "state-borders")
		      .attr("d", path);
			
			
			function clicked(gElement, d) {
				console.log("f.clickedState", f.clickedState);
				console.log("boolean", f.clickedState != gElement);
				if( f.clickedState != gElement){
					var x, y, k;
					  if (d && centered !== d) {
						  
					    var centroid = path.centroid(d);
					    x = centroid[0];
					    y = centroid[1];
					    k = 2;
					    centered = d;
					    
					    //find all counties belonging to d
					    var c_in_selectedState= [];
					    for(var i in geometries){
					    	var county = geometries[i];
					    	if(d.id == county.properties.stateId){
					    		c_in_selectedState.push(county);
					    	}
					    }
					    //drawing counties in d
					    var gAr = d3.select(gElement);
					    gAr.selectAll("path")
					     .data(c_in_selectedState)
					     .enter().append("g")
					     .attr('class', 'blah')
					     .on('click', function(d){
					    	 						//console.log("counties",d);
					    	 						d3.select(this).style("fill", "yellow");
					    	 						counties[d.id] = d.properties.name;
					    	 						geoService.selectedGeographies[d.properties.stateId] = {title : d.properties.state, counties : counties};
					    	 						
					    	 						
				    	 						 })
					     .on('mouseover', function(d){
												tooltip.style('visibility', 'visible' ).text(d.properties.name + " (" + d.properties.stateAbbr + ")"); 
											})
						 .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
						 .on('mouseout', function(){ tooltip.style('visibility', 'hidden');})
					     .append("path")
					     .attr("d", path)
					     .attr("class", "countyBorders");
					  } 
					  
					  else { 
					    x = width / 2;
					    y = height / 2;
					    k = 1;
					    centered = null;
					  
					  }

//					  f.selectAll("path")
//					      .classed("active", centered && function(d) { return d === centered; });

					  f.transition()
					      .duration(750)
					      .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")scale(" + k + ")translate(" + -x + "," + -y + ")")
					      .style("stroke-width", 1.5 / k + "px");
					}
				f.clickedState = gElement;
				
				}
				  
			
			
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