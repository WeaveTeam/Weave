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

package weave.utils
{
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;

	/**
	 * @author abaumann
	 * @author adufilie
	 */
	public function debug_trace(originClass:Object, ... args):void
	{
		var traceStr:String = "[" + getTimer() + "] {" + getQualifiedClassName(originClass) + "}\n";
		
		for each (var item:* in args)
		{
			if (item is XML_Class)
			{
				traceStr += (item as XML_Class).toXMLString();
			}
			else
			{
				var indent:int = 24;
				var classStr:String = getQualifiedClassName(item);
				
				// get rid of path
				var pos:int = classStr.indexOf("::");
				if (pos >= 0)
					classStr = classStr.substr(pos + 2);
				
				// indent so ':' will line up
				classStr = "  {" + classStr + "}";
				while (classStr.length < indent)
					classStr += " ";
				
				traceStr += classStr + ":  " + item + "\n";
			}
		}
		
		trace(traceStr);
	}
}
