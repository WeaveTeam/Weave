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
    templateUrl: 'tlps/weave.tlps.html',
    controller: 'weaveContentCtrl'
  };

$scope.openDialog = function(partial){
	
  };
})

.controller('weaveContentCtrl', function($scope, $http, dialog){

	$scope.cl = function(){
	    dialog.close();
	 };

});
