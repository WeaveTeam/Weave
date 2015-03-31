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

package weave.visualization.plotters.styles
{
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.newLinkableChild;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.ILineStyle;
	import weave.compiler.StandardLib;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.NormalizedColumn;
	import weave.utils.EquationColumnLib;

	/**
	 * This class defines sessioned parameters for a call to Graphics.lineStyle().
	 * 
	 * @author adufilie
	 */
	public class SolidLineStyle implements ILineStyle
	{
		public function SolidLineStyle()
		{
			_callbackCollection = getCallbackCollection(this);
			weight.internalDynamicColumn.requestLocalObject(NormalizedColumn, true);
			
			normalizedWeightColumn.min.value = 1;
			normalizedWeightColumn.max.value = 5;
		}
		
		private var _callbackCollection:ICallbackCollection; // the ICallbackCollection for this object
		private var _triggerCounter:uint = 0; // used to detect change
		
		// This maps an AlwaysDefinedColumn to its preferred value type.
		private const _typesMap:Dictionary = new Dictionary(true);
		// this maps an AlwaysDefinedColumn to the default value for that column.
		// if there is an internal column in the AlwaysDefinedColumn, the default value is not stored
		private const _defaultValues:Dictionary = new Dictionary();

		/**
		 * @private
		 */
		private function createColumn(valueType:Class, defaultValue:*):AlwaysDefinedColumn
		{
			var column:AlwaysDefinedColumn = newLinkableChild(this, AlwaysDefinedColumn);
			_typesMap[column] = valueType;
			column.defaultValue.value = defaultValue;
			return column;
		}

		/**
		 * Used to enable or disable line drawing.
		 */
		public const enable:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * These properties are used with a basic Graphics.lineStyle() function call.
		 */
		
		public const color:AlwaysDefinedColumn = createColumn(Number, 0x000000);
		public const weight:AlwaysDefinedColumn = createColumn(Number, 1);
		public const alpha:AlwaysDefinedColumn = createColumn(Number, 0.5);
		
		public function get normalizedWeightColumn():NormalizedColumn { return weight.getInternalColumn() as NormalizedColumn; }
		
		public const pixelHinting:AlwaysDefinedColumn = createColumn(Boolean, false);
		public const scaleMode:AlwaysDefinedColumn = createColumn(String, "normal");
		public const caps:AlwaysDefinedColumn = createColumn(String, null);
		public const joints:AlwaysDefinedColumn = createColumn(String, null);
		public const miterLimit:AlwaysDefinedColumn = createColumn(Number, 3);
		
		/**
		 * IQualifiedKey -> getLineStyleParams() result
		 */
		private var cache:Dictionary;

		/**
		 * This function sets the line style on a Graphics object using the saved border properties.
		 * @param graphics The Graphics object to initialize.
		 */
		public function beginLineStyle(recordKey:IQualifiedKey, target:Graphics):void
		{
			target.lineStyle.apply(target, getLineStyleParams(recordKey));
		}
		
		public function getLineStyleParams(recordKey:IQualifiedKey):Array
		{
			if (_triggerCounter != _callbackCollection.triggerCounter)
			{
				_triggerCounter = _callbackCollection.triggerCounter;
				// update the default values
				for (var col:* in _typesMap)
				{
					var column:AlwaysDefinedColumn = col as AlwaysDefinedColumn;
					if (column.getInternalColumn() != null)
						delete _defaultValues[column];
					else
						_defaultValues[column] = EquationColumnLib.cast(column.defaultValue.value, _typesMap[column]);
				}
				cache = new Dictionary(true);
			}
			
			var params:Array = cache[recordKey];
			if (params)
				return params;
			
			var _color:* = _defaultValues[color];
			var _weight:* = _defaultValues[weight];
			var _alpha:* = _defaultValues[alpha];
			var _pixelHinting:* = _defaultValues[pixelHinting];
			var _scaleMode:* = _defaultValues[scaleMode];
			var _caps:* = _defaultValues[caps];
			var _joints:* = _defaultValues[joints];
			var _miterLimit:* = _defaultValues[miterLimit];
			
			if (enable.getSessionState())
			{
				var lineWeight:Number = _weight !== undefined ? _weight : weight.getValueFromKey(recordKey, Number);
				var lineColor:Number = _color !== undefined ? _color : color.getValueFromKey(recordKey, Number);
				if (!isNaN(lineColor)) // if color is defined, use basic Graphics.lineStyle() function
				{
					if (lineWeight == 0) // treat lineWeight 0 as no line
					{
						params = [0, 0, 0];
					}
					else
					{
						var lineAlpha:Number         = _alpha        !== undefined ? _alpha        :      alpha.getValueFromKey(recordKey, Number);
						var linePixelHinting:Boolean = _pixelHinting !== undefined ? _pixelHinting : StandardLib.asBoolean(pixelHinting.getValueFromKey(recordKey, Number));
						var lineScaleMode:String     = _scaleMode    !== undefined ? _scaleMode    :  scaleMode.getValueFromKey(recordKey, String) as String;
						var lineCaps:String          = _caps         !== undefined ? _caps         :       caps.getValueFromKey(recordKey, String) as String || null;
						var lineJoints:String        = _joints       !== undefined ? _joints       :     joints.getValueFromKey(recordKey, String) as String || null;
						var lineMiterLimit:Number    = _miterLimit   !== undefined ? _miterLimit   : miterLimit.getValueFromKey(recordKey, Number);

						params = [lineWeight, lineColor, lineAlpha, linePixelHinting, lineScaleMode, lineCaps, lineJoints, lineMiterLimit];
					}
				}
				else
				{
					params = [0, 0, 0];
				}
			}
			else
			{
				params = [0, 0, 0];
			}
			cache[recordKey] = params;
			return params;
		}
		
		// backwards compatibility
		[Deprecated(replacement="enable")] public function get enabled():AlwaysDefinedColumn
		{
			if (!_adc)
			{
				_adc = newDisposableChild(this, AlwaysDefinedColumn);
				_adc.defaultValue.addImmediateCallback(this, function():void { enable.value = _adc.defaultValue.value; });
			}
			return _adc;
		}
		private var _adc:AlwaysDefinedColumn
	}
}
