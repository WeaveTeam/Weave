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
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IColumnReference;
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.core.CallbackCollection;
	import weave.core.CallbackJuggler;
	import weave.core.LinkableDynamicObject;
	import weave.utils.ColumnUtils;
	
	/**
	 * This provides a wrapper for a referenced column.
	 * 
	 * @author adufilie
	 */
	public class ReferencedColumn extends CallbackCollection implements IColumnWrapper
	{
		/**
		 * This is a reference to another column.
		 */
		public const dynamicColumnReference:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IColumnReference));
		
		/**
		 * The trigger counter value at the last time the internal column was retrieved.
		 */		
		private var _prevTriggerCounter:uint = 0;
		/**
		 * the internal referenced column
		 */
		private var _internalColumn:IAttributeColumn = null;
		
		private const _columnJuggler:CallbackJuggler = new CallbackJuggler(this, triggerCallbacks, false);
		
		/**
		 * This is the actual IColumnReference object inside dynamicColumnReference.
		 */
		public function get internalColumnReference():IColumnReference
		{
			return dynamicColumnReference.internalObject as IColumnReference;
		}
		
		/**
		 * @inheritDoc 
		 */		
		public function getInternalColumn():IAttributeColumn
		{
			if (_prevTriggerCounter != triggerCounter)
			{
				_columnJuggler.target = _internalColumn = WeaveAPI.AttributeColumnCache.getColumn(internalColumnReference);
				_prevTriggerCounter = triggerCounter;
			}
			return _internalColumn;
		}
		
		
		/************************************
		 * Begin IAttributeColumn interface
		 ************************************/

		public function getMetadata(attributeName:String):String
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getMetadata(attributeName) : null;
		}

		public function getMetadataPropertyNames():Array
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getMetadataPropertyNames() : [];
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		public function get keys():Array
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.keys : [];
		}

		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		public function containsKey(key:IQualifiedKey):Boolean
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn && _internalColumn.containsKey(key);
		}
		
		/**
		 * getValueFromKey
		 * @param key A key of the type specified by keyType.
		 * @return The value associated with the given key.
		 */
		public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			if (_prevTriggerCounter != triggerCounter)
				getInternalColumn();
			return _internalColumn ? _internalColumn.getValueFromKey(key, dataType) : undefined;
		}
		
		public function toString():String
		{
			return debugId(this) + '(' + ColumnUtils.getTitle(this) + ')';
		}
		
		// backwards compatibility
		[Deprecated(replacement="dynamicColumnReference")] public function set columnReference(value:Object):void
		{
			setSessionState(dynamicColumnReference, value);
		}
	}
}
