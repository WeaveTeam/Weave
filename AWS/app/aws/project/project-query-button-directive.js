/**
 * 
 */
angular.module('aws.project')//name of module
.directive('projectQueryButton', function($compile) {//name of directive (part used in HTML)
  return {//way of building directive by returning a directive description object
	  restrict: 'E',//invoking the directive as an 'Element'
	  //require : 'ngModel',
	  //inline template for specifying the html
	  template: '<button ng-model="ngModel" style="width: 500px;" type="button" class="btn btn-default">' +
	  	'<ul><li>Title: {{item.title}}</li><li>Date: {{item.date}}</li><li>Datatable: {{item.dataTable.title}}</li>' +
		  '</button>',
	  scope: true,
	  //registers all listeners on this specific DOM element
	  link: function(scope, element, attrs) {
		 
		  element.bind('click', function(){
			  scope.$parent.$parent.currentQuerySelected = scope.item;
			  console.log("current", scope.$parent.$parent.currentQuerySelected);
			 
		  });
	  } 
  	}; 
});
