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

	/*	This class defines a list of events that are used to talk
	*	from the collaboration service, to the collaboration tool
	*	that contains it.
	*/
	public class CollaborationEvent extends Event
	{
		/* EVENTS */
		public static const LOG:String 						= "collab_log";
		public static const CONNECT:String 					= "collab_connect";
		public static const DISCONNECT:String 				= "collab_disconnect";
		public static const USER_JOINED_ROOM:String 		= "user_joined_room";
		public static const USER_LEFT_ROOM:String 			= "user_left_room";
		public static const USER_UPDATE_MOUSE_POS:String 	= "user_update_mouse_pos";
		public static const USER_REQUEST_MOUSE_POS:String	= "user_request_mouse_pos";
		public static const USER_UPDATE_USERLIST:String		= "user_update_userlist";
		public static const USER_REQUEST_USERLIST:String	= "user_request_userlist";
		public static const USER_LIST_UPDATED:String		= "user_list_updated";
		public static const REQUEST_MOUSE_CONTROL:String    = "collab_request_mouse_control";
		public static const RELINQUISH_MOUSE_CONTROL:String = "collab_relinquish_mouse_control";
		
		/* ERROR EVENTS */
		public static const NICK_ERROR:String 				= 'collab_nick_error';
		public static const LOCKED_ERROR:String 			= 'collab_locked_error';
		public static const RECONNECT_ERROR:String			= 'collab_reconnect_error';

		/* UI EVENTS */
		public static const CONN_SETTINGS_CONNECT:String 	= "collab_conn_settings_connect";
		public static const CONN_SETTINGS_DISCONNECT:String = "collab_conn_settings_disconnect";
		public static const ADDON_SETTINGS_SAVED:String 	= "collab_addon_settings_saved";
		public static const PARTICIPANT_PANEL_SHOW:String   = "collab_participant_panel_show";
		
		/* CHAT EVENTS */
		public static const SEND_MESSAGE:String 			= "collab_send_message";
		public static const UPDATE_PING:String				= "collab_update_ping";
		public static const UPDATE_MIC:String				= "collab_update_mic";
		public static const UPDATE_CAM:String				= "collab_update_cam";
		public static const SEND_MOUSE_CONTROL_REQUEST:String = "collab_send_mouse_control_request";
		public static const SEND_RELINQUISH_MOUSE_CONTROL:String = "collab_send_relinquish_mouse_control";
		
		private var text:String;
		private var color:uint;
		private var x:Number;
		private var y:Number;
		private var o:Object;
		private var queue:Array;
		
		//Constructor for each CollaborationEvent.
		public function CollaborationEvent(type:String, text:String = null, color:uint = 0, x:Number = 0, y:Number = 0, o:Object = null, queue:Array = null)
		{
			super(type);
			this.text = text;
			this.color = color;
			this.x = x;
			this.y = y;
			this.o = o;
			this.queue = queue;
		}
		
		public function getText():String
		{
			return text;
		}
		public function getColor():uint
		{
			return color;
		}
		public function getX():Number
		{
			return x;
		}
		public function getY():Number
		{
			return y;
		}
		public function getInfo():Object
		{
			return o;
		}
		public function getQueue():Array
		{
			return queue;
		}
	}
}