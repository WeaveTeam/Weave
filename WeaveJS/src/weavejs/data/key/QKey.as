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

package weavejs.data.key
{
	import weavejs.api.data.IQualifiedKey;

	/**
	 * This class is internal to QKeyManager because instances
	 * of QKey should not be instantiated outside QKeyManager.
	 */
	internal class QKey implements IQualifiedKey
	{
		private static var serial:uint = 0;
		
		public function QKey(keyType:String, localName:String, toString:String)
		{
			kt = keyType;
			ln = localName;
			_toNumber = serial++;
			_toString = toString;
		}
		
		private var kt:String;
		private var ln:String;
		private var _toNumber:Number;
		private var _toString:String;
		
		/**
		 * This is the namespace of the QKey.
		 */
		public function get keyType():String
		{
			return kt;
		}
		
		/**
		 * This is local record identifier in the namespace of the QKey.
		 */
		public function get localName():String
		{
			return ln;
		}
		
		public function toNumber():Number
		{
			return _toNumber;
		}
		
		public function toString():String
		{
			return _toString;
		}
	}
}
