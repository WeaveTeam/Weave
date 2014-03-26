/**
 * Created by patrick on 3/24/14.
 */
describe("It should fetch a list of scripts from server", function(){
    var httpBackend, $scope, $q, scriptManagerService;
    var resolvedValue;

    beforeEach(module('aws.configure.script'));
    beforeEach(inject(function($injector,  _$q_, $rootScope){
        $scope = $rootScope.$new();
        $q = _$q_;
        scriptManagerService = $injector.get('scriptManagerService');
//        console.log("scriptmanagerservice:", scriptManagerService);
//        spyOn(scriptManagerService, 'getListOfScripts')
//            .andCallFake(function(){
//                var d = $q.defer();
//                setTimeout(function(){
//                    resolvedValue = "success";
//                }, 100);
//                return d.promise;
//        });
//        scriptManagerService.getListOfScripts().then(function(){
//            dataObject.listOfScripts =["a","b"];
//        });


    }));

//    beforeEach(function(){
//        waitsFor(function(){
//            return resolvedValue !== undefined;
//        }, 500);
//    });
    it('should have ', function(){
        expect(typeof(scriptManagerService.getListOfScripts)).toEqual('function');
    });

//     it('should make a request to the backend for list of scripts', function(){
//
//        scriptManagerService.getListOfScripts();
//
//        expect(scriptManagerService.getListOfScripts).toHaveBeenCalled();
//        console.log(scriptManagerService.dataObject.listOfScripts);
//
//        expect(scriptManagerService.dataObject.listOfScripts).toBeDefined();
//    });
    it('should call the aws Rclient',function(){
        var fake = function(callback){
            return callback(['a','b']);
        }
        spyOn(aws.RClient,'getListOfScripts').andCallFake(fake);
        scriptManagerService.getListOfScripts();
        expect(aws.RClient.getListOfScripts).toHaveBeenCalled();
        expect(scriptManagerService.dataObject.listOfScripts).toBeDefined();
        expect(scriptManagerService.dataObject.listOfScripts).toEqual(['a','b']);

    })

    afterEach(function(){
        console.log("running aftereach");
    })
});