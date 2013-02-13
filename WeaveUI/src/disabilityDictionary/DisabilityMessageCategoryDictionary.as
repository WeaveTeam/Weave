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
		
		public var messageCategoryMap:Dictionary;
		
		public function DisabilityMessageCategoryDictionary():void
		{
			messageCategoryMap = DisabilityMessageProperties.getMessageCategoryMap();
		}
		
		
		public function setMessage(messageID:Array):Array//returns an array of strings(messages)
			
		{
			var messageCollections:Array = new Array();//collects all the messages together
			for (var i:int =0; i < messageID.length; i++)//picking up as many nessages as there are IDs
			{
				messageCollections[i] = messageCategoryMap[messageID[i]];
			}
			
			
			return messageCollections;
		}
		
		
		
		//this function will take an object as a parameter, it will loop over its properties and collect the respective IDs after passing the if else checks
		public function collectMessageCategoryID(inputObject:DisabilityObject):Array//returns an array of actual text messages
		{
			
			var finalMessages:Array;
			var messageCategoryIDs : Array = new Array();
			var objProperties:Array = inputObject.properties;
			
			//for(var i:int = 0; i < objProperties.length; i++)
			//{
			//flesh out these if else checks to make the decision for the message category
			
			
			if (objProperties[0] > 0)   // propertyNames[0] -> slope hard coded
				messageCategoryIDs.push(DisabilityMessageProperties.INCREASING_TREND_ID);
			else if (objProperties[0] < 0)
				messageCategoryIDs.push(DisabilityMessageProperties.DECREASING_TREND_ID);
			else if (objProperties[0] == 0)
				messageCategoryIDs.push(DisabilityMessageProperties.STABLE_TREND_ID);
			//    else
			//        messageCategoryIDs.push(DisabilityMessageProperties.UNDEFINED_TREND_ID);
			
			//}
			
			
			finalMessages = setMessage(messageCategoryIDs);
			
			return finalMessages;
		}
	}
}