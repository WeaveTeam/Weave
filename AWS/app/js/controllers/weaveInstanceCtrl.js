/** WeaveInstance Module
 * weaveInstanceCtrl - Controls the instance of Weave.
 * weaveContentCtrl - Manages the content of weaveInstance wizard. 
 */
angular.module('aws.weave', ['aws'])
.controller('weaveInstanceCtrl',function($scope, $dialog){
  $scope.opts = {
    backdrop: true,
    keyboard: true,
    backdropClick: true,
    templateUrl: 'tpls/weave.tpls.html',
    controller: 'weaveContentCtrl'
  };

$scope.openDialog = function(partial){
	console.log("hello");
	if(partial){
		$scope.opts.templateUrl = 'tpls/' + partial + '.tpls.html';
	}
	var d = $dialog.dialog($scope.opts);
	d.open();
  };
})

.controller('weaveContentCtrl', function($scope, $http, dialog){

	$scope.cl = function(){
	    dialog.close();
	 };

});
