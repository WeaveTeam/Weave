'use strict';

/* Directives */

angular
.module('aws.directives', [ 'aws.Main' ])
.directive('fileUpload', function() {
	return {
		link : function($scope, elem, attrs) {
			$(elem).fileReader({"debugMode":true,"filereader":"lib/jquery/filereader.swf"});
			
			$(elem).on("change", function(evt){
				//console.log(evt.target.files);
				var file = evt.target.files[0];
				var reader = new FileReader();
				reader.onload = function(e) {
					$scope.jsonText =  $.parseJSON(e.target.result);
					$scope.$broadcast('newQueryLoaded');
					console.log(e.target.result);
					//var qh = new aws.QueryHandler(importedobjectfromjson);
					//qh.runQuery();
				}
				reader.readAsText(file);
				
			});
			
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
