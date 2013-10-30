/**
 * RunQueryCtrl. This controller manages the run of queries.
 */
angular.module("aws.RunQuery", []).controller("RunQueryCtrl", function($scope, queryService) {
			
		var queryHandler = undefined;
		
		$scope.runQuery = function(){
			queryHandler = new aws.QueryHandler(queryService.queryObject);
			queryHandler.runQuery();
		};
		
		$scope.clearWeave = function(){
			if (queryHandler) {
				queryHandler.clearWeave();
				queryHandler = undefined;
			}
		};
});