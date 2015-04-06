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
	
	import weave.api.data.IQualifiedKey;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IFillStyle;
	import weave.core.LinkableBoolean;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;

	/**
	 * SolidFillStyle
	 * 
	 * @author adufilie
	 */
	public class SolidFillStyle implements IFillStyle
	{
		public function SolidFillStyle()
		{
		}
		
		/**
		 * Used to enable or disable fill patterns.
		 */
		public const enable:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(true));
		
		/**
		 * These properties are used with a basic Graphics.setFill() function call.
		 */
		public const color:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(NaN));
		public const alpha:AlwaysDefinedColumn = registerLinkableChild(this, new AlwaysDefinedColumn(1.0));
		
		/**
		 * This function sets the fill on a Graphics object using the saved fill properties.
		 * @param recordKey The record key to initialize the fill style for.
		 * @param graphics The Graphics object to initialize.
		 * @return A value of true if this function began a fill, or false if it did not.
		 */
		public function beginFillStyle(recordKey:IQualifiedKey, target:Graphics):Boolean
		{
			var params:Array = getBeginFillParams(recordKey);
			if (params)
			{
				target.beginFill(params[0], params[1]);
				return true;
			}
			target.endFill();
			return false;
		}
		
		/**
		 * @return [color, alpha] or null if there is no fill
		 */
		public function getBeginFillParams(recordKey:IQualifiedKey):Array
		{
			if (enable.getSessionState())
			{
				var fillColor:Number = color.getValueFromKey(recordKey, Number);
				if (isFinite(fillColor))
				{
					var fillAlpha:Number = alpha.getValueFromKey(recordKey, Number);
					return [fillColor, fillAlpha];
				}
			}
			return null;
		}
		
		// backwards compatibility
		[Deprecated(replacement="enable")] public function set enabled(value:Object):void
		{
			try {
				enable.setSessionState(value['defaultValue']);
			} catch (e:Error) { }
		}
	}
}
