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
	import weave.api.WeaveAPI;
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.data.AttributeColumnMetadata;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.juggleImmediateCallback;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.CallbackCollection;
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
		public function ReprojectedGeometryColumn()
		{
			// force the internal column to always be a ReferencedColumn
			internalDynamicColumn.requestLocalObject(ReferencedColumn, true);
			addImmediateCallback(this, updateReprojectedColumn);
		}
		
		/**
		 * These callbacks are triggered when the list of keys or bounding boxes change.
		 */		
		public const boundingBoxCallbacks:ICallbackCollection = newLinkableChild(this, CallbackCollection);
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == AttributeColumnMetadata.PROJECTION)
			{
				var srs:String = projectionSRS.value;
				if (srs != null && srs != '')
					return srs;
			}
			
			return super.getMetadata(propertyName);
		}
		
		override public function getInternalColumn():IAttributeColumn
		{
			return _reprojectedColumn;
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
			
			// if the column didn't change, do nothing
			if (_reprojectedColumn == newColumn)
				return;
			
			delayCallbacks();
			
			if (_reprojectedColumn)
			{
				(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _reprojectedColumn);
				_reprojectedColumn.removeCallback(handleReprojectedColumnChange);
			}
			
			_reprojectedColumn = newColumn;
			
			if (_reprojectedColumn)
			{
				registerLinkableChild(this, _reprojectedColumn);
				_reprojectedColumn.addImmediateCallback(this, handleReprojectedColumnChange);
			}
			
			handleReprojectedColumnChange();
			triggerCallbacks();
			resumeCallbacks();
		}
		
		private function handleReprojectedColumnChange(cleanup:Boolean = false):void
		{
			// if _unprojectedColumn is not null, it means there is no reprojection to do.
			var _unprojectedColumn:StreamedGeometryColumn = ColumnUtils.hack_findNonWrapperColumn(_reprojectedColumn) as StreamedGeometryColumn;
			
			// get the callback target that should trigger boundingBoxCallbacks
			var target:ILinkableObject = _unprojectedColumn ? _unprojectedColumn.boundingBoxCallbacks : _reprojectedColumn;
			
			if (_prevBBTarget != target)
			{
				juggleImmediateCallback(_prevBBTarget, target, this, boundingBoxCallbacks.triggerCallbacks);
				boundingBoxCallbacks.triggerCallbacks();
				_prevBBTarget = target;
			}
		}
		
		private var _prevBBTarget:ILinkableObject = null;
		
		private var _reprojectedColumn:IAttributeColumn = null;
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_reprojectedColumn)
				return _reprojectedColumn.getValueFromKey(key, dataType);
			
			return super.getValueFromKey(key, dataType);
		}
	}
}
