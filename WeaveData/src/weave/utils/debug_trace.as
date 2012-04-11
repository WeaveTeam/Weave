/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

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
			if (item is XML)
			{
				traceStr += (item as XML).toXMLString();
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
