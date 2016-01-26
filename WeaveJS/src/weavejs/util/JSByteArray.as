/*
amf.js - An AMF library in JavaScript (ported to ActionScript for Weave)

Copyright (c) 2010, James Ward - www.jamesward.com
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

   1. Redistributions of source code must retain the above copyright notice, this list of
      conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright notice, this list
      of conditions and the following disclaimer in the documentation and/or other materials
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY JAMES WARD ''AS IS'' AND ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMES WARD OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the
authors and should not be interpreted as representing official policies, either expressed
or implied, of James Ward.
*/
package weavejs.util
{
	public class JSByteArray
	{
		public const ENCODING_AMF0:int = 0;
		public const ENCODING_AMF3:int = 3;
		
		private const AMF0_Number:int        =  0;
		private const AMF0_Boolean:int       =  1;
		private const AMF0_String:int        =  2;
		private const AMF0_Object:int        =  3;
		private const AMF0_MovieClip:int     =  4;
		private const AMF0_Null:int          =  5;
		private const AMF0_Undefined:int     =  6;
		private const AMF0_Reference:int     =  7;
		private const AMF0_ECMAArray:int     =  8;
		private const AMF0_ObjectEnd:int     =  9;
		private const AMF0_StrictArray:int   = 10;
		private const AMF0_Date:int          = 11;
		private const AMF0_LongString:int    = 12;
		private const AMF0_Unsupported:int   = 13;
		private const AMF0_Recordset:int     = 14;
		private const AMF0_XMLObject:int     = 15;
		private const AMF0_TypedObject:int   = 16;
		private const AMF0_AvmPlusObject:int = 17;
		
		private const AMF3_Undefined:int  = 0;
		private const AMF3_Null:int       = 1;
		private const AMF3_False:int      = 2;
		private const AMF3_True:int       = 3;
		private const AMF3_Integer:int    = 4;
		private const AMF3_Double:int     = 5;
		private const AMF3_String:int     = 6;
		private const AMF3_XML:int        = 7;
		private const AMF3_Date:int       = 8;
		private const AMF3_Array:int      = 9;
		private const AMF3_Object:int     = 10;
		private const AMF3_AvmPlusXml:int = 11;
		private const AMF3_ByteArray:int  = 12;
		
		public var data:/*Uint8*/Array;
		public var dataView:Object; // DataView
		public var length:int = 0;
		public var pos:int = 0;
		public var littleEndian:Boolean = false;
		public var objectEncoding:int = ENCODING_AMF3;
		public var stringTable:Array = [];
		public var objectTable:Array = [];
		public var traitTable:Array = [];
		
		/**
		 * Attempt to imitate AS3's ByteArray as very high-performance javascript.
		 * I aliased the functions to have shorter names, like ReadUInt32 as well as ReadUnsignedInt.
		 * I used some code from http://fhtr.blogspot.com/2009/12/3d-models-and-parsing-binary-data-with.html
		 * to kick-start it, but I added optimizations and support both big and little endian.
		 * @param data A Uint8Array
		 */
		public function JSByteArray(data:/*Uint8*/Array, littleEndian:Boolean = false)
		{
			this.data = data as JS.Uint8Array || new JS.Uint8Array(data);
			this.dataView = new JS.DataView(this.data.buffer);
			this.littleEndian = littleEndian;
			this.length = this.data.length;
	
			this.stringTable = [];
			this.objectTable = [];
			this.traitTable = [];
		}
		
		public function readByte():int
		{
			return data[pos++] & 0xFF;
		}
	
		public function readBoolean():Boolean
		{
			return data[pos++] & 0xFF ? true : false;
		}
	
		private function readUInt30():int
		{
			if (littleEndian)
				return readUInt30LE();
			var ch1:int = data[pos++] & 0xFF;
			var ch2:int = data[pos++] & 0xFF;
			var ch3:int = data[pos++] & 0xFF;
			var ch4:int = data[pos++] & 0xFF;
	
			if (ch1 >= 64)
				return undefined;
	
			return ch4 | (ch3 << 8) | (ch2 << 16) | (ch1 << 24);
		}
	
		public function readUnsignedInt/*readUInt32*/():int
		{
			var value:Number = dataView.getUint32(pos, littleEndian);
			pos += 4;
			return value;
		}
		
		public function readInt/*readInt32*/():int
		{
			var value:Number = dataView.getInt32(pos, littleEndian);
			pos += 4;
			return value;
		}
	
		public function readUnsignedShort/*readUInt16*/():int
		{
			var value:Number = dataView.getUint16(pos, littleEndian);
			pos += 2;
			return value;
		}
		
		public function readShort/*readInt16*/():int
		{
			var value:Number = dataView.getInt16(pos, littleEndian);
			pos += 2;
			return value;
		}
	
		public function readFloat/*readFloat32*/():Number
		{
			var value:Number = dataView.getFloat32(pos, littleEndian);
			pos += 4;
			return value;
		}
	
		public function readDouble/*readFloat64*/():Number
		{
			var value:Number = dataView.getFloat64(pos, littleEndian);
			pos += 8;
			return value;
		}
	
		private function readUInt29():int
		{
			var value:int;
	
			// Each byte must be treated as unsigned
			var b:int = data[pos++] & 0xFF;
	
			if (b < 128)
				return b;
	
			value = (b & 0x7F) << 7;
			b = data[pos++] & 0xFF;
	
			if (b < 128)
				return (value | b);
	
			value = (value | (b & 0x7F)) << 7;
			b = data[pos++] & 0xFF;
	
			if (b < 128)
				return (value | b);
	
			value = (value | (b & 0x7F)) << 8;
			b = data[pos++] & 0xFF;
	
			return (value | b);
		}
	
		private function readUInt30LE():int
		{
			var ch1:int = data[pos++] & 0xFF;
			var ch2:int = data[pos++] & 0xFF;
			var ch3:int = data[pos++] & 0xFF;
			var ch4:int = data[pos++] & 0xFF;
	
			if (ch4 >= 64)
				return undefined;
	
			return ch1 | (ch2 << 8) | (ch3 << 16) | (ch4 << 24);
		}
	
		private function readDate():Date
		{
			var time_ms:Number = this.readDouble();
			var tz_min:int = this.readUnsignedShort();
			return new Date(time_ms + tz_min * 60 * 1000);
		}
	
		public function readString(len:int):String
		{
			var str:String = new StringView(data, "UTF-8", this.pos, len).toString();
			this.pos += len;
			return str;
		}
	
		public function readUTF():String
		{
			return this.readString(this.readUnsignedShort());
		}
	
		public function readLongUTF():String
		{
			return this.readString(this.readUInt30());
		}
	
		private function stringToXML(str):Object
		{
			var xmlDoc:Object;
	
			if (JS.global.DOMParser)
			{
				var parser:Object = new JS.global.DOMParser();
				xmlDoc = parser.parseFromString(str, "text/xml");
			}
			else // IE
			{
				xmlDoc = new JS.global.ActiveXObject("Microsoft.XMLDOM");
				xmlDoc.async = false;
				xmlDoc.loadXML(str);
			}
	
			return xmlDoc;
		}
	
		public function readXML():Object
		{
			var xml:String = this.readLongUTF();
	
			return this.stringToXML(xml);
		}
	
		private function readStringAMF3():String
		{
			var ref:int = this.readUInt29();
	
			if ((ref & 1) == 0) // This is a reference
				return this.stringTable[(ref >> 1)];
	
			var len:int = (ref >> 1);
	
			if (0 == len)
				return "";
	
			var str:String = this.readString(len);
	
			this.stringTable.push(str);
	
			return str;
		}
	
		private function readTraits(ref):Object
		{
			var traitInfo:Object = {};
			traitInfo.properties = [];
	
			if ((ref & 3) == 1)
				return this.traitTable[(ref >> 2)];
	
			traitInfo.externalizable = ((ref & 4) == 4);
	
			traitInfo.dynamic = ((ref & 8) == 8);
	
			traitInfo.count = (ref >> 4);
			traitInfo.className = this.readStringAMF3();
	
			this.traitTable.push(traitInfo);
	
			for (var i:int = 0; i < traitInfo.count; i++)
			{
				var propName:String = this.readStringAMF3();
				traitInfo.properties.push(propName);
			}
	
			return traitInfo;
		}
	
		private function readExternalizable(className):Object
		{
			return this.readObject();
		}
	
		public function readObject():Object
		{
			if (this.objectEncoding == ENCODING_AMF0)
			{
				return this.readAMF0Object();
			}
			else if (this.objectEncoding == ENCODING_AMF3)
			{
				return this.readAMF3Object();
			}
			return undefined;
		}
	
		private function readAMF0Object():Object
		{
			var marker:int = data[pos++] & 0xFF;
			var value:Object, o:Object;
	
			if (marker == AMF0_Number)
			{
				return this.readDouble();
			}
			else if (marker == AMF0_Boolean)
			{
				return this.readBoolean();
			}
			else if (marker == AMF0_String)
			{
				return this.readUTF();
			}
			else if ((marker == AMF0_Object) || (marker == AMF0_ECMAArray))
			{
				o = {};
	
				var ismixed:Boolean = (marker == AMF0_ECMAArray);
	
				if (ismixed)
					this.readUInt30();
	
				while (true)
				{
					var c1:int = data[pos++] & 0xFF;
					var c2:int = data[pos++] & 0xFF;
					var name:String = this.readString((c1 << 8) | c2);
					var k:int = data[pos++] & 0xFF;
					if (k == AMF0_ObjectEnd)
						break;
	
					this.pos--;
	
					o[name] = this.readObject();
				}
	
				return o;
			}
			else if (marker == AMF0_StrictArray)
			{
				var size:int = this.readInt();
	
				var a:Array = [];
	
				for (var i:int = 0; i < size; ++i)
				{
					a.push(this.readObject());
				}
	
				return a;
			}
			else if (marker == AMF0_TypedObject)
			{
				o = {};
	
				var typeName:String = this.readUTF();
				
				var propertyName:String = this.readUTF();
				var type:int = data[pos++] & 0xFF;
				while (type != AMF0_ObjectEnd)
				{
					value = this.readObject();
					o[propertyName] = value;
	
					propertyName = this.readUTF();
					type = data[pos++] & 0xFF;
				}
	
				return o;
			}
			else if (marker == AMF0_AvmPlusObject)
			{
				return this.readAMF3Object();
			}
			else if (marker == AMF0_Null)
			{
				return null;
			}
			else if (marker == AMF0_Undefined)
			{
				return undefined;
			}
			else if (marker == AMF0_Reference)
			{
				var refNum:int = this.readUnsignedShort();
	
				value = this.objectTable[refNum];
	
				return value;
			}
			else if (marker == AMF0_Date)
			{
				return this.readDate();
			}
			else if (marker == AMF0_LongString)
			{
				return this.readLongUTF();
			}
			else if (marker == AMF0_XMLObject)
			{
				return this.readXML();
			}
			return undefined;
		}
	
		private function readAMF3Object():Object
		{
			var marker:int = data[pos++] & 0xFF;
			var ref:int, len:int, i:int, value:Object;
	
			if (marker == AMF3_Undefined)
			{
				return undefined;
			}
			else if (marker == AMF3_Null)
			{
				return null;
			}
			else if (marker == AMF3_False)
			{
				return false;
			}
			else if (marker == AMF3_True)
			{
				return true;
			}
			else if (marker == AMF3_Integer)
			{
				return this.readUInt29();
			}
			else if (marker == AMF3_Double)
			{
				return this.readDouble();
			}
			else if (marker == AMF3_String)
			{
				return this.readStringAMF3();
			}
			else if (marker == AMF3_XML)
			{
				return this.readXML();
			}
			else if (marker == AMF3_Date)
			{
				ref = this.readUInt29();
	
				if ((ref & 1) == 0)
					return this.objectTable[(ref >> 1)];
	
				var d:Number = this.readDouble();
				value = new Date(d);
				this.objectTable.push(value);
	
				return value;
			}
			else if (marker == AMF3_Array)
			{
				ref = this.readUInt29();
	
				if ((ref & 1) == 0)
					return this.objectTable[(ref >> 1)];
	
				len = (ref >> 1);
	
				var key:String = this.readStringAMF3();
	
				if (key == "")
				{
					var a:Array = [];
	
					for (i = 0; i < len; i++)
					{
						value = this.readObject();
	
						a.push(value);
					}
	
					return a;
				}
	
				// mixed array
				var result:Object = {};
	
				while (key != "")
				{
					result[key] = this.readObject();
					key = this.readStringAMF3();
				}
	
				for (i = 0; i < len; i++)
				{
					result[i] = this.readObject();
				}
	
				return result;
			}
			else if (marker == AMF3_Object)
			{
				var o:Object = {};
	
				this.objectTable.push(o);
	
				ref = this.readUInt29();
	
				if ((ref & 1) == 0)
					return this.objectTable[(ref >> 1)];
	
				var ti:Object = this.readTraits(ref);
				var className:String = ti.className;
				var externalizable:Boolean = ti.externalizable;
	
				if (externalizable)
				{
					o = this.readExternalizable(className);
				}
				else
				{
					len = ti.properties.length;
	
					for (i = 0; i < len; i++)
					{
						var propName:String = ti.properties[i];
	
						value = this.readObject();
	
						o[propName] = value;
					}
	
					if (ti.dynamic)
					{
						for (; ;)
						{
							var name:String = this.readStringAMF3();
							if (name == null || name.length == 0) break;
	
							value = this.readObject();
							o[name] = value;
						}
					}
				}
	
				return o;
			}
			else if (marker == AMF3_AvmPlusXml)
			{
				ref = this.readUInt29();
	
				if ((ref & 1) == 0)
					return this.stringToXML(this.objectTable[(ref >> 1)]);
	
				len = (ref >> 1);
	
				if (0 == len)
					return null;
	
	
				var str:String = this.readString(len);
	
				var xml:Object = this.stringToXML(str);
	
				this.objectTable.push(xml);
	
				return xml;
			}
			else if (marker == AMF3_ByteArray)
			{
				ref = this.readUInt29();
				if ((ref & 1) == 0)
					return this.objectTable[(ref >> 1)];
	
				len = (ref >> 1);
				
				var ba:JSByteArray = new JSByteArray(data.subarray(this.pos, this.pos += len));
				
				this.objectTable.push(ba);
				
				return ba;
			}
			
			return undefined;
		}
	}
}
