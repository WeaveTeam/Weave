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
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IQualifiedKey;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.core.SessionManager;
	import weave.utils.DebugUtils;

	/**
	 * ProxyColumn
	 * This class is a proxy (a wrapper) for another attribute column.
	 * 
	 * @author adufilie
	 */
	public class ProxyColumn extends AbstractAttributeColumn implements IColumnWrapper
	{
		public function ProxyColumn(metadata:XML = null)
		{
			super(metadata);
		}
		
		/**
		 * @return the keys associated with this column.
		 */
		override public function get keys():Array
		{
			var column:IAttributeColumn = internalNonProxyColumn;
			return column ? column.keys : [];
		}
		
		/**
		 * @param key A key to test.
		 * @return true if the key exists in this IKeySet.
		 */
		override public function containsKey(key:IQualifiedKey):Boolean
		{
			return _internalColumn && _internalColumn.containsKey(key);
		}

		/**
		 * This function updates the proxy metadata.
		 * @param metadata New metadata for the proxy.
		 */
		public function setMetadata(metadata:XML):void
		{
			_metadata = metadata;
			triggerCallbacks();
		}

		/**
		 * The metadata specified by ProxyColumn will override the metadata of the internal column.
		 * First, this function checks thet ProxyColumn metadata.
		 * If the value is null, it checks the metadata of the internal column.
		 * @param propertyName The name of a metadata property to get.
		 * @return The metadata value of the ProxyColumn or the internal column, ProxyColumn metadata takes precendence.
		 */
		override public function getMetadata(propertyName:String):String
		{
			var overrideValue:String = super.getMetadata(propertyName);
			if (overrideValue == null && _internalColumn != null)
				return _internalColumn.getMetadata(propertyName);
			return overrideValue;
		}
		
		/**
		 * proxyID
		 * This is a globally unique ID for this ProxyColumn object.
		 */
		private const proxyID:String = 'Proxy'+DebugUtils.generateID();
		
		/**
		 * internalNonProxyColumn
		 * As long as internalAttributeColumn is a ProxyColumn, this function will
		 * keep traversing internalAttributeColumn until it reaches an IAttributeColumn that
		 * is not a ProxyColumn.
		 * @return An attribute column that is not a ProxyColumn, or null.
		 */
		public function get internalNonProxyColumn():IAttributeColumn
		{
			var column:IAttributeColumn = _internalColumn;
			while (column is ProxyColumn)
				column = (column as ProxyColumn)._internalColumn;
			return column;
		}
		
		/**
		 * internalAttributeColumn
		 * This is the IAttributeColumn object contained in this ProxyColumn.
		 */
		private var _internalColumn:IAttributeColumn = null;
		public function getInternalColumn():IAttributeColumn
		{
			return _internalColumn;
		}
		public function setInternalColumn(newColumn:IAttributeColumn):void
		{
			if (newColumn == this)
			{
				trace("WARNING! Attempted to set ProxyColumn.internalAttributeColumn to self: " + this);
				return;
			}
			
			if (_internalColumn == newColumn)
				return;

			// clean up ties to previous column
			if (_internalColumn != null)
				(WeaveAPI.SessionManager as SessionManager).unregisterLinkableChild(this, _internalColumn);

			// save pointer to new column
			_internalColumn = newColumn;
			
			// initialize for new column
			if (_internalColumn != null)
				registerLinkableChild(this, _internalColumn);

			triggerCallbacks();
		}
		
		/**
		 * The functions below serve as wrappers for matching function calls on the internalAttributeColumn.
		 */
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class = null):*
		{
			var value:*

			if (_internalColumn == null)
				value = NaN;
			else
				value = _internalColumn.getValueFromKey(key, dataType);

			return value;
		}

		/**
		 * dispose
		 * This function should be called when the ProxyColumn is no longer in use.
		 * All existing pointers to objects should be set to null so they can be garbage collected.
		 */
		override public function dispose():void
		{
			super.dispose();
			setInternalColumn(null); // this will remove the callback that was added to the internal column
		}

		override public function toString():String
		{
			return proxyID + '( ' + (getInternalColumn() ? getInternalColumn() : super.toString()) + ' )';
		}
		
		/**
		 * undefinedColumn
		 * This object can be used as an alternative to a null
		 * return value for a function returning a ProxyColumn.
		 */
		public static const undefinedColumn:ProxyColumn = registerDisposableChild(ProxyColumn, new ProxyColumn(<attribute name="Undefined"/>));
	}
}
