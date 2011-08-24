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

/*
	Whomeever this code gets passed onto, please feel free to delete or
	rewrite the comments I have written. They are only painfully obvious
	to facilitate the transferring of this code to the new maintainer.
	
	~Andrew Wilkinson
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
	import mx.collections.ArrayCollection;
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
	
	import weave.api.WeaveAPI;
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
		private var root:ILinkableObject;
		private var connection:XMPPConnection;
		private var selfJID:String;
		private var serverIP:String;
		private var serverName:String;
		private var port:int;
		private var roomToJoin:String;
		private var _room:Room;

		private var baseEncoder:Base64Encoder = new Base64Encoder();
		private var baseDecoder:Base64Decoder = new Base64Decoder();
		private var connectedToRoom:Boolean   = false;
		private var connectedToServer:Boolean = false;
		private var stateSet:Boolean  		  = false;
		private var stateLog:SessionStateLog  = null;
		
		public var userList:ArrayCollection  = new ArrayCollection();
		public var username:String;
		public var role:String;

		public function CollaborationService( root:ILinkableObject )
		{
			this.root = root;
			
			// register these classes so they will not lose their type when they get serialized and then deserialized.
			// all of these classes are internal
			for each (var c:Class in [FullSessionState, SessionStateMessage, TextMessage])
				registerClassAlias(getQualifiedClassName(c), c);
		}
		
		//This is here just to warn us in the many places that room is called, if it is null
		private function get room():Room
		{
			if( _room == null)
				throw new Error("Not Connected to Collaboration Server");
			return _room;
		}
		
		// this will be called by SessionManager to clean everything up
		public function dispose():void
		{
			if( isConnectedToRoom() == true) disconnect();
		}
		
		//If the Session state changes in anyway, a diff is created and stored in the
		//StateLog history. The latest entry is than sent to the server, to be sent
		//to everyone else to update their collaboration session.
		private function handleStateChange():void
		{
			// note: this code may need to be changed later if SessionStateLog implementation changes.
			if (isConnectedToRoom() && stateSet)
			{ 
				var log:Array 	 = stateLog.undoHistory;
				var entry:Object = log[log.length - 1];
				sendSessionStateDiff( entry.id, entry.forward );
			}
		}
		
		public function isConnectedToServer():Boolean 
		{
			return connectedToServer;
		}
		
		public function isConnectedToRoom():Boolean 
		{
			return connectedToRoom;
		}
		
		public function connect( serverIP:String, serverName:String, port:int, roomToJoin:String, username:String ):void
		{
			//if already connected disconnect and start over
			if (connectedToServer == true) disconnect();
			
			//These values all come from the tool as inputs
			this.serverIP = serverIP;
			this.serverName = serverName;
			this.port =	port;
			this.roomToJoin = roomToJoin;
			this.username = username;
			
			postMessageToUser("connecting to " + serverName + " at " + serverIP + ":" + port.toString() + " ...\n");
			connection = new XMPPConnection();
			
			//Use this for servers where a registered name is not required,
			//otherwise you can use the registered login below
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
			
			userList.removeAll();
			
			if( connection ) 
			{
				//Remove Event Listeners 
				connection.removeEventListener(LoginEvent.LOGIN, onLogin);
				connection.removeEventListener(XIFFErrorEvent.XIFF_ERROR, onError);
				connection.removeEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
				connection.removeEventListener(MessageEvent.MESSAGE, onReceiveMessage);
			}	
			if( _room != null)
			{
				room.removeEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
				room.removeEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
				room.removeEventListener(RoomEvent.USER_JOIN, onUserJoin);
				room.removeEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			}
			if( connection )
				connection.disconnect();
		}
		
		//Sends messages to the room on the server
		public function sendEncodedObject( message:Object, target:String ):void
		{
			//trace( ObjectUtil.toString( message ) , ObjectUtil.toString( target )  );
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(message) );
			else
				room.sendMessage( encodeObject(message) );
			
		}
		
		//Handles sending text messages
		public function sendTextMessage( text:String, target:String=null ):void
		{
			var message:TextMessage = new TextMessage( selfJID, text );
			sendEncodedObject( message, target );
		}
		
		//Handles Sending the entire session state. Should only be used if
		//someone needs a hard reset, or joining the collaboration server
		//for the first time.
		public function sendFullSessionState( diffID:int, diff:Object, target:String=null ):void
		{
			var message:FullSessionState = new FullSessionState(diffID, diff);
			sendEncodedObject( message, target );
		}
		
		//Handles sending session state changes
		public function sendSessionStateDiff( diffID:int, diff:Object, target:String=null ):void
		{
			var message:SessionStateMessage = new SessionStateMessage(diffID, diff);
			sendEncodedObject( message, target );
		}
		
		//When a message is recieved pass it on to the user
		private function postMessageToUser( message:String ) :void
		{
			dispatchEvent(new CollaborationEvent(CollaborationEvent.TEXT, message));
		}
		
		//Goes through the room user list, sorts it, and reports it back to the Tool
		private function updateUsersList():void
		{
			userList.removeAll();
			for( var i:int = 0; i < room.length; i++ )
				userList.addItem( { name: room[i].displayName, role: room[i].role } );
		}
		
		//After you connect to a server, onLogin will direct you here
		//to connect to a room that is defined in the XMPPConnection (connection).
		private function joinRoom(roomName:String):void
		{
			postMessageToUser( "joined room: " + roomToJoin + "\n" );
			_room = new Room(connection);
			
			//nickname will replace the random string generated for Anonnymous users
			//and can be used for private messages and most user to user functions
			room.nickname = username;
			postMessageToUser( "set alias to: " + room.nickname + "\n" );
			room.roomJID = new UnescapedJID(roomName + "@conference" + '.' + serverName);
			
			room.addEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
			room.addEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
			room.addEventListener(RoomEvent.USER_JOIN, onUserJoin);
			room.addEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			
			room.join();
		}
			
		
		//Call back for when you connect to a server. The implementation here
		// is you'll join the room specified in the config page of the tool.
		//Future versions could implement a browser for different collaboration
		//rooms on the same server, if that becomes neccessary.
		private function onLogin(e:LoginEvent):void
		{
			connectedToServer = true;
			var message:String = "";
			
			message += "connected as ";
			if( connection.useAnonymousLogin == true ) message += "anonymous user: ";
			message += connection.username + "\n";
			postMessageToUser( message );
			
			joinRoom(roomToJoin);
		}
		
		//Handles receiving all messages, including text, diffs, and full session states
		private function onReceiveMessage(e:MessageEvent):void
		{
			//if id is null, it implies that the message originated from the server, 
			//and not from a user
			if( e.data.id != null) 
			{
				var i:int;
				
				// handle a message from a user
				var o:Object;
				try
				{
					o = decodeObject(e.data.body);
				} catch( e:Error ) {
					trace( "Bad incoming message, ignoring..." );
					return;
				}
				//WeaveAPI.ErrorManager.reportError( new Error( ObjectUtil.toString( o )) );
				
				//var room:String = e.data.from.node;
				var userAlias:String = e.data.from.resource;
				
				//Full session state message
				if (o is FullSessionState)
				{
					var fss:FullSessionState = o as FullSessionState;
					setSessionState( root, fss.state, true);

					if( stateLog == null )
					{
						//start logging
						stateLog = registerDisposableChild( this, new SessionStateLog( root ) );
						getCallbackCollection( stateLog ).addImmediateCallback( this, handleStateChange );
					}
					stateSet = true;
				}
				
				//A session state diff
				else if (o is SessionStateMessage)
				{
					if( stateSet ) //don't do anything till the collaborative session state is loaded
					{
						var ssm:SessionStateMessage = o as SessionStateMessage;
						if( userAlias == this.username )
						{
							// received echo back from local state change
							// search history for diff with matching id
							var foundID:Boolean = false;
							if( stateLog )
							{
								for (i = 0; i < stateLog.undoHistory.length; i++)
								{
									if (stateLog.undoHistory[i].id == ssm.id)
									{
										foundID = true;
										break;
									}
								}
							}
	 						// remove everything up until the diff with the matching id
							if (foundID)
								stateLog.undoHistory.splice(0, i + 1);
							else
								WeaveAPI.ErrorManager.reportError(new Error("collab failed"));
						}
						
						// received diff from someone else -- rewind local changes and replay them.
						else
						{
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
				}
				
				//A text message from the text box
				else if (o is TextMessage)
				{
					var tm:TextMessage = o as TextMessage;
					postMessageToUser( tm.id + ": " + tm.message + "\n" );
				}
				
				//an unknown message with data, but wasn't one of the three pre-defineds 
				else
				{
					WeaveAPI.ErrorManager.reportError(new Error("Unable to determine message type: ", ObjectUtil.toString(o)));
				}
			}
			
			//A message from the server
			else
			{
				// messages from the server are always strings
				postMessageToUser( "server: " + e.data.body + "\n" );
			}
		}
		
		private function onDisconnect(e:DisconnectionEvent):void
		{
			//== Reset variables ==//
			connectedToRoom = 	false;
			connectedToServer = false;
			stateSet =			false;
			connection = 		null;
			_room =				null;
			selfJID = 			null;	
		}
		
		private function onError(e:XIFFErrorEvent):void
		{
			//401 == Not Authorized to connect to server
			//was a specific error I was running into
			if( e.errorCode == 401 )
				dispatchEvent( new CollaborationEvent( CollaborationEvent.TEXT, "Not Authorized to connect to Server, please check IP and server name, and try again.\n" ) );
			
			dispatchEvent( new CollaborationEvent(CollaborationEvent.DISCONNECT, null) );
		}
		
		//handles when this joins the room
		private function onRoomJoin(e:RoomEvent):void
		{
			selfJID = room.userJID.resource;
			role = room.role;
			var userList:Array = room.toArray();
			connectedToRoom = true;
			updateUsersList();
		}
		
		//Most servers have this enabled, where if you don't do anything for too long
		//it'll fire the timeout event
		private function onTimeout(e:RoomEvent):void
		{
			connectedToRoom = false;
			postMessageToUser( "You've timed out from the server.\n" );
			disconnect();
		}
		
		//handled whenever any user joins the same room as this
		private function onUserJoin(e:RoomEvent):void
		{
			postMessageToUser( e.nickname + " has joined the room.\n" );
			updateUsersList();
		
			//This whole sequence of steps is just to determine alphabetially
			//who's on the top of the list. It needs to be sorted, because order
			//of names in array is not guarenteed
			var userList:Array = room.toArray().sortOn( "displayName" );
	
			for( var i:int = 0; i < userList.length; i++)
				if(userList[i].displayName == e.nickname)
				{
					userList.splice(i,1);
					break;
				}

			//if no one else is in room, start logging
			if( userList.length == 0)
			{
				if( stateLog == null )
				{
					stateLog = registerDisposableChild( this, new SessionStateLog( root ) );
					getCallbackCollection( stateLog ).addImmediateCallback( this, handleStateChange );
				}
				stateSet = true;
			}
			//If you are the user at the top of the list than send session
			//state to the new user that joined.
			else if( username == userList[0].displayName )
			{
				var id:int = stateLog.undoHistory[ stateLog.undoHistory.length - 1];
				sendFullSessionState(id, getSessionState(root), e.nickname );
			} 
		}
		
		//Handled when any user leaves the room this is in
		private function onUserLeave(e:RoomEvent):void
		{
			postMessageToUser( e.nickname + " has left the room.\n" );
			updateUsersList();
		}
		
		//Used to convert data to binary
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
		
		//Used to decode data from binary back to it's original object
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

//Internal classes are used to define the different message types
//that will be sent over the server
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
