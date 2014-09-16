package weave.services.collaboration
{
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.core.EscapedJID;
	import org.igniterealtime.xiff.core.UnescapedJID;
	import org.igniterealtime.xiff.data.ExtensionClassRegistry;
	import org.igniterealtime.xiff.data.ISerializable;
	import org.igniterealtime.xiff.data.XMPPStanza;
	import org.igniterealtime.xiff.data.muc.MUCUserExtension;
	import org.igniterealtime.xiff.data.xhtml.XHTMLExtension;
	
	public class WeaveMessage extends XMPPStanza implements ISerializable
	{
		//Static variables for type strings.
		public static var FULL_SESSION_STATE:String = "fullsessionstate";
		public static var SESSION_STATE_MESSAGE:String = "sessionstatemessage";
		public static var REQUEST_MOUSE_MESSAGE:String = "requestmousemessage";
		public static var MOUSE_MESSAGE:String = "mousemessage";
		public static var PING:String = "ping";
		public static var ADDONS_MESSAGE:String = "addonsmessage";
		public static var ADDON_STATUS:String = "addonstatus";
		
		// Private references to nodes within our XML
		private var myContentNode:XMLNode;
		private var myTimeStampNode:XMLNode;
		
		private static var isMessageStaticCalled:Boolean = MessageStaticConstructor();	
		private static var staticConstructorDependency:Array = [ XMPPStanza, XHTMLExtension, ExtensionClassRegistry ];
		
		public function WeaveMessage( recipient:EscapedJID=null, msgID:String=null, msgContent:String=null, msgType:String=null )	
		{
			// Flash gives a warning if superconstructor is not first, hence the inline id check
			var msgId:String = exists( msgID ) ? msgID : generateID("m_");
			super( recipient, null, msgType, msgId, "message" );
			content = msgContent;
		}
		
		public static function MessageStaticConstructor():Boolean
		{
			XHTMLExtension.enable();
			return true;
		}
		
		/**
		 * Serializes the Message into XML form for sending to a server.
		 *
		 * @return An indication as to whether serialization was successful
		 */
		override public function serialize( parentNode:XMLNode ):Boolean	
		{
			return super.serialize( parentNode );	
		}
		
		/**
		 * Deserializes an XML object and populates the Message instance with its data.
		 *
		 * @param xmlNode The XML to deserialize
		 * @return An indication as to whether deserialization was sucessful
		 */
		override public function deserialize( xmlNode:XMLNode ):Boolean	
		{		
			var isSerialized:Boolean = super.deserialize( xmlNode );
			
			if (isSerialized) {
				var children:Array = xmlNode.childNodes;
				for( var i:String in children )	
				{
					switch( children[i].nodeName )	
					{
						// Adding error handler for 404 sent back by server
						case "error":
							break;
						case "content":
							myContentNode = children[i];
							break;
						case "x":
							if(children[i].attributes.xmlns == "jabber:x:delay")
								myTimeStampNode = children[i];
							if(children[i].attributes.xmlns == MUCUserExtension.NS) {
								var mucUserExtension:MUCUserExtension = new MUCUserExtension(getNode());
								mucUserExtension.deserialize(children[i]);
								addExtension(mucUserExtension);	
							}
							break;	
					}	
				}	
			}
			return isSerialized;	
		}
		
		/**
		 * The message body in plain-text format. If a client cannot render HTML-formatted
		 * text, this text is typically used instead.
		 */
		public function get content():String	
		{
			if (!exists(myContentNode)){
				return null;	
			}
			var value: String = '';
			try	
			{
				value =  myContentNode.firstChild.nodeValue;                               	
			}
			catch (error:Error)	
			{
				trace (error.getStackTrace());	
			}
			return value;	
		}
		
		public function set content( contentText:String ):void	
		{
			myContentNode = replaceTextNode(getNode(), myContentNode, "content", contentText);	
		}
		
		public function set time( theTime:Date ):void	
		{		
		}
		
		public function get time():Date
		{
			if(myTimeStampNode == null) return null;
			
			var stamp:String = myTimeStampNode.attributes.stamp;
			
			var t:Date = new Date();
			//CCYYMMDDThh:mm:ss
			//20020910T23:41:07
			t.setUTCFullYear(stamp.slice(0, 4)); //2002
			t.setUTCMonth(Number(stamp.slice(4, 6)) - 1); //09 
			t.setUTCDate(stamp.slice(6, 8)); //10
			//T
			t.setUTCHours(stamp.slice(9, 11)); //23
			//:
			t.setUTCMinutes(stamp.slice(12, 14)); //41
			//:
			t.setUTCSeconds(stamp.slice(15, 17)); //07
			return t;	
		}
		
	}
}