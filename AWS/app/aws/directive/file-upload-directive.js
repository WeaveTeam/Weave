angular.module('aws.directives.fileUpload', [])
        .directive('fileUpload', function($q) {
          return {
            restrict: 'E',
            template: "<label class='file-nput-btn'>{{label}}<input class='file-upload' type='file'/></label>",
            replace: true,
            link: function($scope, elem, attrs) {
              var deferred;
              $scope.label = attrs.label;
              $(elem).fileReader({
                "debugMode": true,
                "filereader": "lib/file-reader/filereader.swf"
              });
              $(elem).on('click', function(args) {
                deferred = $q.defer();
                $scope.fileUpload = deferred.promise;
              });
              $(elem).find('input').on("change", function(evt) {
                var file = evt.target.files[0];
                if (file.name == undefined || file.name == "") {
                  return;
                }
                var reader = new FileReader();
                reader.onload = function(e) {
                  var contents = {filename: file.name,
                    content: e.target.result};
                  scriptUploaded = contents;
                  $scope.$safeApply(function() { deferred.resolve(contents); });
                };
                reader.readAsText(file);
              });
            }
          };
        })
        .directive("fileread", [function () {
    return {
        scope: {
            fileread: "="
        },
        link: function (scope, element, attributes) {
            element.bind("change", function (changeEvent) {
                var reader = new FileReader();
                reader.onload = function (loadEvent) {
                    scope.$apply(function () {
                        scope.fileread = {
                        		content : loadEvent.target.result,
                        		filename : changeEvent.target.files[0].name
                        };
                    });
                };
                reader.readAsText(changeEvent.target.files[0]);
            });
        }
    };
}]).directive('ngEnter', function () {
    return function (scope, element, attrs) {
        element.bind("keydown keypress", function (event) {
            if(event.which === 13) {
                scope.$apply(function (){
                    scope.$eval(attrs.ngEnter);
                });

                event.preventDefault();
            }
        });
    };
});;;
        
