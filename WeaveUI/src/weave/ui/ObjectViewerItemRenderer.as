/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.ui
{
	import flash.display.DisplayObject;
	
	import mx.controls.treeClasses.TreeItemRenderer;
	import mx.controls.treeClasses.TreeListData;
	import mx.core.IUITextField;
	import mx.core.UITextField;
	import mx.core.mx_internal;
	
	use namespace mx_internal;
	
	public class ObjectViewerItemRenderer extends TreeItemRenderer
	{
		private var _secondLabel:IUITextField;
		private var _secondLabelX:Number;
		private var _secondLabelFunction:Function;
		
		public function set secondLabelFunction(value:Function):void
		{
			_secondLabelFunction = value;
			invalidateProperties();
		}
		
		public function set secondLabelX(value:Number):void
		{
			_secondLabelX = value;
			invalidateProperties();
		}
		
		override mx_internal function createLabel(childIndex:int):void
		{
			super.mx_internal::createLabel(childIndex)
			
			if (!_secondLabel)
			{
				_secondLabel = IUITextField(createInFontContext(UITextField));
				_secondLabel.styleName = this;
				_secondLabel.x = _secondLabelX;
				_secondLabel.mouseEnabled = false;
				
				if (childIndex == -1)
					addChild(DisplayObject(_secondLabel));
				else 
					addChildAt(DisplayObject(_secondLabel), childIndex - 1);
			}
		}
		
		/**
		 *  @private
		 *  Removes the label from this component.
		 */
		override mx_internal function removeLabel():void
		{
			super.mx_internal::removeLabel();
			if (_secondLabel != null)
			{
				removeChild(DisplayObject(_secondLabel));
				_secondLabel = null;
			}
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if (_secondLabel)
			{
				_secondLabel.x = _secondLabelX;
				_secondLabel.text = _secondLabelFunction != null ? _secondLabelFunction((this.listData as TreeListData).item) : null;
			}
		}
		
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w, h);
			
			if (_secondLabel)
			{
				_secondLabel.width = width - _secondLabel.x;
				_secondLabel.height = label.height;
			}
		}
	}
}