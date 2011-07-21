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
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.text.engine.BreakOpportunity;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getQualifiedClassName;
	
	import mx.charts.renderers.BoxItemRenderer;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	
	import org.igniterealtime.xiff.auth.*;
	import org.igniterealtime.xiff.bookmark.*;
	import org.igniterealtime.xiff.conference.*;
	import org.igniterealtime.xiff.core.*;
	import org.igniterealtime.xiff.data.*;
	import org.igniterealtime.xiff.data.register.RegisterExtension;
	import org.igniterealtime.xiff.data.search.SearchExtension;
	import org.igniterealtime.xiff.events.*;
	import org.igniterealtime.xiff.exception.*;
	import org.igniterealtime.xiff.filter.*;
	import org.igniterealtime.xiff.im.*;
	import org.igniterealtime.xiff.privatedata.*;
	import org.igniterealtime.xiff.util.*;
	import org.igniterealtime.xiff.vcard.*;
	
	import weave.api.core.ILinkableHashMap;
	import weave.core.ErrorManager;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	
	public class CollaborationService extends EventDispatcher
	{
		public function CollaborationService()
		{
			// register these classes so they will not lose their type when they get serialized and then deserialized.
			for each (var c:Class in [SessionStateMessage, TextMessage])
				registerClassAlias(getQualifiedClassName(c), c);
		}
		
		private var _room:Room;
		private function get room():Room
		{
			if( _room == null)
				throw new Error("Not Connected to Collaboration Server");
			return _room;
		}
		
		private var connection:XMPPConnection;
	
		//Contains a user's "Buddy List"
		/* public static var roster:Roster; */
		private var selfJID:String;
		
		private var serverIP:String;
		private var serverName:String;
		private var port:int;
		private var roomToJoin:String;
		private var username:String;
		
		private var lastMessage:SessionStateMessage	= new SessionStateMessage();
		private var messageIndex:int = 0;
		
		//private var server:String = 						"129.63.17.121";
		private var compName:String = 						"@conference";
		
		//The port defines a secure connection
		//5222(unsecure) , 5223(secure)
		private var baseEncoder:Base64Encoder = 			new Base64Encoder();
		private var baseDecoder:Base64Decoder = 			new Base64Decoder();
		
		//setting a room that doesn't exist will register that
		//new room with the server
		private var connectedToRoom:Boolean = 				false;
		private var isConnected:Boolean = 					false;
		
		public function connect( serverIP:String, serverName:String, port:int, roomToJoin:String, username:String ):void
		{
			if (isConnected == true) disconnect();
			isConnected = true;
			
			this.serverIP = serverIP;
			this.serverName = serverName;
			this.port =	port;
			this.roomToJoin = roomToJoin;
			this.username = username;
			
			postMessageToUser("connecting to " +serverName + " at " + serverIP + ":" + port.toString() + " ...\n");
			trace( "connecting to " +serverName + " at " + serverIP + ":" + port.toString() ); 
			connection = new XMPPConnection();
			
			connection.useAnonymousLogin = true;
			/* connection.username = "admin";
			connection.password = "admin"; */
			
			connection.server = serverIP;
			connection.port = port;
			
			// For a full list of listeners, see XIFF/src/org/jivesoftware/xiff/events
			connection.addEventListener(LoginEvent.LOGIN, onLogin);
			connection.addEventListener(MessageEvent.MESSAGE, onReceiveMessage);
			connection.addEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
			connection.addEventListener(XIFFErrorEvent.XIFF_ERROR, onError);
			
			connection.connect();
		}
		
		public function disconnect():void
		{
			connectedToRoom = false;
			connection.disconnect();
		}
		
		public function hasConnection():Boolean 
		{
			return connectedToRoom;
		}
		
		public function sendMessage( message:String, target:String=null ):void
		{
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(new TextMessage(selfJID, message)));
			else
				room.sendMessage(encodeObject(new TextMessage(selfJID, message)));
		}
		
		public function sendSessionState( state:Object, target:String=null ):void
		{
			messageIndex++;
			var currentMessage:SessionStateMessage = new SessionStateMessage(lastMessage.id, selfJID + "." + String(currentMessage), state);
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(currentMessage) );
			else
				room.sendMessage(encodeObject(currentMessage) );
			
			lastMessage = currentMessage;
		}
		
		private function postMessageToUser( message:String ) :void
		{
			if( this.username == "Host")
				return;
			dispatchEvent(new CollaborationEvent(CollaborationEvent.TEXT, message));
		}
		
		private function updateUsersList():void
		{
			var s:String = "";
			for each (var occ:RoomOccupant in room)
			{					
				if( occ.displayName != "Host")
					s += occ.displayName + '\n';
			}
			dispatchEvent(new CollaborationEvent(CollaborationEvent.USERS_LIST, s));
		}
		
		
		private function joinRoom(roomName:String):void
		{
			postMessageToUser( "joined room: " + roomToJoin + "\n" );
			_room = new Room(connection);
			
			room.nickname = username;
			postMessageToUser( "set alias to: " + room.nickname + "\n" );
			room.roomJID = new UnescapedJID(roomName + compName + '.' + serverName);
			
			room.addEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
			room.addEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
			room.addEventListener(RoomEvent.USER_JOIN, onUserJoin);
			room.addEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			room.join();
		}
		
		private function onLogin(e:LoginEvent):void
		{
			trace("connection successful");
			var message:String = "";
			
			message += "connected as ";
			if( connection.useAnonymousLogin == true )
				message += "anonymous user: ";
			message += connection.username + "\n";
			postMessageToUser( message );
			
			joinRoom(roomToJoin);
		}
		
		private function onReceiveMessage(e:MessageEvent):void
		{	
			if( e.data.id != null)
			{
				// handle a message from a user
				var o:Object = decodeObject(e.data.body);
				if (o is SessionStateMessage)
				{
					var ssm:SessionStateMessage = o as SessionStateMessage;
					if( this.username == "Host")
					{
						//What to do when recieving a private SessionStateMessage i.e. Host
						if( e.data.from.resource != this.username )
							sendSessionState(ssm.state);
					}
					else if( ssm.id != selfJID )
					{
						dispatchEvent(new CollaborationEvent(CollaborationEvent.STATE_CHANGED, ssm.state));
					}
				}
				else if (o is TextMessage)
				{
					var tm:TextMessage = o as TextMessage;
					postMessageToUser( tm.id + ": " + tm.message + "\n" );
				}
				else
				{
					ErrorManager.reportError(new Error("Unable to determine message type: ", ObjectUtil.toString(o)));
				}
			}
			else
			{
				// messages from the server are always strings
				postMessageToUser( "server: " + e.data.body + "\n" );
			}
		}
		
		private function onDisconnect(e:DisconnectionEvent):void
		{
			isConnected = false;
		}
		
		private function onError(e:XIFFErrorEvent):void
		{
			trace("Error: " + e.errorMessage);
		}
		
		private function onRoomJoin(e:RoomEvent):void
		{
			trace("Joined Room")
			//_room = Room(e.target);
			connectedToRoom = true;
			selfJID = room.userJID.resource;
			lastMessage.id = selfJID + "." + String(messageIndex);
			updateUsersList();
			dispatchEvent(new CollaborationEvent( CollaborationEvent.CREATE_HOST, null ));
		}
		
		private function onTimeout(event:RoomEvent):void
		{
			if (connectedToRoom)
				Alert.show("Would you like to reconnect?", "Disconnected", Alert.YES | Alert.NO, null, closeHandler, null, Alert.YES);
			clean();
		}
		
		private function onUserJoin(event:RoomEvent):void
		{
			if( event.nickname != "Host")
			{
				postMessageToUser( event.nickname + " has joined the room.\n" );
				updateUsersList();
			}
		}
		
		private function onUserLeave(event:RoomEvent):void
		{
			if( event.nickname != "Host")
			{
				postMessageToUser( event.nickname + " has left the room.\n" );
				updateUsersList();
			}
		}
			
		private function clean():void
		{
			dispatchEvent( new CollaborationEvent(CollaborationEvent.CLEAR_LOG, null) );
			dispatchEvent( new CollaborationEvent(CollaborationEvent.USERS_LIST, "") );
			
			//== Remove Event Listeners ==//
			connection.removeEventListener(LoginEvent.LOGIN, onLogin);
			connection.removeEventListener(XIFFErrorEvent.XIFF_ERROR, onError);
			connection.removeEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
			connection.removeEventListener(MessageEvent.MESSAGE, onReceiveMessage);
			if( room != null)
			{
				room.removeEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
				room.removeEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
				room.removeEventListener(RoomEvent.USER_JOIN, onUserJoin);
				room.removeEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			}
			
			//== Reset variables ==//
			isConnected = 				false;
			connection = 				null;
			_room =						null;
			selfJID = 					null;
		}
		
		private function closeHandler(e:CloseEvent):void
		{
			if(e.detail == Alert.YES )
			{
				clean();
				if( connection == null )
					Alert.show( "Unable to connect at this time.", "Connection Issue");
			}
		}
		
		private function encodeObject(toEncode:Object):String
		{
			baseEncoder.reset();
			baseEncoder.insertNewLines = false;
			var byteArray:ByteArray = new ByteArray();
			byteArray.writeObject(toEncode);
			byteArray.position = 0;
			baseEncoder.encodeBytes(byteArray);
			return baseEncoder.toString();
		}
		
		private function decodeObject(message:String):Object
		{
			baseDecoder.reset();
			baseDecoder.decode(message);
			var byteArray:ByteArray = baseDecoder.toByteArray();
			byteArray.position = 0;
			return byteArray.readObject();
		}
	}
}

internal class SessionStateMessage
{
	public function SessionStateMessage(parentID:String=null, id:String=null, state:Object=null)
	{
		this.parentID = parentID;
		this.id = id;
		this.state = state;
	}
	
	public var parentID:String;
	public var id:String;
	public var state:Object;
}

internal class TextMessage
{
	public function TextMessage(id:String=null, message:String=null)
	{
		this.id = id;
		this.message = message;
	}
	
	public var id:String;
	public var message:String;
}
