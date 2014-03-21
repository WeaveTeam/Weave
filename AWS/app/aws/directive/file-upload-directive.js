angular.module('aws.directives.fileUpload', [])
    .directive('fileUpload', function() {
        return {
          restrict: 'A',
          link: function($scope, elem, attrs) {
              $(elem).fileReader({
                  "debugMode": true,
                  "filereader": "lib/file-reader/filereader.swf"
              });

              $(elem).on("change", function(evt) {
                  var file = evt.target.files[0];
                  if(file.name.lenth < 3){
                    return;
                  }
                  $scope.scriptToUpload = file.name;
                  var reader = new FileReader();
                  reader.onload = function(e) {
                      $scope.fileToUpload = e.target.result;
                      //$scope.$broadcast('fileUploaded');
                  };
                  reader.readAsText(file);
              });
//              $scope.$watch('scriptToUpload', function(){
//                
//              });
          }
        };
    })