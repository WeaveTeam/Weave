/**
 * Created by patrick on 3/24/14.
 */
describe("It should fetch a list of scripts from server",function(){
    var httpBackend, $scope, $q, scriptManagerService;

    beforeEach(angular.mock.module('aws'), function(){
        console.log("running in beforeEach");
        scriptManagerService = "testing";
        angular.mock.inject(function($rootScope){
            $scope = $rootScope.new();
        });
    });
    it("tests to see if running",function(){
        console.log("test suite not empty!");
        //angular.mock.module('aws');

        expect(scriptManagerService).toBe("testing");
        expect($scope).toBeTruthy();
    })
});