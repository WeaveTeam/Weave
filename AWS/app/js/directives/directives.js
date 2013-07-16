'use strict';

/* Directives */

/*
angular.module('myApp.directives', []).
  directive('appVersion', ['version', function(version) {
    return function(scope, elm, attrs) {
      elm.text(version);
    };
  }]);*/

/**
* myApp Module
*
* Description
*/
angular.module('aws.directives', [])
.directive('sortable', function(){
	return {
		link: function(scope, element, attrs){
			// var e = element.find(".sort");
			// e.sortable();
			// element.find(".portlet").disableSelection();
			$( "#sortable" ).sortable();
		}
	}
}) 
.directive('portletPanel', function(){
	return {
		link: function($scope, elem, attr){
    		$(elem).addClass( "ui-widget ui-widget-content ui-helper-clearfix ui-corner-all" )
		      	.find( ".portlet-header" )
		        .addClass( "ui-widget-header ui-corner-all" )
		        .prepend( "<span class='ui-icon ui-icon-minusthick'></span>")
		        .end()
		      	.find( ".portlet-content" );

		    $(elem).find(".portlet-header").click(function() {
		    	console.log(elem);
		    	
      			$( elem ).find("span").toggleClass( "ui-icon-minusthick" ).toggleClass( "ui-icon-plusthick" );
      			$( elem ).find("span").parents( ".portlet:first" ).find( ".portlet-content" ).toggle();
    		});
		}
	};
})

