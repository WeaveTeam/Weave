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
		public function QKey(keyType:String, localName:*)
		{
			kt = keyType;
			ln = localName;
		}
		
		private var kt:String;
		private var ln:*;
		
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
		
		// This is a String containing both the namespace and the local name of the QKey
		//	public function toString():String
		//	{
		//		// The # sign is used in anticipation that a key type will be a URI.
		//		return kt + '#' + ln;
		//	}
	}
}
