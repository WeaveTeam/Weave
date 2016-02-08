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

package weave.ui.CustomDataGrid
{
	import mx.core.ClassFactory;
	
	import weave.Weave;
	import weave.api.core.IDisposableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.registerDisposableChild;
	import weave.core.LinkableBoolean;
	import weave.data.KeySets.KeySet;
	import weave.utils.ColumnUtils;
	
	public class DataGridColumnForQKeyWithFilterAndGraphics extends DataGridColumnForQKey implements IDisposableObject
	{
		public function DataGridColumnForQKeyWithFilterAndGraphics(attrColumn:IAttributeColumn, showColors:LinkableBoolean, colorFunction:Function)
		{
			super(attrColumn);
			this.showColors = showColors;
			this.colorFunction = colorFunction;
			this.itemRenderer = new ClassFactory(DataGridQKeyRendererWithGraphics);
			
			registerDisposableChild(attrColumn, this);
			attrColumn.addImmediateCallback(this, handleColumnChange, true);
		}
		
		public function dispose():void
		{
			attrColumn.removeCallback(handleColumnChange);
			attrColumn = null;
			selectionKeySet = null;
			showColors = null;
			filterComponent = null;
			colorFunction = null;
			
			sortCompareFunction = null;
			labelFunction = null;
			itemRenderer = null;
		}
		
		/**
		 * This function should have the following signature: function(column:IAttributeColumn, key:IQualifiedKey, cell:UIComponent):Number
		 * The return value should be a color, or NaN for no color.
		 */
		public var colorFunction:Function = null;
		public var selectionKeySet:KeySet = Weave.defaultSelectionKeySet;
		public var probeKeySet:KeySet = Weave.defaultProbeKeySet;
		public var showColors:LinkableBoolean = null;
		
		protected var _filterComponent:IFilterComponent;	
		public function get filterComponent():IFilterComponent
		{
			return _filterComponent;
		}
		
		public function set filterComponent(filterComp:IFilterComponent):void
		{				
			_filterComponent = filterComp;
			
			if (filterComp)
				_filterComponent.mapColumnToFilter(this);
		}
		
		private function handleColumnChange():void
		{
			headerText = ColumnUtils.getTitle(attrColumn);
		}
	}
}