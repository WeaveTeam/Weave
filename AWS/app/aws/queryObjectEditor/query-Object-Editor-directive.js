/**
 * 
 */
angular.module('aws.queryObjectEditor')//name of module
.directive('queryObjectEditor', function($compile) {//name of directive (part used in HTML)
  return {
	  restrict: 'E',//
	  template: '<div id = "q" style="width: 500px; height: 600px;"></div>',
	  replace : true, 
	  
	  link: function(scope, element, attrs) {
		 
		  var editor = new jsoneditor.JSONEditor(element[0]);
			 editor.set(scope.currentJson);
			 
			 
			 scope.$watch('scope.currentJson',function(){
				 editor.set(scope.currentJson);
			 });
			 
	  } 
  	}; 
});
