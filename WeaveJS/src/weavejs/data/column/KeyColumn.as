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

package weavejs.data.column
{
	import weavejs.api.data.ColumnMetadata;
	import weavejs.api.data.IQualifiedKey;
	import weavejs.core.LinkableString;
	import weavejs.data.CSVParser;
	import weavejs.data.EquationColumnLib;

	public class KeyColumn extends AbstractAttributeColumn
	{
		public function KeyColumn(metadata:Object = null)
		{
			super(metadata);
		}
		
		private static var csvParser:CSVParser;
		
		override public function getMetadata(propertyName:String):String
		{
			if (propertyName == ColumnMetadata.TITLE)
			{
				var kt:String = keyType.value;
				if (kt)
					return Weave.lang("Key ({0})", kt);
				return Weave.lang("Key");
			}
			if (propertyName == ColumnMetadata.KEY_TYPE)
				return keyType.value;
			
			return super.getMetadata(propertyName);
		}
		
		public const keyType:LinkableString = Weave.linkableChild(this, LinkableString);
		
		override public function getValueFromKey(key:IQualifiedKey, dataType:Class=null):*
		{
			var kt:String = keyType.value;
			if (kt && key.keyType != kt)
				return EquationColumnLib.cast(undefined, dataType);
			
			if (dataType == String)
				return key.toString();
			if (dataType == Number)
				return key.toNumber();
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