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

package avmplus
{
	public final class DescribeType
	{
		public static const HIDE_NSURI_METHODS:uint = avmplus.HIDE_NSURI_METHODS;
		public static const INCLUDE_BASES:uint = avmplus.INCLUDE_BASES;
		public static const INCLUDE_INTERFACES:uint = avmplus.INCLUDE_INTERFACES;
		public static const INCLUDE_VARIABLES:uint = avmplus.INCLUDE_VARIABLES;
		public static const INCLUDE_ACCESSORS:uint = avmplus.INCLUDE_ACCESSORS;
		public static const INCLUDE_METHODS:uint = avmplus.INCLUDE_METHODS;
		public static const INCLUDE_METADATA:uint = avmplus.INCLUDE_METADATA;
		public static const INCLUDE_CONSTRUCTOR:uint = avmplus.INCLUDE_CONSTRUCTOR;
		public static const INCLUDE_TRAITS:uint = avmplus.INCLUDE_TRAITS;
		public static const USE_ITRAITS:uint = avmplus.USE_ITRAITS;
		public static const HIDE_OBJECT:uint = avmplus.HIDE_OBJECT;
		public static const FLASH10_FLAGS:uint = avmplus.FLASH10_FLAGS;
		
		public static const ACCESSOR_FLAGS:uint = INCLUDE_TRAITS | INCLUDE_ACCESSORS;
		public static const INTERFACE_FLAGS:uint = INCLUDE_TRAITS | INCLUDE_INTERFACES;
		public static const METHOD_FLAGS:uint = INCLUDE_TRAITS | INCLUDE_METHODS;
		public static const VARIABLE_FLAGS:uint = INCLUDE_TRAITS | INCLUDE_VARIABLES;
		
		public static const GET_INSTANCE_INFO:uint = INCLUDE_BASES | INCLUDE_INTERFACES | INCLUDE_VARIABLES | INCLUDE_ACCESSORS | INCLUDE_METHODS | INCLUDE_METADATA | INCLUDE_CONSTRUCTOR | INCLUDE_TRAITS | USE_ITRAITS;
		public static const GET_CLASS_INFO:uint = INCLUDE_INTERFACES | INCLUDE_VARIABLES | INCLUDE_ACCESSORS | INCLUDE_METHODS | INCLUDE_METADATA | INCLUDE_TRAITS | HIDE_OBJECT;
		
		public static function getInstanceInfo(o:*):Object
		{
			return describeTypeJSON(o, GET_INSTANCE_INFO);
		}
		
		public static function getClassInfo(o:*):Object
		{
			return describeTypeJSON(o, GET_CLASS_INFO);
		}
		
		/**
		 * avmplus.describeTypeJSON(o:*, flags:uint):Object
		 */
		public static const getInfo:Function = describeTypeJSON;
	}
}
