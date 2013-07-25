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
				templateUrl : 'tlps/ProjectMenu.tlps.html',
				controller : 'ProjectButtonCtrl'
			};

			$scope.openDialog = function(partial) {
				console.log("hello");
				if (partial) {
					$scope.opts.templateUrl = 'tlps/' + partial + '.tlps.html';
				}

				var d = $dialog.dialog($scope.opts);
				d.open();
			};
		})

.controller('ProjectButtonCtrl', function($scope, $http, dialog) {
	$scope.close = function() {
		dialog.close();
	};
})