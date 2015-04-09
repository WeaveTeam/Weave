/**
 * 
 */

this.d3_viz = {};

(function(){
	
	function mapTool(){
		
		this._zoom;
		this._centered;
		this._width;
		this._height;
		this._projection;
		this._path;
		this._toolTip;
		
		
		this._stateGrp;
		this._countyGrp;
		this._counties = {};
		this._statePaths;
		this._countyPaths;
		this._heirarchy;
		this._stateIdLookup = {};
		
		//is a pointer to the geometries after GEO-Jsons are loaded the first time
		this.cache = {
				stateTopoGeometries : [],
				countyTopoGeometries : [],
				selectedStates : {},
				selectedCounties : {},
				US: []
		};
		
		
		
	}
	
	var p = mapTool.prototype;
	
	p.intializeChart = function(config){
		
		this._container = config.container;
		this._margin = config.margin;
		
		this._fileName = config.fileName;
		this._stateFile = config.stateFile;
		this._countyFile = config.countyFile;
		
		this._width = (this._container.offsetWidth) - this._margin.left - this._margin.right;
		this._height = (this._container.offsetHeight) - this._margin.top - this._margin.bottom;
	    
		
		//original SVG
		this._mapSvg = d3.select(this._container).append("svg")
			.attr("width", this._width )
			.attr("height",this._height );
		
		//projection
		this._projection = d3.geo.albersUsa()
							 .translate([this._width/2, this._height/2])
							 .scale([550]);
		//path generator
		this._path = d3.geo.path()
					   .projection(this._projection);
		
		this._zoom = d3.behavior.zoom()
	    .translate(this._projection.translate())
	    .scale(this._projection.scale())
	    .scaleExtent([this._height, 8 * this._height])
	    .on("zoom", this.zoomMap.bind(this));
		
		this._toolTip = d3.select(this._container)
		.append("div")
		.style("position", "absolute")
		.style("z-index", "10")
		.style("visibility", "hidden")
		.text("")
		.style("color", "red")
		.style("font-weight", 'bold');
		
		// these updates the map
		
	};
	

	p.zoomMap = function() {
		  this._projection.translate(d3.event.translate).scale(d3.event.scale);
		  this._stateGrp.selectAll("path").attr("d", this._path);
	};
	
	/**
	 * @param heirarchy the hierarchy you want to render at eg State vs country vs county
	 * @param selectedStates states selected in a previous run
	 * @param selectedCounties counties selected in a previous run
	 */
	p.renderLayer = function(heirarchy, selectedStates, selectedCounties){
		if(!this._mapSvg){
			console.log("Chart not initialized yet");
			return;
		}
		
		
		this._heirarchy = heirarchy;
		if(selectedStates)
			this.cache.selectedStates = selectedStates;
		if(selectedCounties){
			this.cache.selectedCounties = selectedCounties;
		}
			
		
		if(this.cache.US.length == 0)
		{//first time call
			this.loadGeoJson(this._fileName,this._heirarchy);
		}
		else{
			if(this._heirarchy == 'State'){//handling state level geometries
				addStatelayer.call(this,this.cache.stateTopoGeometries.features);	
				
			}
			else if(this._heirarchy == 'County'){ //handling county level
				if('name' in this.cache.countyTopoGeometries.features[0].properties)//if this property has been assigned add it
					addCountyLayer.call(this,this.cache.countyTopoGeometries.features);
				else
					this.loadCountyLayer(this._countyFile);
				
			}
			
		}
	};
	
	p.loadGeoJson = function(filename,heirarchy) {		
		d3.json(filename, function(error, USGeometries){
			
			this.cache.US = USGeometries;
			
			var states = topojson.feature(USGeometries, USGeometries.objects.states);
			this.cache.stateTopoGeometries = states;
			
			var counties = topojson.feature(USGeometries, USGeometries.objects.counties);
			this.cache.countyTopoGeometries = counties;
			
			if(heirarchy== 'State'){//handling state level geometries
				this.loadStateLayer(this._stateFile);
				
			}
			else if(heirarchy== 'County'){ //handling county level
				this.loadCountyLayer(this._countyFile);
			}
		}.bind(this));		
	};
	

	p.loadStateLayer = function(fileName){
		d3.csv(fileName, function(state_fips){
			for(i in state_fips){
				var fips = parseFloat(state_fips[i].US_STATE_FIPS_CODE);
				for(j in this.cache.stateTopoGeometries.features){
					var id = this.cache.stateTopoGeometries.features[j].id;
					if(fips == id){
						this.cache.stateTopoGeometries.features[j].properties.name = state_fips[i].NAME10;
						break;
					}
				}//j loop
			}//i loop
			addStatelayer.call(this,this.cache.stateTopoGeometries.features);	
			
		}.bind(this));//end of csv load
	};
	
	addStatelayer = function(geometries){
		//adding map layer
		
		this._mapSvg.selectAll("*").remove();
		
		this._stateGrp = this._mapSvg.append("g")
	    .call(this._zoom);
		
		this._statePaths = this._stateGrp.selectAll(".path")
		.data(geometries)
		.enter()
		.append("path")
		.attr("d", this._path)
		.attr("class", "geometryFill");
		
		
		//handling selections							
		this._statePaths							
		.on('click', function(d){
			console.log("d", d);
			//if it is selected for the first time
			if(!(d.id in this.cache.selectedStates)){
				this.cache.selectedStates[d.id] = { title: d.properties.name };
			}
			//if already selected; remove it
			else{
				delete this.cache.selectedStates[d.id];
			}
			this.selectTheStates(this.cache.selectedStates);
			
		}.bind(this))
		.on('mouseover', function(d){
				this._toolTip.style('visibility', 'visible' ).text(d.properties.name); 
			}.bind(this))
	    .on("mousemove", function(){
	    	return this._toolTip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");
	    	}.bind(this))
	    .on('mouseout', function(){ 
	    	this._toolTip.style('visibility', 'hidden');
	    	}.bind(this));
		
		//this runs if the selected states have already been cached
		if(Object.keys(this.cache.selectedStates).length != 0)
		{
			this.selectTheStates(this.cache.selectedStates);
		}
	};
	
	p.selectTheStates = function(selectedStates){
			//TODO it needs improvement
			//apply the selected class for the selected state
		
			this._statePaths.classed('selected', function(d){	
				if(d.id in selectedStates)
					d.selected = true;
				else
					d.selected = false;
				return d.selected;
			});
			
		
	};
	
	p.selectTheCounties = function(selectedCounties){
		this._countyPaths.classed('selected', function(d){
			if(d.id in selectedCounties)
				d.selected = true;
			else
				d.selected = false;
			return d.selected;
		});
	};
	
	
	p.loadCountyLayer = function(fileNmae){
		//adding county name property from csv to topojson
		d3.csv(fileNmae, function(county_fips){
			
			for(i in county_fips){
				var county_fips_code = parseFloat(county_fips[i].FIPS);
				for(j in this.cache.countyTopoGeometries.features){
					var id = this.cache.countyTopoGeometries.features[j].id;
					if(county_fips_code == id){
						this.cache.countyTopoGeometries.features[j].properties.name = county_fips[i].County_Name;
						this.cache.countyTopoGeometries.features[j].properties.state = county_fips[i].State_Name;
						this.cache.countyTopoGeometries.features[j].properties.stateAbbr = county_fips[i].State_Abbr;
						this.cache.countyTopoGeometries.features[j].properties.stateId = parseFloat(county_fips[i].STFIPS);
						break;
					}
				}//j loop
			}//i loop
			
			addCountyLayer.call(this);
			
		}.bind(this));//end of csv load
	};
	
	
	p.addCountyLayerForState = function(d){
		if(d)
			var gElement = this._stateIdLookup[d.id];
		if( this._stateGrp.clickedState != gElement){
			var chart = this;
			var x, y, k;
			
			if (d  && this._centered !== d) {
			    var centroid = this._path.centroid(d);
			    x = centroid[0];
			    y = centroid[1];
			    k = 2;
			    this._centered = d;
			    
			   
			    //drawing counties in d
			    var gAr = d3.select(gElement);
			    this._countyPaths= gAr.selectAll("path")
			     .data(this.cache.countyTopoGeometries.features)
			     .enter().append("g")
			     .filter(function(cd,i){
			    	 return d.id == cd.properties.stateId;
			    	
			     })
			     .attr("class", "geometryFill");
			    
			    
			    this._countyPaths
			     .on('click', function(d){
						var countyObj;
						// first check county object there for stateID , then check countyID there for that state
						if(!this.cache.selectedCounties[d.properties.stateId] || !(d.id in this.cache.selectedCounties[d.properties.stateId].counties)){
							countyObj = this.cache.selectedCounties[d.properties.stateId];
							if(!countyObj) 
								countyObj = {title: d.properties.state, state: d.properties.stateId ,counties:{} };
							countyObj.counties[d.id] = { title: d.properties.name };
							
							this.cache.selectedCounties[d.properties.stateId] = countyObj;
							this._counties[d.id] = d.properties.name;
						}
						//if already selected; remove it
						else{
							countyObj = this.cache.selectedCounties[d.properties.stateId];
							if(countyObj){
								delete this.cache.selectedCounties[d.properties.stateId].counties[d.id];
								delete chart._counties[d.id];
							}
						}
						if(this.cache.selectedCounties[d.properties.stateId])
							this.selectTheCounties(this.cache.selectedCounties[d.properties.stateId].counties);
						
						
						
			     }.bind(this))
			     .on('mouseover', function(d){
					 this._toolTip.style('visibility', 'visible' ).text(d.properties.name + " (" + d.properties.stateAbbr + ")"); 
			     	}.bind(this))
				 .on("mousemove", function(){
					 return this._toolTip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");
				 	}.bind(this))
				 .on('mouseout', function(){
					 this._toolTip.style('visibility', 'hidden');
					 }.bind(this))
			     .append("path")
			     .attr("d", this._path)
			     .attr("class", "countyBorders");
			} 
			  
			else { 
				x = this._width / 2;
				y = this._height / 2;
				k = 1;
				this._centered = null;
		  
			}

//			  f.selectAll("path")
//			      .classed("active", centered && function(d) { return d === centered; });

			this._stateGrp.transition()
			      .duration(750)
			      .attr("transform", "translate(" + this._width / 2 + "," + this._height / 2 + ")scale(" + k + ")translate(" + -x + "," + -y + ")")
			      .style("stroke-width", 1.5 / k + "px");
			
			if(d)
				{
					if(this.cache.selectedCounties[d.id])
						this.selectTheCounties(this.cache.selectedCounties[d.id].counties);
				}
		}
		this._stateGrp.clickedState = gElement;
	};
	
	
	addCountyLayer = function(geometries){
		if(this.cache.selectedCounties){
			for(stateID in this.cache.selectedCounties)
				for(countyID in this.cache.selectedCounties[stateID].counties)
					this._counties[countyID] = this.cache.selectedCounties[stateID].counties[countyID];
		}
		else
			this._counties = {};
		var chart = this;
		
		this._mapSvg.selectAll("*").remove();
		
		this._mapSvg.append("rect")
		 .attr("class", "background")
		 .attr("width", this._width)
		 .attr("height", this._height)
		 .on("click", this.addCountyLayerForState.bind(this));
		
		this._stateGrp = this._mapSvg.append('g');
		
		
		this._statePaths = this._stateGrp
		 .append("g")
		 .attr("id", "states")
		 .selectAll("g")
		 .data(this.cache.stateTopoGeometries.features)
		 .enter();
		
		this._statePaths.append("g")
		.each(function(d){ 
			chart._stateIdLookup[d.id] = this;
		})
		.on('click', this.addCountyLayerForState.bind(this))
		 .append("path")
		 .attr("d", this._path); 
		
		this._stateGrp.append("path")//just for the borders
	      .datum(topojson.mesh(this.cache.US, this.cache.US.objects.states, function(a, b) { return a !== b; }))
	      .attr("id", "state-borders")
	      .attr("d", this._path);
		
		
		//this runs if the selected states have already been cached
		if(Object.keys(this.cache.selectedCounties).length != 0)
		{
			for(state in this.cache.selectedCounties){
				for(var i = 0; i < this.cache.stateTopoGeometries.features.length; i++)
					{
						if(state == this.cache.stateTopoGeometries.features[i].id)
							{
								this.addCountyLayerForState(this.cache.stateTopoGeometries.features[i]);
								break;
							}
					}
				
			}
			
		}
	};
	
	
	d3_viz.mapTool = mapTool;
}());

