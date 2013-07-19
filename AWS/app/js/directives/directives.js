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
angular.module('aws.directives', ['aws.Main'])
.directive('selectable', function(){
	return {
		link: function(scope, elem, attrs){
			$(elem).selectable({
				selected: function(event, ui){
					// nothing
					var temp = event;
				}
			});
//			{
//				stop: function(event, ui){
//					
//					var result = $( "#select-result" ).empty();
//			        $( ".ui-selected", this ).each(function() {
//			          var index = $( "#selectable li" ).index( this );
//			          result.append( " #" + ( index + 1 ) );
//			        });
//										// Not sure if this will work or if it should be $(elem)
////					var par = scope.$parent;
////					 var temp = $( ".ui-selected", par );
////					 scope.$parent.selectedResult = temp;
////					.each(function() {
////				          var index = $( "#selectable li" ).index( this );
////				          scope.$parent.selectedResult.push( index + 1 );
////				        });
//				}
//			}
			// var e = element.find(".sort");
			// e.sortable();
			// element.find(".portlet").disableSelection();
			//$( "#sortable" ).sortable();
		}
	};
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


