package weave.ui.infomap.layout
{
	import flash.display.Graphics;
	
	import weave.api.core.ILinkableObject;
	import weave.ui.infomap.core.IInfoMapNode;
	import weave.ui.infomap.core.InfoMapNode;

	public interface IInfoMapNodeLayout extends ILinkableObject
	{
		
		
		/**
		 * This is name of the layout
		 **/
		function get name():String;
		
		/**
		 * This is a pointer to the NodeHandler using this layout
		 */
		function set parentNodeHandler(value:NodeHandler):void;
		
		/**
		 * This function will draw the base layout (probably using the NodeControlComponent)
		 * It requires the graphics of the NodeHandler
		 */
		function drawBaseLayout(graphics:Graphics):void;
		
		/**
		 * This function will plot the thumbnails based on a layout algorithm
		 **/
		function plotThumbnails():void;
	}
}