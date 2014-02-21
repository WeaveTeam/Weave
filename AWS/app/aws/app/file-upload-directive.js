angular.module('aws.directives.fileUpload', ['aws.router'])
    .directive('fileUpload', function() {
        return {
            link: function($scope, elem, attrs) {
                $(elem).fileReader({
                    "debugMode": true,
                    "filereader": "lib/jquery/filereader.swf"
                });

                $(elem).on("change", function(evt) {
                    //console.log(evt.target.files);
                    var file = evt.target.files[0];
                    var reader = new FileReader();
                    reader.onload = function(e) {
                        $scope.jsonText = $.parseJSON(e.target.result);
                        $scope.$broadcast('newQueryLoaded');
                    }
                    reader.readAsText(file);

                });

            }
        };
    })