var weave_mod = angular.module('aws.WeaveModule', []);
//TODO figure out whici module this service belongs to
AnalysisModule.service("WeaveService", ['$q','$rootScope','runQueryService', 'dataServiceURL', function($q, rootScope, runQueryService, dataServiceURL) {
	
	this.weave;
	var ws = this;
	this.weaveWindow = window;
	this.analysisWindow = window;
	this.toolsEnabled = [];
	
	this.columnNames = [];
	
	this.generateUniqueName = function(className) {
		if(!ws.weave)
			return null;
		return ws.weave.path().getValue('generateUniqueName')(className);
	};
	
	this.tileWindows = function() {
		if(!ws.weave)
			return;
		ws.weave.path()
		 .libs("weave.ui.DraggablePanel")
		 .exec("DraggablePanel.tileWindows()");
	};
	
	this.setWeaveWindow = function(window) {
		var weave;
		if(!window) {
			ws.weave = null;
			return;
		}
		try {
			ws.weaveWindow = window;
			weave = window.document.getElementById('weave');

			if (weave && weave.WeavePath && weave.WeavePath.prototype.pushLayerSettings) {
				ws.weave = weave;
				console.log("weave and its api are ready");
				rootScope.$safeApply();
			}
			else {
				setTimeout(ws.setWeaveWindow, 50, window);
			}
		} catch (e)
		{
			console.error("fails", e);
		}
    };
    
	this.setWeaveWindow(window);
	
	this.addCSVData = function(csvData, aDataSourceName, queryObject) {
		var dataSourceName = "";
		if(!aDataSourceName)
			dataSourceName = ws.generateUniqueName("CSVDataSource");
		else
			dataSourceName = ws.generateUniqueName(aDataSourceName);
	
		ws.weave.path(dataSourceName)
			.request('CSVDataSource')
			.vars({rows: csvData})
			.exec('setCSVData(rows)');
		for(var i in csvData[0])
		{
			queryObject.resultSet.unshift({ id : csvData[0][i], title: csvData[0][i], dataSourceName : dataSourceName});
		}
	};
	
	// weave path func
	var setQueryColumns = function(mapping) {
		this.forEach(mapping, function(column, propertyName) {
			if (Array.isArray(column))
			{
				this.push(propertyName).call(setQueryColumns, column);
			}
			else if (ws.weave && ws.weave.path && column)
			{
				if(column.id == "" || angular.isUndefined(column.id))
					return;
				this.push(propertyName).setColumn(column.id, column.dataSourceName);
			}
		});
		if (Array.isArray(mapping))
			while (this.getType(mapping.length))
				this.remove(mapping.length);
		return this;
	};
	
	//returns a list of visualization tools currently open in Weave
	this.listOfTools = function(){
		var openTools = [];
		if(ws.weave && ws.weave.path ){
			var tools =  ws.weave.path().libs('weave.api.ui.IVisTool').getValue('getObjects(IVisTool)');
		}
		
		for(var i in tools){
			var type = tools[i].getType();
			openTools.push(type.replace(/weave.visualization.tools::/g, ""));
		}
		
		return openTools;
	};
	
	//returns a list of selectable attributes for every plotter in a given visualization tool
	this.getSelectableAttributes = function(vizTool){
		
		var selAttributes =[];
		
		if(ws.weave && ws.weave.path ){
			//var plotLayers = ws.weave.path(vizTool, 'children', 'visualization', 'plotManager', 'plotters').getNames();
			//var plotLayers = ws.weave.path( ws.weave.path(vizTool, 'children', 'visualization', 'plotManager', 'plotters', 'plot'));
			var attrs = ws.weave.path(vizTool, 'children', 'visualization', 'plotManager', 'plotters', 'plot').getValue('getSelectableAttributeNames()');
			for(var j in attrs){
				selAttributes.push({plotLayer : 'plot', title : attrs[j]});
			}
			
//			for(var i in plotLayers)
//			{
//				var attrs = ws.weave.path(vizTool, 'children', 'visualization', 'plotManager', 'plotters', plotLayers[i]).getValue('getSelectableAttributeNames()');
//				for(var j in attrs){
//					selAttributes.push({plotLayer : plotLayers[i], title : attrs[j]});
//				}
//			}
		}
		
		
		return selAttributes;
	};
	
	/**
	 * this function sets the selected attribute(selected in the attribute widget tool) in the required tool
	 * @param tool the tool whose attribute is to be set
	 * @param vizAttribute the attribute of tool to be set
	 * @param attrObject the object used for setting vizAttribute
	 */
	
	this.setVizAttribute = function(tool, vizAttribute, attrObject){
		console.log("vizAttribute", vizAttribute);
		console.log("tool", tool);
		console.log("attrObject", attrObject);
		switch(tool){
		
			case 'MapTool' :
				switch(vizAttribute.title){
					case 'Color' :
						//call color column setter
						if(ws.weave && ws.weave.path)
							{
								ws.weave.path('defaultColorDataColumn').setColumn(attrObject.id, attrObject.dataSourceName);
							}
						break;
					case 'Geometry' :
						//set geometry column
						if(ws.weave && ws.weave.path)
						{
							ws.wave.path(tool, 'children', 'visualization', 'plotManager', 'plotters')
							.push(vizAttribute.plotLayer).request('weave.visualization.plotters.GeometryPlotter')
							.call(setQueryColumns, {geometryColumn: attrObject});
						}
						break;
			}
				break;
				
			case 'ScatterPlotTool' :
				switch(vizAttribute.title){
					case 'Color':
						if(ws.weave && ws.weave.path)
						{
							ws.weave.path('defaultColorDataColumn').setColumn(attrObject.id, attrObject.dataSourceName);
						}
						break;
					case 'X':
						if(ws.weave && ws.weave.path)
						{
							ws.weave.path(toolName).request('ScatterPlotTool')
							.state({ panelX : "50%", panelY : "50%", panelTitle : state.title, enableTitle : true})
							.push('children', 'visualization','plotManager', 'plotters', 'plot')
							.call(setQueryColumns, {dataX : attrObject});
						}
						break;
					case 'Y':
						if(ws.weave && ws.weave.path)
						{
							ws.weave.path(toolName).request('ScatterPlotTool')
							.state({ panelX : "50%", panelY : "50%", panelTitle : state.title, enableTitle : true})
							.push('children', 'visualization','plotManager', 'plotters', 'plot')
							.call(setQueryColumns, {dataY : attrObject});
						}
						break;
					case 'Size':
						if(ws.weave && ws.weave.path){
							
							ws.weave.path(toolName).request('ScatterPlotTool')
							.state({ panelX : "50%", panelY : "50%", panelTitle : state.title, enableTitle : true})
							.push('children', 'visualization','plotManager', 'plotters', 'plot')
							.call(setQueryColumns, {sizeBy : attrObject});
						}
						break;
			}
				break;
				
			case 'CompoundBarChartTool':
				switch(vizAttribute.title){
				case 'Color':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path('defaultColorDataColumn').setColumn(attrObject.id, attrObject.dataSourceName);
					}
					break;
				case 'Height':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path(toolName)
						.request('CompoundBarChartTool')
						.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
						.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.call(setQueryColumns, {heightColumns : attrObject});
					}
					break;
				case 'Label':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path(toolName)
						.request('CompoundBarChartTool')
						.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
						.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.call(setQueryColumns, {labelColumn : attrObject});
					}
					break;
				case 'Sort':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path(toolName)
						.request('CompoundBarChartTool')
						.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
						.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.call(setQueryColumns, {sortColumn : attrObject});
					}
					break;
				case 'Positive Error':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path(toolName)
						.request('CompoundBarChartTool')
						.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
						.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.call(setQueryColumns, {positiveErrorColumns : attrObject});
					}
					break;
				case 'Negative Error':
					if(ws.weave && ws.weave.path)
					{
						ws.weave.path(toolName)
						.request('CompoundBarChartTool')
						.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
						.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
						.call(setQueryColumns, {positiveErrorColumns : attrObject});
					}
			}
				break;
				
			case 'TableTool':
				break;
		
		}//end of switch for tool
	};
	
	this.AttributeMenuTool = function(state, aToolName){
		
		var toolName = aToolName || ws.generateUniqueName("AttributeMenuTool");
		
		if(state == null)
			return toolName;
		
		if(ws.weave && ws.weave.path && state) {
			if(!state.enabled) {
				ws.weave.path(toolName).remove();
				return "";
			}
			ws.weave.path(toolName).request('AttributeMenuTool')
			.state({ panelX : "50%", panelY : "0%", panelHeight: "15%", panelWidth :"50%",  panelTitle : state.title, enableTitle : true})
			.call(setQueryColumns, {choices: state.columns});
		}
	};
	
	this.BarChartTool =  function (state, aToolName) {
		var toolName = aToolName || ws.generateUniqueName("BarChartTool");
		
		if(state == null)
			return toolName;
		
		if(ws.weave && ws.weave.path && state) {
			
			try{
				if(state.enabled)
				{
					ws.weave.path(toolName)
					.request('CompoundBarChartTool')
					.state({ panelX : "0%", panelY : "50%", panelTitle : state.title, enableTitle : true, showAllLabels : state.showAllLabels })
					.push('children', 'visualization', 'plotManager', 'plotters', 'plot')
					.call(setQueryColumns, {
						sortColumn : state.sort,
						labelColumn : state.label,
						heightColumns : state.heights,
						positiveErrorColumns : state.posErr,
						negativeErrorColumns : state.negErr
					});
				} else {
					ws.weave.path(toolName).remove();
				}
			} catch(e)
			{
				console.log(e);
			}
		}
		
		return toolName;
	};
	
	this.MapTool = function(state, aToolName){
		
		var toolName = aToolName || ws.generateUniqueName("MapTool");
	
		if(ws.weave && ws.weave.path && state) {
			
			try{
				if(!state.enabled)
				{
					ws.weave.path(toolName).remove();
					return "";
				}
				else{
					
				}
				ws.weave.path(toolName).request('MapTool').state({ panelX : "0%", panelY : "0%", panelTitle : state.title, enableTitle : true });
				;
				//STATE LAYER
				if(state.stateGeometryLayer)
				{
					var stateGeometry = state.stateGeometryLayer;

					ws.weave.path(toolName).request('MapTool')
					.push('children', 'visualization', 'plotManager', 'plotters')
					.push('Albers_State_Layer').request('weave.visualization.plotters.GeometryPlotter')
					.push('line', 'color', 'defaultValue').state('0').pop()
					.call(setQueryColumns, {geometryColumn: stateGeometry});
					
					if(state.useKeyTypeForCSV)
					{
						if(state.labelLayer)
						{
							ws.weave.setSessionState([state.labelLayer.dataSourceName], {"keyType" : stateGeometry.keyType});
						}
					}
					
				}
				else{//to remove state layer
					
					if($.inArray('Albers_State_Layer',ws.weave.path().getNames()))//check if the layer exists and then remove it
						ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'Albers_State_Layer').remove();
				}
				
				//COUNTY LAYER
				if(state.countyGeometryLayer)
				{
					var countyGeometry = state.countyGeometryLayer;
					
					ws.weave.path(toolName).request('MapTool')
					.push('children', 'visualization', 'plotManager', 'plotters')
					.push('Albers_County_Layer').request('weave.visualization.plotters.GeometryPlotter')
					.push('line', 'color', 'defaultValue').state('0').pop()
					.call(setQueryColumns, {geometryColumn : countyGeometry});
				
					//TODO change following
					//done for handling albers projection What about other projection?
					ws.weave.path(toolName, 'projectionSRS').state(stateGeometry.projection);
					ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'layerSettings', 'Albers_County_Layer', 'alpha').state(0);
				}
				else{//to remove county layer
					
					if($.inArray('Albers_County_Layer',ws.weave.path().getNames()))//check if the layer exists and then remove it
						ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'plotters', 'Albers_County_Layer').remove();
				}
				
				//LABEL LAYER
				if(state.labelLayer && state.stateGeometryLayer)
				{
					var labelLayer = state.labelLayer;
					ws.weave.setSessionState([labelLayer.dataSourceName], {keyColName : "fips"});//TODO handle this
					
					var stateGeometryLayer = state.stateGeometryLayer;
					
					ws.weave.path(toolName).request('MapTool')
					.push('children', 'visualization', 'plotManager','plotters')
					.push('stateLabellayer').request('weave.visualization.plotters.GeometryLabelPlotter')
					.call(setQueryColumns, {geometryColumn : stateGeometryLayer})
					.call(setQueryColumns, {text : labelLayer});
				}
				
				//handling zoom layer
				// 1. check if above a certain zoom level(or zoom bounds) only for demo purposes
				// 2. as state.zoomLevel increases, county layer alpha is either 1 or 0
				
				if(state.zoomLevel)
					{
						ws.weave.path('MapTool','children', 'visualization', 'plotManager').vars({myZoom: state.zoomLevel}).exec('setZoomLevel(myZoom)');//set zoom according to UI widget
						
						if(state.zoomLevel > 3 && state.countyGeometryLayer)
						{
							ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'layerSettings', 'Albers_County_Layer', 'alpha').state(1);
				
						}
						else{
							ws.weave.path(toolName, 'children', 'visualization', 'plotManager', 'layerSettings', 'Albers_County_Layer', 'alpha').state(0);
						}
					}
				
			} catch(e) {
				console.log(e);
			}
		}
		return toolName;
	};
	
	
	this.ScatterPlotTool = function(state, aToolName){
		var toolName = aToolName || ws.generateUniqueName("ScatterPlotTool");
		
		if(ws.weave && ws.weave.path && state)
		{
			if(!state.enabled)
			{
				ws.weave.path(toolName).remove();
				return "";
			}
			
			ws.weave.path(toolName).request('ScatterPlotTool')
			.state({ panelX : "50%", panelY : "50%", panelTitle : state.title, enableTitle : true})
			.push('children', 'visualization','plotManager', 'plotters', 'plot')
			.call(setQueryColumns, {dataX : state.X, dataY : state.Y});
		}
		
		return toolName;
	};
	
	this.DataTableTool = function(state, aToolName){

		if(!state)
			return;
		var toolName = aToolName || ws.generateUniqueName("DataTableTool");;
		
		if(ws.weave && ws.weave.path && state) {
			if(!state.enabled) {
				ws.weave.path(toolName).remove();
				return "";
			}
			ws.weave.path(toolName).request('AdvancedTableTool')
			.state({ panelX : "50%", panelY : "0%", panelTitle : state.title, enableTitle : true})
			.call(setQueryColumns, {columns: state.columns});
		};
		
		return toolName;
	};
	
	this.ColorColumn = function(state){
		if(ws.weave && ws.weave.path && state) {
			
			if(state.column)
			{
				ws.weave.path('defaultColorDataColumn').setColumn(state.column.id, state.column.dataSourceName);
			}

				//hack for demo
				if(state.column2 && state.column3){
					console.log("getting columns together", state.column2, state.column3);
					//gets their ids
					//call modified combinedColumnfunction
					ws.weave.path('defaultColorDataColumn', 'internalDynamicColumn', null)
					  .request('CombinedColumn')
					  .push('columns')
					  .setColumns([ state.column3.id, state.column2.id]);
				}
				//hack for demo end
			
			if(state.showColorLegend)
			{
				ws.weave.path("ColorBinLegendTool").request('ColorBinLegendTool')
				.state({panelX : "80%", panelY : "0%"});
			}
			if(!state.showColorLegend)
				ws.weave.path("ColorBinLegendTool").remove();
		}
		//;
	};
	
	this.keyColumn = function(keyColumn) {
		if(ws.weave && ws.weave.path && keyColumn) {
			if(keyColumn.name) {
				ws.weave.setSessionState([keyColumn.dataSourceName], {keyColName : keyColumn.id});
			}
			else{
				ws.weave.setSessionState([keyColumn.dataSourceName], {keyColName : "fips"});
			}
		}
	};
	
	this.getSessionState = function()
	{
		return ws.weave.path().getValue("\
		        var e = new 'mx.utils.Base64Encoder'();\
		        e.encodeBytes( Class('weave.Weave').createWeaveFileContent(true) );\
		        return e.drain();\
		    ");
	};
	
	this.setSessionHistory = function(base64encodedstring)
	{
		ws.weave.path()
		.vars({encoded: base64encodedstring})
		.getValue("\
	        var d = new 'mx.utils.Base64Decoder'();\
			var decodedStuff = d.decode(encoded);\
			var decodeBytes =  d.toByteArray();\
	      Class('weave.Weave').loadWeaveFileContent(decodeBytes);\
	    ");
	};
	
	this.clearSessionState = function(){
		ws.weave.path().state(['WeaveDataSource']);
	};
	
	//this function creates the CSV data format needed to create the CSVDataSource in Weave
	/*[
	["k","x","y","z"]
	["k1",1,2,3]
	["k2",3,4,6]
	["k3",2,4,56]
	] */
	/**
	 * @param resultData the actual data values
	 * @param columnNames the names of the result columns returned
	 */
	this.createCSVDataFormat = function(resultData, columnNames){
		var columns = resultData;


		var final2DArray = [];

	//getting the rowCounter variable 
		var rowCounter = 0;
		/*picking up first one to determine its length, 
		all objects are different kinds of arrays that have the same length
		hence it is necessary to check the type of the array*/
		var currentRow = columns[0];
		if(currentRow.length > 0)
			rowCounter = currentRow.length;
		//handling single row entry, that is the column has only one record
		else{
			rowCounter = 1;
		}

		var columnHeadingsCount = 1;

		rowCounter = rowCounter + columnHeadingsCount;//we add an additional row for column Headings

		final2DArray.unshift(columnNames);//first entry is column names

			for( var j = 1; j < rowCounter; j++)
			{
				var tempList = [];//one added for every column in 'columns'
				for(var f =0; f < columns.length; f++){
					//pick up one column
					var currentCol = columns[f];
					if(currentCol.length > 0)//if it is an array
					//the second index in the new list should coincide with the first index of the columns from which values are being picked
						tempList[f]= currentCol[j-1];
					
					//handling single record
					else 
					{
						tempList[f] = currentCol;
					}

				}
				final2DArray[j] = tempList;//after the first entry (column Names)
			}

			return final2DArray;
	};
}]);

//aws.WeaveClient.prototype.reportToolInteractionTime = function(message){
//	
//	var time = aws.reportTime();
//	
//	ws.weave.evaluateExpression([], "WeaveAPI.ProgressIndictor.getNormalizedProgress()", {},['weave.api.WeaveAPI']); 
//	
//	console.log(time);
//	try{
//		$("#LogBox").append(time + message + "\n");
//	}catch(e){
//		//ignore
//	}	
//};
