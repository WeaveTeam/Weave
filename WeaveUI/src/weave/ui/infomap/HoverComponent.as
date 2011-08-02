package weave.ui.infomap
{
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.Timer;
	
	import mx.containers.Canvas;
	import mx.core.UIComponent;
	import mx.managers.PopUpManager;
	
	
	public class HoverComponent extends Canvas
	{
		public function HoverComponent()
		{
			this.setStyle("backgroundColor",0xEDE6E6);
			this.setStyle("borderStyle","solid");
			this.setStyle("borderColor",0xC40202);
			this.setStyle("cornerRadius",10);
			this.setStyle("borderThickness",2);
			this.minWidth = 250;
			this.minHeight = 300;
		}
		
		public var delay:Number = 1000;
		private var _parentComponent:UIComponent;
		
		private var timer:Timer;
		private var popped:Boolean = false;
		
		public function set parentComponent( parentComponent:UIComponent ):void
		{
			_parentComponent = parentComponent;
			if ( _parentComponent != null )
			{
				// if you call this directly object says "global" instead of "HoverComponent" (while compiling)
				// since global lead to flickering of hover component on stage.
				// Reason: Not figured out why?
				// solution: use as UI component
				var thisComponent:UIComponent = this;
				parentComponent.addEventListener( MouseEvent.MOUSE_OVER, function( evt:MouseEvent ):void
				{
					thisComponent.move( evt.stageX + 15, evt.stageY + 15 );					
					PopUpManager.addPopUp( thisComponent, parentComponent );
					popped = true;					
				});
				
				parentComponent.addEventListener( MouseEvent.MOUSE_OUT, function( evt:MouseEvent ):void
				{
					if ( popped )
					{
						PopUpManager.removePopUp( thisComponent );
						popped = false;
					}
				});
			}
		}
		
		public function get parentComponent():UIComponent
		{
			return _parentComponent;
		} 
	}
}