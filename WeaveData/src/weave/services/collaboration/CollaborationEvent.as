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

package weave.services.collaboration
{
	import flash.events.Event;

	
	//This class defines a list of events that are used to talk
	//from the collaboration service, to the collaboration tool
	//that contains it.
	public class CollaborationEvent extends Event
	{
		public static const TEXT:String 		= "collab_text_receive";
//		public static const USERS_LIST:String 	= "collab_users_list_receive";
		public static const DISCONNECT:String 	= "collab_disconnect";
		
		//generic data
		public var data:Object;
		
		public function CollaborationEvent(type:String, data:Object)
		{
			this.data = data;
			super(type);
		}
		
		public function getText():String
		{
			return data as String;
		}
		
	}
}