angular.module('aws.directives.panel', ['aws.router'])

.directive(
        'panel',
        function($compile, $templateCache) {

            return {
                restrict: "E",
                scope: {
                    //refreshColumns: '='
                },
                templateUrl: function(tElement, tAttrs) {
                    if(tAttrs.hasOwnProperty("tpl")){
                    	return tAttrs.tpl;
                    }
                	return "aws/visualization/tools/" + tAttrs.paneltype + "/" + tAttrs.paneltype + ".html";
                },
                transclude: true,
                //template: $templateCache.get('./tpls/genericPortlet.tpls.html'),
                //controller : indicator +'Ctrl',
                link: function(scope, element, attrs, controller) {
                    // Adding CSS classes to make a panel
                    //controller = attrs.paneltype + 'Ctrl';
                    $(element)
                        .addClass(
                            "ui-widget portlet ui-widget-content col-md-4 ui-corner-all ui-helper-clearfix panel")
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
        });