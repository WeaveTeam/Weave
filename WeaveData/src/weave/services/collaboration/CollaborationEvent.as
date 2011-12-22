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
		/* EVENTS */
		public static const LOG:String 						= "collab_log";
		public static const CONNECT:String 					= "collab_connect";
		public static const DISCONNECT:String 				= "collab_disconnect";
		public static const USER_JOINED_CREATE_MOUSE:String = "user_joined_create_mouse";
		public static const USER_LEFT_REMOVE_MOUSE:String 	= "user_left_remove_mouse";
		public static const USER_LIST_UPDATED:String		= "user_list_updated";
		
		/* ERROR EVENTS */
		public static const NICK_ERROR:String 				= 'collab_nick_error';
		public static const LOCKED_ERROR:String 			= 'collab_locked_error';
		public static const RECONNECT_ERROR:String			= 'collab_reconnect_error';

		/* UI EVENTS */
		public static const CONN_SETTINGS_SAVED:String 		= "collab_conn_saved_settings";
		public static const ADDON_SETTINGS_SAVED:String 	= "collab_addon_settings_saved";
		
		/* CHAT EVENTS */
		public static const SEND_MESSAGE:String 			= "collab_send_message";
		
		
		//generic data
		private var text:String;
		private var from:String;
		private var color:uint;
		
		public function CollaborationEvent(type:String, text:String = null, from:String = null, color:uint = 0)
		{
			super(type);
			this.text = text;
		}
		
		public function getText():String
		{
			return text;
		}
		public function getFrom():String
		{
			return from;
		}
		public function getColor():uint
		{
			return color;
		}
		
	}
}