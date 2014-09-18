package weave.services.collaboration
{
	import flash.xml.XMLNode;
	
	import org.igniterealtime.xiff.data.Extension;
	import org.igniterealtime.xiff.data.ExtensionClassRegistry;
	import org.igniterealtime.xiff.data.IExtension;
	import org.igniterealtime.xiff.data.ISerializable;
	
	public class WeaveExtension extends Extension implements IExtension, ISerializable
	{
		
		public static var NS:String = "weave:message";
		public static var ELEMENT:String = "data";
		
		private var myContentNode:XMLNode;
		
		public function WeaveExtension(parent:XMLNode=null)
		{
			super(parent);
			
			getNode().attributes.xmlns = getNS();
			getNode().nodeName = getElementName();
			
		}
		
		public function getNS():String
		{
			return WeaveExtension.NS;
		}
		
		public function getElementName():String
		{
			return WeaveExtension.ELEMENT;
		}
		
		public function set content(data:String):void
		{
			myContentNode = replaceTextNode(getNode(), myContentNode, "content", data);
		}

		public function get content():String
		{
			return myContentNode.firstChild.nodeValue;
		}
		
		/**
		 * Performs the registration of this extension into the extension registry.  
		 */
		public static function enable():void	
		{
			ExtensionClassRegistry.register(WeaveExtension);	
		}
		
		public function serialize(parentNode:XMLNode):Boolean
		{
			var node:XMLNode = getNode();
			
			if (!exists(node.parentNode)) {
				parentNode.appendChild(node.cloneNode(true));	
			}
			
			return true;
		}
		
		public function deserialize(node:XMLNode):Boolean
		{
			setNode(node);
			
			var children:Array = getNode().childNodes;
			for( var i:String in children)
			{
				switch( children[i].nodeName )
				{
					case "content":
						myContentNode = children[i];
						break;
				}
			}
			return true;
		}
		
	}
}