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
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableBoolean;
	import weavejs.data.column.AlwaysDefinedColumn;
	
	public class SolidFillStyle implements ILinkableObject
	{
		/**
		 * Used to enable or disable fill patterns.
		 */
		public const enable:LinkableBoolean = Weave.linkableChild(this, new LinkableBoolean(true));
		
		/**
		 * These properties are used with a basic Graphics.setFill() function call.
		 */
		public const color:AlwaysDefinedColumn = Weave.linkableChild(this, new AlwaysDefinedColumn(NaN));
		public const alpha:AlwaysDefinedColumn = Weave.linkableChild(this, new AlwaysDefinedColumn(1.0));
		
		public function getStyle(key:IQualifiedKey):Object
		{
			return {
				'color': color.getValueFromKey(key, Number),
				'alpha': alpha.getValueFromKey(key, Number)
			};
		}
	}
}
