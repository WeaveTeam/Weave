/**
 *this controller watches for read/write status of the database while inserting or deleting rows(queryObjects/projects) 
 */
angular.module('aws.project')
.controller("databaseLogController", function($scope, queryService){
	
	$scope.$on('DB_UPDATE', function(event, args){
		$scope.databaseLog = args.status;

	});
});