/**
 * Project Module ProjectButtonCtrl - Controls actions of the project button.
 * ProjectContentCtrl - Controls dialog content for project actions.
 */
angular.module('aws.project', [ 'aws' ]).controller('ProjectButtonCtrl',
		function($scope, $dialog) {
	$scope.opts = {
			backdrop : true,
			keyboard : true,
			backdropClick : true,
			templateUrl : 'tpls/ProjectMenu.tpls.html',
			controller : 'ProjectButtonContentCtrl'
	};

	$scope.openDialog = function(partial) {
		console.log("hello");
		if (partial) {
			$scope.opts.templateUrl = 'tpls/' + partial + '.tpls.html';
		}

		var d = $dialog.dialog($scope.opts);
		d.open();
	};
	
	$scope.save = function(){
		saveJSON($scope.query);
	};
	
})
.controller('ProjectButtonContentCtrl', function($scope, queryobj, $dialog) {
	$scope.close = function() {
		$dialog.close();
	};

	$scope.query = queryobj;
	
});
	
function saveJSON(queryobj) {
	//var query = $rootScope;
	var blob = new Blob([JSON.stringify(queryobj)], {type: "text/plain;charset=utf-8"});
	saveAs(blob, "queryObject.json");
}