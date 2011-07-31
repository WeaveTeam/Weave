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
			this.setStyle("backgroundColor",0xffffff);
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
				var thisComponent:UIComponent = this;
				
				//Detects mouse overs and starts a timer to display the hover
				parentComponent.addEventListener( MouseEvent.MOUSE_OVER, function( evt:MouseEvent ):void
				{
					//Initialize the timer to trigger one time after delay millis
					timer = new Timer( delay, 1 );
					
					//Wait for the timer to complete
					timer.addEventListener(TimerEvent.TIMER_COMPLETE, function( tevt:TimerEvent ):void
					{
						//move to a position relative to the mouse cursor
						thisComponent.move( evt.stageX + 15, evt.stageY + 15 );
						
						//Popup the hover component
						PopUpManager.addPopUp( thisComponent, parentComponent );
						
						//Set a flag so we know that a popup actually occurred
						popped = true;
					});
					
					//start the timer
					timer.start();
				});
				
				parentComponent.addEventListener( MouseEvent.MOUSE_OUT, function( evt:MouseEvent ):void
				{
					//If the timer exists we stop it
					if ( timer )
					{
						timer.stop();
						timer = null;
					} 
					
					//If we popped up, remove the popup
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