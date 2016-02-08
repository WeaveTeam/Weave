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

package weavejs.net.beans
{	
	import weavejs.util.JSByteArray;

	public class AttributeColumnData 
	{
		public static const NO_TABLE_ID:int = -1;
		
		public var id:int;
		public var tableId:int;
		public var tableField:String;
		public var metadata:Object;
		public var keys:Array;
		public var data:Array;
		public var thirdColumn:Array;
		public var metadataTileDescriptors:JSByteArray;
		public var geometryTileDescriptors:JSByteArray;
	}
}
