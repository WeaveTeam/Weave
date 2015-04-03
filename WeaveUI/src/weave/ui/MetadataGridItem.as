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
    public class MetadataGridItem
    {
		/**
		 * @param property The name of the metadata item
		 * @param value The starting value of the metadata item
		 */
		public function MetadataGridItem(property:String, value:Object = null)
		{
			this.property = property;
			this.oldValue = value || '';
			this.value = value || '';
		}
		
		public var property:String;
		public var oldValue:Object;
		public var value:Object;
		
		public function get changed():Boolean
		{
			// handle '' versus null
			if (!oldValue && !value)
				return false;
			
			return oldValue != value;
		}
    }
}
