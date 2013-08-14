'use strict';

/* Directives */

angular
.module('aws.directives', [ 'aws.Main' ])
.directive('selectable', function() {
	return {
		link : function(scope, elem, attrs) {
			$(elem).selectable({
				selected : function(event, ui) {
					// nothing
					var temp = event;
				}
			});
			// {
			// stop: function(event, ui){
			//					
			// var result = $( "#select-result" ).empty();
			// $( ".ui-selected", this ).each(function() {
			// var index = $( "#selectable li" ).index( this );
			// result.append( " #" + ( index + 1 ) );
			// });
			// // Not sure if this will work or if it should be $(elem)
			// // var par = scope.$parent;
			// // var temp = $( ".ui-selected", par );
			// // scope.$parent.selectedResult = temp;
			// // .each(function() {
			// // var index = $( "#selectable li" ).index( this );
			// // scope.$parent.selectedResult.push( index + 1 );
			// // });
			// }
			// }
			// var e = element.find(".sort");
			// e.sortable();
			// element.find(".portlet").disableSelection();
			// $( "#sortable" ).sortable();
		}
	};
})
.directive(
		'megaSelect',
		function() {
			return {
				link : function($scope, elem, attr) {
					$(elem).find("select").megaselectlist(	{
						animate: true, 
						multiple: true, 
						animateevent: "click"
						});
					
					}
			
			};
		})
.directive(
		'panel',
		function($compile, $templateCache) {
						
			return {
				restrict : "E",
				scope : {
					//refreshColumns: '='
				},
				templateUrl: function(tElement, tAttrs){
					return "tpls/"+tAttrs.paneltype+".tpls.html";
				},
				transclude: true,
				//template: $templateCache.get('./tpls/genericPortlet.tpls.html'),
				//controller : indicator +'Ctrl',
				link: function(scope, element, attrs, controller) {
					// Adding CSS classes to make a panel
					//controller = attrs.paneltype + 'Ctrl';
					$(element)
							.addClass(
									"ui-widget portlet ui-widget-content span4 ui-corner-all ui-helper-clearfix panel")
							.find(".portlet-header")
							.addClass(
									"ui-widget-header ui-helper-clearfix")
							.find("span").addClass(
									"panel-title-margins");
					scope.panelTitle = attrs.name;
					scope.selectorId = attrs.id;
					scope.panelType = attrs.type;
					//$compile(element.contents())(scope);

				}
				/*compile : function(element, attrs) {
					console.log(attrs);
					//this.controller = attrs.paneltype + 'Ctrl';
					return function(scope, element, attrs, controller) {
						// Adding CSS classes to make a panel
						controller = attrs.paneltype + 'Ctrl';
						$(element)
								.addClass(
										"ui-widget portlet ui-widget-content span4 ui-corner-all ui-helper-clearfix panel")
								.find(".portlet-header")
								.addClass(
										"ui-widget-header ui-helper-clearfix")
								.find("span").addClass(
										"panel-title-margins");
						scope.panelTitle = attrs.name;
						scope.selectorId = attrs.id;
						scope.panelType = attrs.type;
						 $compile(element.contents())(scope);

					}
				}*/

			};
		})
