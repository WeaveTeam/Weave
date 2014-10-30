angular.module('aws.directives.popover-with-tpl', []).directive('popoverWithTpl', function($compile, $templateCache, $q, $http) {

  var getTemplate = function(templateUrl) {
    var def = $q.defer();

    var template = '';
    
    template = $templateCache.get(templateUrl);
    console.log(template);
    if (typeof template === "undefined") {
      $http.get(templateUrl)
        .success(function(data) {
          $templateCache.put(templateUrl, data);
          def.resolve(data);
        });
    }else {
    	 def.resolve(template);
    }

    return def.promise;
  };
  
  return {
    restrict: "A",
    link: function(scope, element, attrs) {
    	console.log(attrs.templateUrl);
      getTemplate(attrs.templateUrl).then(function(popOverContent) {
        var options = {
          content: popOverContent,
          placement: attrs.popoverPlacement,
          html: true,
          date: scope.date
        };
        $(element).popover(options);
      });
    }
  };
});