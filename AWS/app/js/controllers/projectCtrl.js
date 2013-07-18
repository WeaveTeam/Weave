/**
 * Project Module
 * ProjectButtonCtrl - Controls actions of the project button.
 * ProjectContentCtrl - Controls dialog content for project actions.
 */
angular.module('aws.project', [])
.controller('ProjectButtonCtrl', function(){

	$scope.opts = {
	    templateUrl: 'tlps/ProjectMenu.tlps.html'
	}
	
	$scope.items = [
	  "New...",
	  "Open",
	  "Save",
	  "Quit"
	];
})