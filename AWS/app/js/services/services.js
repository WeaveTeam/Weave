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
	this.weaveOptions = {};
	this.weaveOptions.weaveObject = "Not Defined here";
	this.conn = {};
	this.conn.dataTable = 169602;
	var defaults = {
			scriptLocation : 'C:\\RScripts\\',
			dataTable: 161213,
			/*connectionName : 'demo',
			connectionPass : 'pass',*/
			serverType : 'MySQL',
			sqlip : 'localhost',
			sqlport : '3306',
			sqldbname : 'sdoh2010',
			sqluser : 'root',
			sqlpass : 'pass'
		};
	
})
.service("scriptobj", function(){
	this.scriptMetadata = {
			inputs: ["State(binning Var)", "PSU", "FinalWt", "StStr", "Diabetes indicator"],
			outputs: ["Fips (binningVar)", "Response", "Prevalence Percentage", "CI Low", "CI Hi"]
	};
})

angular.module("aws.services").service("dataService", ['$q', '$rootScope', function($q, scope){
	function safeApply( fn ) {
        if ( !scope.$$phase ) {
            scope.$apply( fn );
        }
        else {
            fn();
        }
    }
	
	var fetchColumns = function(id){
		if(!id){
			alert("No DataTable Id Specified. Please update in the Data Dialog");
		}
		var deferred = $q.defer();
		var prom = deferred.promise;
		var deferred2 = $q.defer();
		
		var callbk = function(result){
			safeApply(function(){
				//console.log(result);
				deferred.resolve(result);
			});
		};
		var callbk2 = function(result){
			safeApply(function(){
				
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
			safeApply(function(){
				console.log(result);
				deferred.resolve(result);
			});
		};
		var callbk2 = function(result){
			safeApply(function(){
				
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
	
	
	//var fullColumnObjs = fetchColumns(scope, datatable);
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
		giveMeColObjs: function(scopeobj, id){
			return fetchColumns(id).then(function(response){
					var type = scopeobj.panelType;
					return filter(response, type);
				});
		},
		refreshObjects: function(id){
			fullColumnObjs = fetchColumns(id);
		},
		giveMeGeomObjs: function(){
			return fullGeomObjs.then(function(response){
				return response;
			});
		}
	};
}]);