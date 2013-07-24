'use strict';

/* Services */

// Demonstrate how to register services
// In this case it is a simple value service.
angular.module('aws.services', [ 'ngResource' ]).factory('Phone',
		function($resource) {
			return $resource('phones/:phoneId.json', {}, {
				query : {
					method : 'GET',
					params : {
						phoneId : 'phones'
					},
					isArray : true
				}
			});
		});

/**
 * Query Object Service provides access to the main "singleton" query object.
 * 
 * Don't worry, it will be possible to manage more than one query object in the
 * future.
 */
angular.module("aws").service("queryobj", function() {
	this.queryObject = {
		connectionDB : "exampleProperty"
	};

})

angular.module("aws").service("Data", function($q, $timeout){

	return {
		getColNamesFromDb: function(panel, scope){
			// aws.DataClient.getIndicators()??
			var deferred = $q.defer();
			var prom = deferred.promise;
			var deferred2 = $q.defer();
//			var intermediate;
//	//		var childIds = deferred.promise;
//			var out = function(result){
//				console.log("out handler");
//				console.log(result);
//				//deferred.promise.result = result;
//				if(result){
//					deferred.resolve(result);
//					//deferred.reject();
//				}else{
//					
//				}
//				//$rootScope.$apply();
//			};
			
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
//			var safeApply = function(scope, fn) {
//			    (scope.$$phase || scope.$root.$$phase) ? fn() : scope.$apply(fn);
//			};
			
				aws.DataClient.getEntityChildIds(161213, callbk);

				deferred.promise.then(function(res){
					aws.DataClient.getDataColumnEntities([res], callbk2);
				});
				prom = deferred2.promise.then(function(response){
					console.log(response);
					//$scope.options = response;
					return response;
				},function(response){
					console.log("error " + response);
				});
			
			//deferred2.resolve(aws.DataClient.getDataColumnEntities(childIds));
	//		var temp = deferred.promise.then(function(result){
	//			return result;
	//		});
//			deferred.promise.then(function(response){
//				deferred.resolve(intermediate);
//			});
			//deferred.promise.result = intermediate;
			return prom;
		},
		secondMethod: function(bogus){
			console.log("bogus");
			return "blah";
		}
	};
});