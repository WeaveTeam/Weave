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

package weavejs.geom
{
	import weavejs.api.core.ICallbackCollection;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.data.EquationColumnLib;
	import weavejs.data.column.AlwaysDefinedColumn;
	import weavejs.data.column.NormalizedColumn;
	import weavejs.util.JS;

	public class SolidLineStyle implements ILinkableObject
	{
		public function SolidLineStyle()
		{
			_callbackCollection = Weave.getCallbacks(this);
			weight.internalDynamicColumn.requestLocalObject(NormalizedColumn, true);
			
			normalizedWeightColumn.min.value = 1;
			normalizedWeightColumn.max.value = 5;
		}
		
		private var _callbackCollection:ICallbackCollection; // the ICallbackCollection for this object

		private var _triggerCounter:uint = 0; // used to detect change
		
		// This maps an AlwaysDefinedColumn to its preferred value type.
		private const map_column_dataType:Object = new JS.Map();
		// this maps an AlwaysDefinedColumn to the default value for that column.
		// if there is an internal column in the AlwaysDefinedColumn, the default value is not stored
		private const map_column_defaultValue:Object = new JS.Map();
		
		private function createColumn(dataType:Class, defaultValue:*):AlwaysDefinedColumn
		{
			var column:AlwaysDefinedColumn = Weave.linkableChild(this, AlwaysDefinedColumn);
			map_column_dataType[column] = dataType;
			column.defaultValue.state = defaultValue;
			return column;
		}

		public const enable:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		
		public const color:AlwaysDefinedColumn = createColumn(Number, 0x000000);
		public const weight:AlwaysDefinedColumn = createColumn(Number, 1);
		public const alpha:AlwaysDefinedColumn = createColumn(Number, 0.5);
		public const caps:AlwaysDefinedColumn = createColumn(String, null);
		public const joints:AlwaysDefinedColumn = createColumn(String, null);
		public const miterLimit:AlwaysDefinedColumn = createColumn(Number, 3);
		
		public function get normalizedWeightColumn():NormalizedColumn { return weight.getInternalColumn() as NormalizedColumn; }
		
		/**
		 * For use with ColumnUtils.getRecords()
		 */
		public function get recordFormat():Object
		{
			return { 'color': color, 'weight': weight, 'alpha': alpha, 'caps': caps, 'joints': joints, 'miterLimit': miterLimit };
		}
		
		/**
		 * For use with ColumnUtils.getRecords()
		 */
		public function get recordType():Object
		{
			return { 'color': Number, 'weight': Number, 'alpha': Number, 'caps': String, 'joints': String, 'miterLimit': Number };
		}
		
		/**
		 * IQualifiedKey -> getLineStyleParams() result
		 */
		private var map_key_style:Object;

		public function getStyle(key:IQualifiedKey):Object
		{
			if (_triggerCounter != _callbackCollection.triggerCounter)
			{
				_triggerCounter = _callbackCollection.triggerCounter;
				// update the default values
				for (var col:* in JS.mapKeys(map_column_dataType))
				{
					var column:AlwaysDefinedColumn = col as AlwaysDefinedColumn;
					if (column.getInternalColumn() != null)
						map_column_defaultValue['delete'](column);
					else
						map_column_defaultValue.set(column, EquationColumnLib.cast(column.defaultValue.state, map_column_dataType.get(column)));
				}
				map_key_style = new JS.WeakMap();
			}
			
			var params:Object = map_key_style.get(key);
			if (params)
				return params;
			
			var _color:* = map_column_defaultValue.get(color);
			var _weight:* = map_column_defaultValue.get(weight);
			var _alpha:* = map_column_defaultValue.get(alpha);
			var _caps:* = map_column_defaultValue.get(caps);
			var _joints:* = map_column_defaultValue.get(joints);
			var _miterLimit:* = map_column_defaultValue.get(miterLimit);
			
			var lineColor:Number = _color !== undefined ? _color : color.getValueFromKey(key, Number);
			var lineWeight:Number = _weight !== undefined ? _weight : weight.getValueFromKey(key, Number);
			var lineAlpha:Number         = _alpha        !== undefined ? _alpha        :      alpha.getValueFromKey(key, Number);
			var lineCaps:String          = _caps         !== undefined ? _caps         :       caps.getValueFromKey(key, String) as String || null;
			var lineJoints:String        = _joints       !== undefined ? _joints       :     joints.getValueFromKey(key, String) as String || null;
			var lineMiterLimit:Number    = _miterLimit   !== undefined ? _miterLimit   : miterLimit.getValueFromKey(key, Number);

			params = {
				'color': lineColor,
				'weight': lineWeight,
				'alpha': lineAlpha,
				'caps': lineCaps,
				'joints': lineJoints,
				'miterLimit': lineMiterLimit
			};
			
			map_key_style.set(key, params);
			
			return params;
		}
	}
}
