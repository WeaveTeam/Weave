/*
* Copyright 2007-2011 the original author or authors.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/
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
		
		/**
		 * avmplus.describeTypeJSON(o:*, flags:uint):Object
		 */
		public static function getJSONFunction():Function
		{
			return describeTypeJSON;
		}
	}
}
