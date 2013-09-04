'use strict';

/* Services */


/**
 * Query Object Service provides access to the main "singleton" query object.
 * 
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws.services", []).service("queryobj", function() {
	this.title = "AlphaQueryObject";
	this.date = new Date();
	this.author = "UML IVPR AWS Team";
	this.scriptType = "r";
	this.dataTable = 1;
	this.conn = {
			scriptLocation : 'C:\\RScripts\\',
			serverType : 'MySQL',
			sqlip : 'localhost',
			sqlport : '3306',
			sqldbname : 'sdoh2010q',
			sqluser : 'root',
			sqlpass : 'pass',
			schema : 'data',
			dsn : 'brfss'
	};
	this.setQueryObject = function(jsonObj){
		if (!jsonObj){
			return undefined;
		}
		this.title = jsonObj.title;
		this.date = jsonObj.data;
		this.author = jsonObj.author;
		this.scriptType = jsonObj.scriptType;
		this.dataTable = jsonObj.dataTable;
		this.conn = jsonObj.conn;
		this.selectedVisualization = jsonObj.selectedVisualization;
		this.barchart = jsonObj.barchart;
		this.datatable = jsonObj.datatable;
		this.colorColumn = jsonObj.colorColumn;
		this.byvars = jsonObj.byvars;
		this.indicators = jsonObj.indicators;
		this.geography = jsonObj.geography;
		this.timeperiods = jsonObj.timeperiods;
		this.analytics = jsonObj.analytics;
		this.scriptOptions = jsonObj.scriptOptions;
		this.scriptSelected = jsonObj.scriptSelected;
		this.maptool = jsonObj.maptool;
	};
		
})

angular.module("aws.services").service("scriptobj", ['queryobj', '$rootScope', '$q', function(queryobj, scope, $q){
	this.scriptMetadata = [];
	this.availableScripts = [];
	
	var that = this;
	this.getScriptMetadata = function(){
		var deferred = $q.defer();
		var promise = deferred.promise;
		
		var callback = function(result){
			scope.$safeApply(function(){
				console.log(result);
				deferred.resolve(result);
			});
		};
		
		aws.RClient.getScriptMetadata(queryobj.conn.scripLocation, queryobj.scriptSelected, callback);
		prom.then(function(result){
			return result;
		});
		
		return prom;
	};
	
	this.getScriptsFromServer = function(){
		var deferred = $q.defer();
		var prom = deferred.promise;
		
		var callbk = function(result){
			scope.$safeApply(function(){
				console.log(result);
				deferred.resolve(result);
			});
		};

		aws.RClient.getListOfScripts(queryobj.conn.scriptLocation, callbk );
		prom.then(function(result){
			//this.availableScripts = result;
			return result;
		});
		return prom;
	};
	 this.availableScripts = this.getScriptsFromServer();
	 this.scriptMetadata = this.getScriptMetadata();
	 
}]);

angular.module("aws.services").service("dataService", ['$q', '$rootScope', 'queryobj', 
   function($q, scope, queryobj){

	
	var fetchColumns = function(id){
		if(!id){
			alert("No DataTable Id Specified. Please update in the Data Dialog");
		}
		var deferred = $q.defer();
		var prom = deferred.promise;
		var deferred2 = $q.defer();
		
		var callbk = function(result){
			scope.$safeApply(function(){
				//console.log(result);
				deferred.resolve(result);
			});
		};
		var callbk2 = function(result){
			scope.$safeApply(function(){
				
				console.log(result);
				deferred2.resolve(result);
			});
		};
		
		aws.DataClient.getEntityChildIds(id, callbk);

		deferred.promise.then(function(res){
			aws.DataClient.getDataColumnEntities(res, callbk2);
		});
		
		prom = deferred2.promise.then(function(response){
			//console.log(response);
			return response;
		},function(response){
			console.log("error " + response);
		});
		
		return prom;
	};
	
	var fetchGeoms = function(){
		var deferred = $q.defer();
		var prom = deferred.promise;
		var deferred2 = $q.defer();
		var callbk = function(result){
			scope.$safeApply(function(){
				console.log(result);
				deferred.resolve(result);
			});
		};
		var callbk2 = function(result){
			scope.$safeApply(function(){
				
				console.log(result);
				deferred2.resolve(result);
			});
		};
		aws.DataClient.getEntityIdsByMetadata({"dataType":"geometry"}, callbk);
		deferred.promise.then(function(res){
			aws.DataClient.getDataColumnEntities(res, callbk2);
		});
		
		prom = deferred2.promise.then(function(response){
			//console.log(response);
			return response;
		},function(response){
			console.log("error " + response);
		});
		
		return prom;
	};
	
	
	var fullColumnObjs = fetchColumns(queryobj.dataTable);
	var fullGeomObjs = fetchGeoms();
	var filter = function(data, type){
		var toFilter = data;
		var filtered = [];
		for(var i = 0; i < data.length; i++){
			try{
				if(toFilter[i].publicMetadata.ui_type == type){
					filtered.push(toFilter[i]);
				}
			}catch(e){
				console.log(e);
			}
		}
		filtered.sort();
		return filtered;
	};
	
	return {
		giveMeColObjs: function(scopeobj){
			return fullColumnObjs.then(function(response){
					var type = scopeobj.panelType;
					return filter(response, type);
			});
		},
		refreshColumns: function(scopeobj){
			fullColumnObjs = fetchColumns(queryobj.dataTable);
		},
		giveMeGeomObjs: function(){
			return fullGeomObjs.then(function(response){
				return response;
			});
		}
	};
}]);
