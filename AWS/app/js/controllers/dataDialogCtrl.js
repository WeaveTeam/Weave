
/** DataDialog Module
 * DataDialogCtrl - Controls dialog button and closure.
 * DataDialogConnectCtrl - Manages the content of the Dialog. 
 */
angular.module('aws.DataDialog', [])
.controller('DataDialogCtrl',function($scope, $dialog){
  $scope.opts = {
    backdrop: true,
    keyboard: true,
    backdropClick: true,
    templateUrl: 'tlps/dataDialog.tlps.html',
    controller: 'DataDialogConnectCtrl'
  };

  $scope.openDialog = function(partial){
  	if(partial){
		$scope.opts.templateUrl = 'tlps/' + partial + '.tlps.html';
	}
	var d = $dialog.dialog($scope.opts);
    d.open().then(function(result){
      if(result)
      {
        alert('dialog closed with result: ' + result);
      }
    });
  };
})
.controller('DataDialogConnectCtrl', function($scope, $http, dialog){

	$scope.dataTables = null;
	$scope.conn = {
		serverType: "",
		sqlip:  "demo.oicweave.org",
		sqlport: "3306",
		sqluser: "root",
		sqlpass: "Tc1Sgp7nFc",
		sqldbname: "",
		connectionName: "",
		connectionPass: ""
	};

	$scope.close = function(result){
	    dialog.close(result);
	 };

	$scope.connect = function(){
		console.log("entered connect fcn");
		var res = $scope.getEntityHierarchyInfo($scope.conn.connectionName, $scope.conn.connectionPass, 0);
		for(var i in res){
			var table = res[i];
			$('#dataTables').append($("<option/>").val(table.id.toString()).text(table.title + " (" + table.numChildren + ")"));
			//appending this table of results to the data table selector
		}
	};
	
})
