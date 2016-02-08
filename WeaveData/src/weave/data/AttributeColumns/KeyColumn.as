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

package weave.data.AttributeColumns
{
	import weave.api.data.ColumnMetadata;
	import weave.api.data.IQualifiedKey;
	import weave.api.newLinkableChild;
	import weave.core.LinkableString;
	import weave.utils.EquationColumnLib;

	public class KeyColumn extends AbstractAttributeColumn
	{
		public function KeyColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.TITLE)
			{
				var kt:String = keyType.value;
				if (kt)
					return lang("Key ({0})", kt);
				return lang("Key");
			}
			if (propertyName == ColumnMetadata.KEY_TYPE)
				return keyType.value;
			
			return super.getMetadata(propertyName);
		}
		
		public const keyType:LinkableString = newLinkableChild(this, LinkableString);
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			var kt:String = keyType.value;
			if (kt && key.keyType != kt)
				return EquationColumnLib.cast(undefined, dataType);
			
			if (dataType == String)
				return key.localName;
			
			if (dataType == IQualifiedKey)
				return key;
			
			return EquationColumnLib.cast(key, dataType);
		}
		
		override public function get keys():Array
		{
			return [];
		}
	}
}