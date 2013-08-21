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
	this.dataTable = 169602;
	this.conn = {
			scriptLocation : 'C:\\RScripts\\',
			serverType : 'MySQL',
			sqlip : 'localhost',
			sqlport : '3306',
			sqldbname : 'test2010_new',
			sqluser : 'root',
			sqlpass : 'pass',
			schema : 'data'
	};
})

angular.module("aws.services").service("scriptobj", ['queryobj', '$rootScope', '$q', function(queryobj, scope, $q){
	this.scriptMetadata = {
			inputs: ["State(binning Var)", "PSU", "FinalWt", "StStr", "Diabetes indicator"],
			outputs: ["fips", "response", "prev.percent", "CI_LOW", "CI_HI"]
	};
	this.availableScripts = [];
	
	
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
