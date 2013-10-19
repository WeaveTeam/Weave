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

package weave.data.AttributeColumns
{
	import flash.utils.getQualifiedClassName;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
	import weave.core.LinkableWatcher;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.utils.ColumnUtils;

	/**
	 * This column provides reprojected geometries for an internal geometry column.
	 * 
	 * @author adufilie
	 */
	public class ReprojectedGeometryColumn extends ExtendedDynamicColumn
	{
		private function debugTrace(..._):void { } // comment this line to enable debugging
		
		public function ReprojectedGeometryColumn()
		{
			// force the internal column to always be a ReferencedColumn
			internalDynamicColumn.requestLocalObject(ReferencedColumn, true);
			addImmediateCallback(this, updateReprojectedColumn);
			
			var self:Object = this;
			boundingBoxCallbacks.addImmediateCallback(this, function():void{ debugTrace(self, 'boundingBoxCallbacks', boundingBoxCallbacks); });
		}
		
		/**
		 * These callbacks are triggered when the list of keys or bounding boxes change.
		 */		
		public const boundingBoxCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);
		private const boundingBoxCallbacksTriggerWatcher:LinkableWatcher = newLinkableChild(boundingBoxCallbacks, LinkableWatcher);
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.PROJECTION)
			{
				var srs:String = projectionSRS.value;
				if (srs != null && srs != '')
					return srs;
			}
			
			return super.getMetadata(propertyName);
		}
		
		override public function getInternalColumn():IAttributeColumn
		{
			return reprojectedColumnWatcher.target as IAttributeColumn;
		}
		
		/**
		 * This is the SRS code of the destination projection when reprojecting geometries from the internal column.
		 */		
		public const projectionSRS:LinkableString = newLinkableChild(this, LinkableString);
		
		/**
		 * This function updates the private _reprojectedColumn variable.
		 */		
		private function updateReprojectedColumn():void
		{
			var ref:IColumnReference = (super.getInternalColumn() as ReferencedColumn).internalColumnReference;
			var newColumn:IAttributeColumn = WeaveAPI.ProjectionManager.getProjectedGeometryColumn(ref, projectionSRS.value);
			
			reprojectedColumnWatcher.target = _reprojectedColumn = newColumn;
		}
		
		private var _reprojectedColumn:IAttributeColumn;
		private const reprojectedColumnWatcher:LinkableWatcher = newLinkableChild(this, LinkableWatcher, handleReprojectedColumnChange);
		
		private function handleReprojectedColumnChange(cleanup:Boolean = false):void
		{
			// if _unprojectedColumn is not null, it means there is no reprojection to do.
			var _unprojectedColumn:StreamedGeometryColumn = ColumnUtils.hack_findNonWrapperColumn(_reprojectedColumn) as StreamedGeometryColumn;
			
			// get the callback target that should trigger boundingBoxCallbacks
			var newTarget:ILinkableObject = _unprojectedColumn ? _unprojectedColumn.boundingBoxCallbacks : _reprojectedColumn;
			
			debugTrace(this, '_unprojectedColumn =', _unprojectedColumn);
			debugTrace(this, 'target =', newTarget);
			
			boundingBoxCallbacksTriggerWatcher.target = newTarget;
		}
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_reprojectedColumn)
				return _reprojectedColumn.getValueFromKey(key, dataType);
			
			return super.getValueFromKey(key, dataType);
		}
	}
}
