angular.module('aws.directives.fileUpload', ['aws.router'])
    .directive('fileUpload', function() {
        return {
            link: function($scope, elem, attrs) {
                $(elem).fileReader({
                    "debugMode": true,
                    "filereader": "lib/jquery/filereader.swf"
                });

                $(elem).on("change", function(evt) {
                    var file = evt.target.files[0];
                    var reader = new FileReader();
                    reader.onload = function(e) {
                        $scope.file = e.target.result;
                        $scope.$broadcast('fileUploaded');
                    }
                    reader.readAsText(file);
                });

            }
        };
    })