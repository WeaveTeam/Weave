angular.module('aws.directives.dragModule', []).
  directive('myDraggable', function($document) {
    return {
        restrict: 'EA',
        replace: true,
        link: function(scope, element, attr) {
      var startX = 0, startY = 0, x = scope.image.x || 0, y = scope.image.y || 0;
 
      element.css({
       position: 'relative',
       cursor: 'pointer'
      });
 
      element.on('mousedown', function(event) {
        // Prevent default dragging of selected content
        event.preventDefault();
        startX = event.pageX - x;
        startY = event.pageY - y;
        $document.on('mousemove', mousemove);
        $document.on('mouseup', mouseup);
      });
 
      function mousemove(event) {
        y = event.pageY - startY;
        x = event.pageX - startX;
        element.css({
          top: y + 'px',
          left:  x + 'px'
        });
      }
 
      function mouseup() {
        $document.unbind('mousemove', mousemove);
        $document.unbind('mouseup', mouseup);
      }
    }
    
    };
  });