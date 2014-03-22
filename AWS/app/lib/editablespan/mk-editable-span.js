var mod = angular.module('mk.editablespan', []);

mod.directive('editablespan', function() {
  return {
    restrict: 'E',
    template: '<div class="spanClass"><span ng-hide="editing" class="spanClass">{{text}}</span><form style="width: 90px;" ng-show="editing"><input style="width: 90px;" type="{{getInputType()}}" class="spanClass"></form><div>',
    scope: {
      text: '=model',
      onReady: '&',
      spanClass: '@',
      inputClass: '@',
      inputType: '@'
    },
    replace: true,
    link: function(scope, element, attrs) {
      scope.getInputType = function() {
        return scope.inputType || 'text';
      };

      var span = angular.element(element.children()[0]);
      var form = angular.element(element.children()[1]);
      var input = angular.element(element.children()[1][0]);
      
      // altered by Patrick Ryan 3/20/14
      scope.$watch('$parent.editMode',function(currentMode){
        if(currentMode == true){
          span.bind('click', function(event) {
            input[0].value = scope.text;
            startEdit();
          });
        }else if(currentMode == false){
          span.unbind('click');
        }
      });
      //form.addClass("inline-form");
      //element.addClass("pull-right");
      
      function startEdit() {
        bindEditElements();
        setEdit(true);
        input[0].focus();
      }

      function bindEditElements() {
        input.bind('blur', function() {
          stopEdit();
        });

        input.bind('keyup', function(event) {
          if(isEscape(event)) {
            stopEdit();
          }
        });

        form.bind('submit', function() {
          // you can't save empty string
          if(input[0].value) {
            save();
          }
          stopEdit();
        });
      }

      function save() {
        scope.text = input[0].value;
        scope.$apply();
        scope.onReady();
      }

      function stopEdit() {
        unbindEditElements();
        setEdit(false);
      }

      function unbindEditElements() {
        input.unbind();
        form.unbind();
      }

      function setEdit(value) {
        scope.editing = value;
        scope.$apply();
      }

      function isEscape(event) {
        return event && event.keyCode == 27;
      }
    }
  };
});

