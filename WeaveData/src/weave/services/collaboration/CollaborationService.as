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
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.media.Sound;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.collections.Sort;
	import mx.containers.Canvas;
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.core.Application;
	import mx.events.CloseEvent;
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;
	import mx.utils.ObjectUtil;
	import mx.utils.StringUtil;
	
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
	import weave.api.reportError;
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
		private var username:String;
		private var password:String;

		private const baseEncoder:Base64Encoder 		= new Base64Encoder();
		private const baseDecoder:Base64Decoder 		= new Base64Decoder();
		private var connectedToRoom:Boolean 			= false;
		private var stateLog:SessionStateLog 			= null;
		private var synchronizingIncomingDiff:Boolean 	= false;
		
		public const userList:ArrayCollection 			= new ArrayCollection();
		public var nickname:String;
		public var myRole:String;
		public var room:Room;
		[Bindable] public var ping:Number;

		public function CollaborationService( root:ILinkableObject )
		{
			this.root = root;
			// register these classes so they will not lose their type when they get serialized and then deserialized.
			// all of these classes are internal
			for each (var c:Class in [FullSessionState, SessionStateMessage, TextMessage, MouseMessage, RequestMouseMessage, Ping, AddonsMessage])
				registerClassAlias(getQualifiedClassName(c), c);
				
			userList.sort = new Sort();
			userList.sort.compareFunction = ObjectUtil.stringCompare;
		}
		
		// this will be called by SessionManager to clean everything up
		public function dispose():void
		{
			if( connectedToRoom ) disconnect();
		}
		
		public function get isConnected():Boolean 
		{
			return connectedToRoom;
		}
		
		public function connect( serverIP:String, serverName:String, port:int, roomToJoin:String, nickname:String, username:String = null, password:String = null ):void
		{
			//if already connected disconnect and start over
			if (connectedToRoom)
				disconnect();
			
			//These values all come from the tool as inputs
			this.serverIP = serverIP;
			this.serverName = serverName;
			this.port =	port;
			this.roomToJoin = roomToJoin;
			this.nickname = nickname;
			this.username = username;
			this.password = password;
			
			dispatchLogEvent("Connecting to " + serverName + " at " + serverIP + ":" + port.toString() + " ...");
			connection = new XMPPConnection();
			
			//Use this for servers where a registered name is not required,
			//otherwise you can use the registered login below
			connection.useAnonymousLogin = true;

			if( !connection.useAnonymousLogin ) 
			{
				connection.username = username;
				connection.password = password;
			}
			
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
			if (!connectedToRoom)
			{
				reportError("disconnect(): Not connected");
				return;
			}
			
			stopLogging();
			
			connectedToRoom = false;
			
			dispatchLogEvent( "Disconnected from server" );
			
			userList.removeAll();
			
			if( connection ) 
			{
				//Remove Event Listeners 
				connection.removeEventListener(LoginEvent.LOGIN, onLogin);
				connection.removeEventListener(XIFFErrorEvent.XIFF_ERROR, onError);
				connection.removeEventListener(DisconnectionEvent.DISCONNECT, onDisconnect);
				connection.removeEventListener(MessageEvent.MESSAGE, onReceiveMessage);
			}	
			if( room != null)
			{
				room.removeEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
//				room.removeEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
				room.removeEventListener(RoomEvent.USER_JOIN, onUserJoin);
				room.removeEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			}
			if( connection )
				connection.disconnect();
			dispatchEvent( new CollaborationEvent(CollaborationEvent.DISCONNECT) );
		}
		
		//Sends messages to the room on the server
		private function sendEncodedObject( message:Object, target:String ):void
		{
			if (!connectedToRoom)
				throw new Error("Not connected");
			
			if( target != null)
				room.sendPrivateMessage( target, encodeObject(message) );
			else
				room.sendMessage( encodeObject(message) );
		}
		public function sendMouseMessage( id:String, color:uint, posX:Number, posY:Number ):void
		{
			var message:MouseMessage = new MouseMessage(id, color, posX, posY);
			sendEncodedObject(message, null);
		}
		public function requestMouseMessage( id:String ):void
		{
			var message:RequestMouseMessage = new RequestMouseMessage(nickname);
			sendEncodedObject(message, id);
		}
		//Handles sending text messages
		public function sendTextMessage( text:String, target:String=null ):void
		{
			var message:TextMessage = new TextMessage( selfJID, text );
			sendEncodedObject( message, target );
		}
		public function sendPing(id:String):void
		{
			var message:Ping = new Ping(id);
			sendEncodedObject(message, id);
		}
		public function sendAddonUpdate( id:String, type:String, toggle:Boolean ):void
		{
			var message:AddonsMessage = new AddonsMessage(id, type, toggle);
			sendEncodedObject(message, null);
		}
		//Handles Sending the entire session state. Should only be used if
		//someone needs a hard reset, or joining the collaboration server
		//for the first time.
		public function sendFullSessionState( diffID:int, diff:Object, target:String ):void
		{
			var message:FullSessionState = new FullSessionState(diffID, diff);
			sendEncodedObject( message, target );
		}
		
		//Handles sending session state changes
		public function sendSessionStateDiff( diffID:int, diff:Object ):void
		{
			//dispatchLogEvent('\nOUTGOING ' + diffID + ' ' + ObjectUtil.toString(diff) + '\n--------------------------\n');
			var message:SessionStateMessage = new SessionStateMessage(diffID, diff);
			sendEncodedObject(message, null);
		}
		
		//When a message is recieved pass it on to the user
		private function dispatchLogEvent( message:String ) :void
		{
			dispatchEvent(new CollaborationEvent(CollaborationEvent.LOG, message ));
		}
		
		//Goes through the room user list, sorts it, and reports it back to the Tool
		private function updateUsersList():void
		{
			userList.removeAll();
			if (room != null)
				for( var i:int = 0; i < room.length; i++ )
					userList.addItem( room[i].displayName );
			dispatchEvent(new Event(CollaborationEvent.USER_LIST_UPDATED));
		}
		
		//After you connect to a server, onLogin will direct you here
		//to connect to a room that is defined in the XMPPConnection (connection).
		private function joinRoom(roomName:String):void
		{
			dispatchLogEvent( "Joined room: " + roomToJoin );
			room = new Room(connection);
			
			//nickname will replace the random string generated for Anonnymous users
			//and can be used for private messages and most user to user functions
			room.nickname = nickname;
			dispatchLogEvent( "Set alias to: " + room.nickname );
			room.roomJID = new UnescapedJID(roomName + "@conference" + '.' + serverName);
			
			room.addEventListener(RoomEvent.ROOM_JOIN, onRoomJoin);
//			room.addEventListener(RoomEvent.ROOM_LEAVE, onTimeout);
			room.addEventListener(RoomEvent.USER_JOIN, onUserJoin);
			room.addEventListener(RoomEvent.USER_DEPARTURE, onUserLeave);
			room.addEventListener(RoomEvent.NICK_CONFLICT, nickConflictError);
			room.addEventListener(RoomEvent.LOCKED_ERROR, handleLockedError);
			
			room.join();
			
		}
		
		private function startLogging():void
		{
			if (stateLog == null)
			{
				stateLog = registerDisposableChild( this, new SessionStateLog( root ) );
				getCallbackCollection( stateLog ).addImmediateCallback( this, handleStateChange );
			}
		}
		private function stopLogging():void
		{
			if (stateLog)
			{
				disposeObjects(stateLog);
				stateLog = null;
			}
		}
		//If the Session state changes in anyway, a diff is created and stored in the
		//StateLog history. The latest entry is than sent to the server, to be sent
		//to everyone else to update their collaboration session.
		private function handleStateChange():void
		{
			// note: this code may need to be changed later if SessionStateLog implementation changes.
			if (connectedToRoom && stateLog != null)
			{
				var log:Array = stateLog.undoHistory;
				if (synchronizingIncomingDiff)
				{
					log.pop(); // suppress the outgoing diff that results from an incoming diff
				}
				else if (log.length > 0)
				{
					var entry:Object = log[log.length - 1];
					sendSessionStateDiff( entry.id, entry.forward );
				}
			}
		}
		
		//Call back for when you connect to a server. The implementation here
		// is you'll join the room specified in the config page of the tool.
		//Future versions could implement a browser for different collaboration
		//rooms on the same server, if that becomes neccessary.
		private function onLogin(e:LoginEvent):void
		{
			var message:String = "";
			
			message += "Connected as ";
			if( connection.useAnonymousLogin == true )
				message += "anonymous user: ";
			message += connection.username;
			dispatchLogEvent( message );
			
			joinRoom(roomToJoin);
		}
		
		//Handles receiving all messages, including text, diffs, and full session states
		private function onReceiveMessage(event:MessageEvent):void
		{
			//if id is null, it implies that the message originated from the server, 
			//and not from a user
			if( event.data.id != null) 
			{
				var i:int;
				
				// handle a message from a user
				var o:Object = null;
				
				try
				{
					o = decodeObject(event.data.body);
				}
				catch( e:Error )
				{
					reportError("Unable to decode message: " + event.data.body);
				}
				
				//reportError( ObjectUtil.toString( o ) );
				
				//var room:String = event.data.from.node;
				var userAlias:String = event.data.from.resource;
				
				//Full session state message
				if (o is FullSessionState)
				{
					var fss:FullSessionState = o as FullSessionState;
					setSessionState(root, fss.state, true);
					startLogging();
				}
				
				//A session state diff
				else if (o is SessionStateMessage)
				{
					if (stateLog != null) //don't do anything until the collaborative session state is loaded
					{
						var ssm:SessionStateMessage = o as SessionStateMessage;
						if (userAlias == this.nickname)
						{
							//dispatchLogEvent('\nECHO ' + ssm.id + '\n--------------------------\n');
							
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
								reportError("collab failed");
						}
						
						// received diff from someone else -- rewind local changes and replay them.
						else
						{
							// apply any pending changes now
							stateLog.synchronizeNow();
							
							// rewind local changes
							for (i = stateLog.undoHistory.length - 1; i >= 0; i--)
								setSessionState(root, stateLog.undoHistory[i].backward, false);
							
							//dispatchLogEvent('\nINCOMING ' + userAlias + '.' + ssm.id + ' ' + ObjectUtil.toString(ssm.diff) + '\n--------------------------\n');
							
							// apply remote change
							setSessionState(root, ssm.diff, false);
							
							// replay local changes
							for (i = 0; i < stateLog.undoHistory.length; i++)
								setSessionState(root, stateLog.undoHistory[i].forward, false);
							
							// this will compute the diff and trigger handleStateChange()
							synchronizingIncomingDiff = true;
							stateLog.synchronizeNow();
							synchronizingIncomingDiff = false;
						}
					}
				}
				
				//A text message from the text box
				else if ( o is TextMessage)
				{
					var tm:TextMessage = o as TextMessage;
					dispatchLogEvent( tm.id + ": " + tm.message);
				}
					
				else if( o is RequestMouseMessage )
				{
					var rmm:RequestMouseMessage = o as RequestMouseMessage;
					if( rmm.id != nickname ) 
						dispatchEvent(new CollaborationEvent(CollaborationEvent.USER_REQUEST_MOUSE_POS, rmm.id, 0, xMousePercent(), yMousePercent()));
				}
				else if( o is MouseMessage )
				{
					var mm:MouseMessage = o as MouseMessage;
					if( mm.id != nickname )
						dispatchEvent(new CollaborationEvent(CollaborationEvent.USER_UPDATE_MOUSE_POS, mm.id, mm.color, mm.percentX, mm.percentY));
				}
				else if( o is Ping )
				{
					var p:Ping = o as Ping;
					ping = (new Date().getMilliseconds() - p.time);
					if( ping < 0 )
						ping = 500;
					dispatchEvent(new Event(CollaborationEvent.UPDATE_PING));
				}
				else if( o is AddonsMessage )
				{
					var am:AddonsMessage = o as AddonsMessage;
					if( am.type == "MIC" )
						dispatchEvent(new CollaborationEvent(CollaborationEvent.UPDATE_MIC, am.id, ( am.toggle ) ? 1 : 0));
					else if( am.type == "CAM" )
						dispatchEvent(new CollaborationEvent(CollaborationEvent.UPDATE_CAM, am.id, ( am.toggle ) ? 1 : 0));
				}
				//an unknown message with data, but wasn't one of the pre-defined types
				else
				{
//					reportError("Unable to determine message type: ", ObjectUtil.toString(o));
					trace(nickname,"Unknown type");
				}
			}
			
			//A message from the server
			else
			{
				// messages from the server are always strings
				dispatchLogEvent("server: " + event.data.body);
			}
		}
		
		private function onDisconnect(e:DisconnectionEvent):void
		{
			//== Reset variables ==//
			connectedToRoom = false;
			stopLogging();
			connection = null;
			room = null;
			selfJID = null;
			
			dispatchEvent(new CollaborationEvent(CollaborationEvent.DISCONNECT));
		}
		
		private function onError(e:XIFFErrorEvent):void
		{
			//401 == Not Authorized to connect to server
			if (e.errorCode == 401)
				dispatchLogEvent("Not Authorized to connect to Server, please check IP and server name, and try again.");
			
			// disconnect on error
			if (connectedToRoom)
				disconnect();
		}
		
		//handles when this joins the room
		private function onRoomJoin(e:RoomEvent):void
		{
			// here we assume room != null
			selfJID = room.userJID.resource;
			myRole = room.role;
			connectedToRoom = true;
			updateUsersList();
			dispatchEvent(new CollaborationEvent(CollaborationEvent.CONNECT));
		}
		
		private function xMousePercent():Number { return Application.application.stage.mouseX / Application.application.stage.stageWidth;  }
		private function yMousePercent():Number { return Application.application.stage.mouseY / Application.application.stage.stageHeight; }

		//Most servers have this enabled, where if you don't do anything for too long
		//it'll fire the timeout event
		private function onTimeout(e:RoomEvent):void
		{
			dispatchLogEvent("You've timed out from the server.");
			Alert.show("Would you like to reconnect to the room?", "Disconnection Alert", Alert.YES | Alert.NO, null, disconnectHandler);
		}
		
		private function disconnectHandler( e:CloseEvent ):void
		{
			if (e.detail == Alert.YES)
				connect(serverIP, serverName, port, roomToJoin, nickname);
		}
		//handled whenever any user joins the same room as this
		private function onUserJoin(e:RoomEvent):void
		{
			dispatchLogEvent(e.nickname + " has joined the room.");
			updateUsersList();
			
			//This whole sequence of steps is just to determine alphabetially
			//who's on the top of the list. It needs to be sorted, because order
			//of names in array is not guarenteed
			var userList:Array = room.toArray().sortOn("displayName");
	
			// remove the user that is currently joining from the list
			for (var i:int = 0; i < userList.length; i++)
			{
				if (userList[i].displayName == e.nickname)
				{
					userList.splice(i,1);
					break;
				}
			}

			if (userList.length == 0) // if we are the only user here
			{
				startLogging();
			}
			else if (nickname == userList[0].displayName) // if we are at the top of the list
			{
				// send full session state to the user who just joined.
				var debugID:int = stateLog.undoHistory[ stateLog.undoHistory.length - 1];
				sendFullSessionState(debugID, getSessionState(root), e.nickname );
			} 
			if( connectedToRoom )
				dispatchEvent(new CollaborationEvent(CollaborationEvent.USER_JOINED_CREATE_MOUSE, e.nickname));
		}
		//Handled when any user leaves the room this is in
		private function onUserLeave(e:RoomEvent):void
		{
			dispatchLogEvent(e.nickname + " has left the room.");
			dispatchEvent(new CollaborationEvent(CollaborationEvent.USER_LEFT_REMOVE_MOUSE, e.nickname));
			updateUsersList();
		}
		private function nickConflictError(e:RoomEvent):void
		{
			dispatchEvent(new CollaborationEvent(CollaborationEvent.NICK_ERROR));
			dispatchLogEvent("The nickname already exists! Please choose another.");
		}
		private function handleLockedError(e:RoomEvent):void
		{
			dispatchEvent(new CollaborationEvent(CollaborationEvent.LOCKED_ERROR));
			dispatchLogEvent(StringUtil.substitute("Error {0}: {1}", e.errorCode, e.errorMessage));
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
	public function FullSessionState(debugID:int = 0, state:Object = null)
	{
		this.debugID = debugID;
		this.state = state;
	}
	
	public var debugID:int;
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
internal class MouseMessage
{
	public function MouseMessage(id:String = null, color:uint = 0, posX:Number = 0, posY:Number = 0 )
	{
		this.id = id;
		this.color = color;
		this.percentX = posX;
		this.percentY = posY;
	}
	
	public var id:String;
	public var color:uint;
	public var percentX:Number;
	public var percentY:Number;
}
internal class RequestMouseMessage
{
	public function RequestMouseMessage(id:String = null)
	{
		this.id = id;
	}
	
	public var id:String;
}
internal class Ping
{
	public function Ping(id:String = null)
	{
		this.id = id;
		this.time = new Date().getMilliseconds();
	}
	
	public var id:String;
	public var time:Number;
}
internal class AddonsMessage
{
	public function AddonsMessage(id:String = null, type:String = null, toggle:Boolean = false)
	{
		this.id = id;
		this.type = type;
		this.toggle = toggle;
	}
	public var id:String;
	public var type:String;
	public var toggle:Boolean;
}