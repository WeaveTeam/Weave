/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package weave.ui
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.containers.Canvas;
	import mx.controls.TextInput;
	
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.UIUtils;
	import weave.api.primitives.IBounds2D;
	import weave.primitives.Bounds2D;
	import weave.utils.BitmapText;

	/**
	 * FOR TESTING PURPOSES ONLY
	 * 
	 * @author adufilie
	 */
	public class UITestBitmapText extends DraggablePanel
	{
		public function UITestBitmapText()
		{
			super();

			// this is where the magic happens
			UIUtils.linkDisplayObjects(visCanvas, children);

			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy = "off";

			this.autoLayout = true;
			
			addChild(visCanvas);
			
			visCanvas.percentHeight = 100;
			visCanvas.percentWidth = 100;
			
			addChild(editor);
			editor.addEventListener(Event.CHANGE, handleTextChange);
			rawChildren.addChild(b);
			b.x = 50;
			b.y = 50;
		}
		private const editor:TextInput = new TextInput();
		private const bt:BitmapText = new BitmapText();
		private const b:Bitmap = new Bitmap(new BitmapData(300, 200));
		private function handleTextChange(event:Event):void
		{
			b.bitmapData.fillRect(b.bitmapData.rect, 0x80808080);
			bt.text = editor.text;
			bt.x = 20;
			bt.y = 50;
			var bounds:IBounds2D = new Bounds2D();
			bt.getUnrotatedBounds(bounds);
			trace(bounds.getRectangle(), bt.text);
			b.bitmapData.fillRect(bounds.getRectangle(), 0xFFAA8000);
			bt.draw(b.bitmapData);
		}

		protected const visCanvas:Canvas = new Canvas();
		
		public const children:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(DisplayObject));
	}
}
