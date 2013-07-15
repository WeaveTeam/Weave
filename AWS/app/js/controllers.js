'use strict';

/* Controllers */

/*angular.module('myApp.controllers', []).
  controller('MyCtrl1', [function() {
  }])
  .controller('MyCtrl2', [function() {
  }]);*/

function LeftPanelsCtrl($scope) {
	
	$scope.panels = [
		{
			panelTitle: "Analysis Builder",
			content: "Summary of selected parameters",
			id: 1
		},
		{
			panelTitle: "Calculation",
			content: "Summary of selected calculation script",
			id: 2
		},
		{
			panelTitle: "Weave",
			content: "Summary of visualization parameters",
			id: 3
		}
	];

	$scope.addContent = function(elem){
		$("#" + elem.id + "-panel").find(".portlet-content").html(elem.content);
	};
}

function DialogCtrl($scope, $dialog){
  $scope.opts = {
    backdrop: true,
    keyboard: true,
    backdropClick: true,
    templateUrl: 'partials/dialog.html',
    controller: 'DataClientCtrl' //found in the dataClient.js. in the "myApp.dataClient" module
  };

  $scope.openDialog = function(partial){
  	if(partial){
		$scope.opts.templateUrl = 'partials/' + partial + '.html';
	}
	var d = $dialog.dialog($scope.opts);
    d.open().then(function(result){
      if(result)
      {
        alert('dialog closed with result: ' + result);
      }
    });
  };

  $scope.openMessageBox = function(){
    var title = 'This is a message box';
    var msg = 'This is the content of the message box';
    var btns = [{result:'cancel', label: 'Cancel'}, {result:'ok', label: 'OK', cssClass: 'btn-primary'}];

    $dialog.messageBox(title, msg, btns)
      .open()
      .then(function(result){
        alert('dialog closed with result: ' + result);
    });
  };
  }


function ModalDemoCtrl($scope) {
	$scope.shouldBeOpen = false;
  $scope.open = function () {
  	console.log("open fired");
    $scope.shouldBeOpen = true;
  };

  $scope.close = function () {
    $scope.closeMsg = 'I was closed at: ' + new Date();
    $scope.shouldBeOpen = false;
  };

  $scope.items = ['item1', 'item2'];

  $scope.opts = {
    backdropFade: true,
    dialogFade:true
  };

}

function CollapseDemoCtrl($scope) {
  $scope.isCollapsed = false;
}

function PanelGenericCtrl($scope){
	$scope.typing = "first";
	$scope.b = [
		{
			panelTitle: "Indicator",
			x: "span3",
			y: 1,
			content: '<input type="text" ng-model="typing">'
		},
		{
			panelTitle: "Geography",
			x: "span4",
			y: 2,
			content: '{{typing}}'
		},
		{
			panelTitle: "By-Variables",
			x: "span6",
			y: 1,
			content: 'JSON Query Object <input id="panel6ImportButton"' +
                  'type="submit" value="Import..." /> <input id="panel6SaveButton"' +
                  'type="submit" value="Save" /> <input id="panel6EditButton"' +
                  'type="submit" value="Edit" />'
		},
		{
			panelTitle: "Time Period",
			x: "span2",
			y: 2},
		{
			panelTitle: "Query Object",
			x: "span2",
			y: 1,
			content: 'JSON Query Object <input id="panel6ImportButton"' +
                  'type="submit" value="Import..." /> <input id="panel6SaveButton"' +
                  'type="submit" value="Save" /> <input id="panel6EditButton"' +
                  'type="submit" value="Edit" />'
		},
		{
			panelTitle: "Round Trip Demo",
			x: "span6",
			y: 2,
			content: 'Script: <select id="scriptCombobox"></select> <br></br>' +
              'Data: <select id="dataCombobox"></select> <br></br>' +
              '<input id="scriptButton"  type="submit" value="Run Script" />'  +
              '<input id="scriptButton2" type="submit" value="CDCforQueries.R" />'
		}
	];
	angular.forEach($scope.b, function(value){
		 value.id = "a" + Math.floor((Math.random()*1000)+1);
	});
	
	$scope.addContent = function(elem){
		//var e = $(elem).find(".portlet-content");
		var e = $("#" + elem.id + "-panel").find(".portlet-content");
		var f = elem.content;
		e.html(f);
		//return f;
		// $(elem).find(".portlet-content").html(elem.content);
	};
	/*$scope.openDialog = function() {
		
		var msg = 'Hello World!';
    var options = {
      resolve: {
        msg: function () { return msg; }
      }
    };
    var d = $dialog.dialog(options);

		d.open('partials/dialog.html', 'dialogCtrl');
	};*/
    

	$scope.panelTitle = "Generic Panel";
	$scope.controls = [
		{
			name : 'slider'
		},
		{
			name : 'combobox'
		}

	];
}

function PhoneListCtrl($scope, Phone) {
	$scope.phones =[];/*= [
    {"name": "Nexus S",
     "snippet": "Fast just got faster with Nexus S.",
 		"age": 2},
    {"name": "Motorola XOOM™ with Wi-Fi",
     "snippet": "The Next, Next Generation tablet.",
 		"age": 0},
    {"name": "MOTOROLA XOOM™",
     "snippet": "The Next, Next Generation tablet.",
 		"age": 1}
  ];*/
  $scope.phones = Phone.query();
	// $http.get('phones/phones.json').success(function(data){
	// 	data = data.splice(0,5);
	// 	angular.forEach(data, function(phone){
	// 		$scope.phones.push(phone);});
	// })
	$scope.query = null;
  
  	$scope.orderProp = 'age';
}   
//PhoneListCtrl.$inject = ['$scope', 'Phone'];
   
function PhoneDetailCtrl($scope, $routeParams, Phone){
	$scope.phone = Phone.get({phoneId: $routeParams.phoneId}, function(phone){
		$scope.mainImage = phone.images[0];
	});
	$scope.setImage = function (imageUrl){
		$scope.mainImage = imageUrl;
	}
}
//PhoneDetailCtrl.$inject = ['$scope', '$routeParams', 'Phone'];

app.controller("MainController", function($scope) {
	$scope.selectedPerson = 0;
	$scope.selectedGenre = null;
	$scope.people = [
	{
		id: 0,
			name: 'Leon',
			music: [
				'Rock',
				'Metal',
				'Dubstep',
				'Electro'
			],
			live: true
	},{
		id: 1,
			name: 'Chris',
			music: [
				'Indie',
				'Drumstep',
				'Dubstep',
				'Electro'
			],
			live: true
		},
		{
			id: 2,
			name: 'Harry',
			music: [
				'Rock',
				'Metal',
				'Thrash Metal',
				'Heavy Metal'
			],
			live: false
		},
		{
			id: 3,
			name: 'Allyce',
			music: [
				'Pop',
				'RnB',
				'Hip Hop'
			],
			live: true
		}
	];
	$scope.newPerson = null;
	$scope.addNew = function() {
		console.log("addNew function");
		if($scope.newPerson != null && $scope.newPerson != ""){
			$scope.people.push({
				id: $scope.people.length,
				name: $scope.newPerson,
				live : true,
				music: []
			});
		}
	};
});
