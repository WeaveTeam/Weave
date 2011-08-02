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
	import com.modestmaps.extras.ui.FullScreenButton;
	
	import flash.events.ErrorEvent;
	import flash.events.EventDispatcher;
	import flash.net.registerClassAlias;
	import flash.text.engine.BreakOpportunity;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.getQualifiedClassName;
	
	import mx.charts.renderers.BoxItemRenderer;
	import mx.controls.Alert;
	import mx.events.CloseEvent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.messaging.messages.ErrorMessage;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	import mx.validators.StringValidator;
	
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
	
	import weave.api.core.IDisposableObject;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.registerDisposableChild;
	import weave.api.registerLinkableChild;
	import weave.api.setSessionState;
	import weave.core.ErrorManager;
	import weave.core.SessionStateLog;
	import weave.data.AttributeColumns.StreamedGeometryColumn;
	
	public class CollaborationService extends EventDispatcher implements IDisposableObject
	{
		public function CollaborationService( root:ILinkableObject )
		{
			this.root = root;
			
			// register these classes so they will not lose their type when they get serialized and then deserialized.
			for each (var c:Class in [FullSessionState, SessionStateMessage, TextMessage])
				registerClassAlias(getQualifiedClassName(c), c);
		}
		
		private var root:ILinkableObject;
		
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
		
		//private var server:String = 						"129.63.17.121";
		private var compName:String = 						"@conference";
		
		//The port defines a secure connection
		//5222(unsecure) , 5223(secure)
		private var baseEncoder:Base64Encoder = 			new Base64Encoder();
		private var baseDecoder:Base64Decoder = 			new Base64Decoder();
		
		//setting a room that doesn't exist will register that
		//new room with the server
		private var connectedToRoom:Boolean = 				false;
		private var connectedToServer:Boolean = 			false;
		
		private var stateLog:SessionStateLog = null;
		
		// this will be called by SessionManager to clean everything up
		public function dispose():void
		{
			if( isConnectedToRoom() == true) disconnect();
		}
		
		//function to send diff
		private function handleStateChange():void
		{
			// note: this code may need to be changed later if SessionStateLog implementation changes.
			if (isConnectedToRoom() == true)
			{
				var log:Array 	 = stateLog.undoHistory;
				var entry:Object = log[log.length - 1];
				sendSessionStateDiff( entry.id, entry.forward );
			}
		}
		
		public function connect( serverIP:String, serverName:String, port:int, roomToJoin:String, username:String ):void
		{
			if (connectedToServer == true) disconnect();
			connectedToServer = true;
			
			this.serverIP = serverIP;
			this.serverName = serverName;
			this.port =	port;
			this.roomToJoin = roomToJoin;
			this.username = username;
			
			postMessageToUser("connecting to " + serverName + " at " + serverIP + ":" + port.toString() + " ...\n");
			connection = new XMPPConnection();
			
			connection.useAnonymousLogin = true;
			/* 
			Registered Login:
			connection.username = "registeredUser";
			connection.password = "password"; 
			*/
			
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
			// stop logging
			if (stateLog)
				disposeObjects(stateLog);
			
			postMessageToUser( "Disconnected from server\n" );
			dispatchEvent( new CollaborationEvent(CollaborationEvent.USERS_LIST, "") );
			
			//== Remove Event Listeners ==//
			connection.removeEventListener(LoginEvent.LOGIN, onLogin);
			connection.removeEventListener(XIFFErrorEvent.XIFF_ERROR, onError);
			connection.removeEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
			connection.removeEventListener(MessageEvent.MESSAGE, onReceiveMessage);
			if( _room != null)
			{
				room.removeEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
				room.removeEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
				room.removeEventListener(RoomEvent.USER_JOIN, onUserJoin);
				room.removeEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			}
			
			connection.disconnect();
		}
		
		public function isConnectedToServer():Boolean 
		{
			return connectedToServer;
		}
		
		public function isConnectedToRoom():Boolean 
		{
			return connectedToRoom;
		}
	
		public function sendMessage( text:String, target:String=null ):void
		{
			var message:TextMessage = new TextMessage( selfJID, text );
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(message) );
			else
				room.sendMessage( encodeObject(message) );
		}
		
		public function sendFullSessionState( diffID:int, diff:Object, target:String=null ):void
		{
			var message:FullSessionState = new FullSessionState(diffID, diff);
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(message) );
			else
				room.sendMessage(encodeObject(message) );
		}
		
		public function sendSessionStateDiff( diffID:int, diff:Object, target:String=null ):void
		{
			var message:SessionStateMessage = new SessionStateMessage(diffID, diff);
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(message) );
			else
				room.sendMessage(encodeObject(message) );
		}
		
		private function postMessageToUser( message:String ) :void
		{
//			if( this.username == "Host")
//				return;
			dispatchEvent(new CollaborationEvent(CollaborationEvent.TEXT, message));
		}
		
		private function updateUsersList():void
		{
			var s:String = '';
			var sorted:Array = room.toArray().sortOn( "displayName" ) as Array;
			for (var i:int = 0; i < sorted.length; i++)
				s += (sorted[i] as RoomOccupant).displayName + '\n';
						
			dispatchEvent(new CollaborationEvent(CollaborationEvent.USERS_LIST, s));
		}
			
		private function joinRoom(roomName:String):void
		{
			postMessageToUser( "joined room: " + roomToJoin + "\n" );
			_room = new Room(connection);
			
			room.nickname = username;
			postMessageToUser( "set alias to: " + room.nickname + "\n" );
			room.roomJID = new UnescapedJID(roomName + compName + '.' + serverName);
			
			//start logging
			stateLog = registerDisposableChild( this, new SessionStateLog( root ) );
			getCallbackCollection( stateLog ).addImmediateCallback( this, handleStateChange );
			
			room.addEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
			room.addEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
			room.addEventListener(RoomEvent.USER_JOIN, onUserJoin);
			room.addEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			room.join();
		}
				
		private function onLogin(e:LoginEvent):void
		{
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
				var i:int;
				// handle a message from a user
				var o:Object = decodeObject(e.data.body);
				//var room:String = e.data.from.node;
				var userAlias:String = e.data.from.resource;
				if (o is FullSessionState)
				{
					var fss:FullSessionState = o as FullSessionState;
					setSessionState( root, fss.state, true);
					//once you've downloaded the sessionState start logging 
					//is there a callback to make sure the sessionState has fully finished
					//downloading?
					connectedToRoom = true;
				}
				else if (o is SessionStateMessage)
				{
					var ssm:SessionStateMessage = o as SessionStateMessage;
					if( userAlias == this.username )
					{
						// received echo back from local state change
						// search history for diff with matching id
						var foundID:Boolean = false;
						for (i = 0; i < stateLog.undoHistory.length; i++)
						{
							if (stateLog.undoHistory[i].id == ssm.id)
							{
								foundID = true;
								break;
							}
						}
 						// remove everything up until the diff with the matching id
						if (foundID)
							stateLog.undoHistory.splice(0, i + 1);
						else
							ErrorManager.reportError(new Error("collab failed"));
					}
					else
					{
						// received diff from someone else -- rewind local changes and replay them.
						
						// rewind local changes
						for (i = stateLog.undoHistory.length - 1; i >= 0; i--)
							setSessionState(root, stateLog.undoHistory[i].backward, false);
						
						// apply remote change
						setSessionState(root, ssm.diff, false);
						
						// replay local changes
						for (i = 0; i < stateLog.undoHistory.length; i++)
							setSessionState(root, stateLog.undoHistory[i].forward, false);
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
			//== Reset variables ==//
			connectedToRoom = 			false;
			connectedToServer = 		false;
			connection = 				null;
			_room =						null;
			selfJID = 					null;	
		}
		
		private function onError(e:XIFFErrorEvent):void
		{
			//401 == Not Authorized to connect to server
			if( e.errorCode == 401 )
				dispatchEvent( new CollaborationEvent( CollaborationEvent.TEXT, "Not Authorized to connect to Server, please check IP and server name, and try again.\n" ) );
			
			dispatchEvent( new CollaborationEvent(CollaborationEvent.DISCONNECT, null) );
		}
		
		private function onRoomJoin(e:RoomEvent):void
		{
			//_room = Room(e.target);
			selfJID = room.userJID.resource;
			var userList:Array = room.toArray();
			updateUsersList();
		}
		
		private function onTimeout(e:RoomEvent):void
		{
			connectedToRoom = false;
			postMessageToUser( "You've timed out from the server.\n" );
			disconnect();
		}
		
		private function onUserJoin(e:RoomEvent):void
		{
			postMessageToUser( e.nickname + " has joined the room.\n" );
			updateUsersList();
		
			var userList:Array = room.toArray().sortOn( "displayName" );
	
			for( var i:int = 0; i < userList.length; i++)
				if(userList[i].displayName == e.nickname)
				{
					userList.splice(i,1);
					break;
				}
			
			if( userList.length == 0)
			{
				//no one else is in room, start logging
				connectedToRoom == true;
			}
			else if( username == userList[0].displayName )
			{
				var id:int = stateLog.undoHistory[ stateLog.undoHistory.length - 1];
				sendFullSessionState(id, getSessionState(root), e.nickname );
			} 
		}
		
		private function onUserLeave(e:RoomEvent):void
		{
			postMessageToUser( e.nickname + " has left the room.\n" );
			updateUsersList();
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

internal class FullSessionState
{
	public function FullSessionState( id:int = 0, state:Object = null)
	{
		this.id = id;
		this.state = state;
	}
	
	public var id:int;
	public var state:Object;
}

internal class SessionStateMessage
{
	public function SessionStateMessage(id:int = 0, diff:Object = null)
	{
		this.id = id;
		this.diff = diff;
	}
	
	public var id:int;
	public var diff:Object;
}

internal class TextMessage
{
	public function TextMessage(id:String = null, message:String = null)
	{
		this.id = id;
		this.message = message;
	}
	
	public var id:String;
	public var message:String;
}
