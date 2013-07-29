'use strict';

/* Services */


/**
 * Query Object Service provides access to the main "singleton" query object.
 * 
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws.services", []).service("queryobj", function() {
	this.queryObject = {
		connectionDB : "exampleProperty"
	};

})

angular.module("aws.services").service("dataService", ['$q', '$rootScope', function($q, scope){
	var fetchColumns = function(scope){

		var deferred = $q.defer();
		var prom = deferred.promise;
		var deferred2 = $q.defer();

		
		function safeApply( fn ) {
            if ( !scope.$$phase ) {
                scope.$apply( fn );
            }
            else {
                fn();
            }
        }
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
		
		aws.DataClient.getEntityChildIds(161213, callbk);

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
	
	var fullColumnObjs = fetchColumns(scope);
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
		return filtered;
	};
	
	return {
		giveMeColObjs: function(scopeobj){
			return fullColumnObjs.then(function(response){
					var type = scopeobj.panelType;
					return filter(response, type);
				});
		},
		refreshObjects: function(){
			fullColumnObjs = fetchColumns(scope);
		}
	};
}]);