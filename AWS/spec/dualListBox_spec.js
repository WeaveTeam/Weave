'use strict';

describe('Directive: dualListBox', function () {
  var $rootScope,
      element,
      $scope,
      $compile,
      $el,
      $body = $('body'),
      box;

  var tpl = '<select id="duallistboxid" dual-list-box multiple ng-model="selected"' + 
      'data-placeholder="Choose Columns"' +
      'ng-options="opt for opt in options">' +
      '</select>';
  // load the directive's module
  //beforeEach(angular.mock.module('aws'));
  //beforeEach();

  beforeEach(function(){
    module('aws','aws.directives','aws.panelControllers');

    inject(function ($injector) {
      $rootScope = $injector.get('$rootScope');
      $scope = $rootScope.$new();
      $compile = $injector.get('$compile');
      //console.log(tpl);
		  //box = 
      $body.append($compile(tpl)($scope));
      //console.log(box);
	  });
    
	  $rootScope.$digest();
    //$body.append(box);
    $el = $('.bootstrap-duallistbox-container');
  });

  it('should instantiate select element with data-duallistbox_generated attribute', function(){
    $scope.$digest();
    element = $el;//box.find('select');
	  //console.log($el);
    expect($el.hasClass('row')).toBeTruthy();
    //expect($el).toHaveClass('bootstrap-duallistbox-container');
  });

   
});