'use strict';

var app = angular.module('aws', ['aws.router',
                                 'aws.analysis', 
                                 'aws.configure',
                                 'aws.directives', 
                                 'aws.project', 
                                 //'aws.data', 
                                 'aws.queryObject',
                                 'aws.visualization',
                                 'ui.bootstrap', // don't need?
                                 'ui.select2',
                                 'ui.slider']);

app.run(['$rootScope', function($rootScope){
	$rootScope.$safeApply = function(fn, $scope) {
			if($scope == undefined){
				$scope = $rootScope;
			}
			
			fn = fn || function() {};
			if ( !$scope.$$phase ) {
        	$scope.$apply( fn );
    	}
    	else {
        	fn();
    	}
	};
}]);

angular.module('aws.analysis', ['aws.analysis.geography']);
angular.module('aws.directives', ['aws.directives.dualListBox',
                                  'aws.directives.fileUpload',
                                  'aws.directives.panel']);
angular.module('aws.configure', ['aws.configure.metadata',
                                 //'aws.configure.auth', 
                                 'aws.configure.script']);
angular.module('aws.visualization',['aws.visualization.tools',
                                    /*'aws.visualization.weave'*/]);
