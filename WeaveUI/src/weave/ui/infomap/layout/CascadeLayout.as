package weave.ui.infomap.layout
{
	import flash.display.Graphics;

	public class CascadeLayout implements IInfoMapNodeLayout
	{
		public function CascadeLayout()
		{
		}
		
		private var _parentNodeHandler:NodeHandler;
		public function set parentNodeHandler(value:NodeHandler):void
		{
			_parentNodeHandler = value;
		}
		
		private var baseLayoutDrawn:Boolean = false;
		public function drawBaseLayout(graphics:Graphics):void
		{
			
			_parentNodeHandler.nodeControl.keywordTextArea.toolTip = _parentNodeHandler.node.keywords.value;
			_parentNodeHandler.nodeControl.keywordTextArea.setStyle("textAlign","center");
			
			
			
			baseLayoutDrawn = true;
		}
		
		public function plotThumbnails():void
		{
			
		}
		
	}
}