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
		title : "starcraft"
	};
	this.selectedColumns = [];

});