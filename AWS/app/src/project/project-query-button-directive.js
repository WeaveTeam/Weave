/**
 * renders the list of query objects in a particular Project
 */
angular.module('aws.project')//name of module
.directive('projectQueryButton', function($compile) {//name of directive (part used in HTML)
  return {//way of building directive by returning a directive description object
	  restrict: 'E',//invoking the directive as an 'Element'
	  scope : true, 
	  //inline template for specifying the html
	  template: '<div class = "check" margin-bottom: 10px; style=" width:800px; border:1px solid #000">' +
	  	'<ul><li>Title: {{item.title}}</li>'+
	  	'<li>Date: {{item.date}}</li>'+
	  	'<li>Datatable: {{item.dataTable.title}}</li></ul>' +
		'<button ng-click = "runQueryInAnalysisBuilder()" class="btn btn-default btn-success"><span class = "glyphicon glyphicon-play-circle"></span></button>' + 
	  	'<button ng-click = "deleteQueryObject()" class="btn btn-default btn-danger"><span class = "glyphicon glyphicon-remove-circle"></span></button>' + 
	  	'<div>',
	  	replace : true, 
	  //registers all listeners on this specific DOM element
	  link: function(scope, element, attrs) {
		 //sets the current query selected
		  element.bind('click', function(){
			  scope.$parent.$parent.currentQuerySelected = scope.item;
			  console.log("current", scope.$parent.$parent.currentQuerySelected);
		  });

		  //FYI accessing a particular element of a directve using jquery
		// $("div.check").bind('click', function(){
		  //console.log("ruuuuuuuuuuun");
		 // });
		  	  
	  } 
  	}; 
});
