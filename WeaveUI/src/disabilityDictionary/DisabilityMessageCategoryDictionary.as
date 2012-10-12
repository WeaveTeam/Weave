/*
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
package disabilityDictionary
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import mx.rpc.events.ResultEvent;
	
	import weave.editors.Disability;

	public class DisabilityMessageCategoryDictionary 
	{
		
		public var messageCategoryMap : Dictionary = new Dictionary();
		public var messageCategoryID : String = "IT";
		public var message : String = "increasing trend";
		
		
		
		public function lineChartDictionary():void
		{
			
			
			messageCategoryMap[messageCategoryID] = message; // eg : IT = "increasing trend"
		   
			
		}

		
		public function setMessageCategoryID(_propertyNames:Array):Array
		{
			
			var messageCategoryIDs : Array = new Array();
			
			if (_propertyNames[0]>1)  // propertyNames[0] -> slope
				messageCategoryIDs.push("IT");
				
			
			return messageCategoryIDs;
		}
	}
}