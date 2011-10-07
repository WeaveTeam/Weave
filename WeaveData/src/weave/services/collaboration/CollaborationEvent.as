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
		public static const NICK_ERROR:String = 'collab_nick_error';
		public static const LOCKED_ERROR:String = 'collab_locked_error';

		public static const LOG:String 		= "collab_log";
		public static const CONNECT:String 	= "collab_connect";
		public static const DISCONNECT:String 	= "collab_disconnect";
		
		public static const USER_JOINED_CREATE_MOUSE:String = "user_joined_create_mouse";
		public static const USER_LEFT_REMOVE_MOUSE:String = "user_left_remove_mouse";
		
		//generic data
		public var data:Object;
		
		public function CollaborationEvent(type:String, data:Object = null)
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