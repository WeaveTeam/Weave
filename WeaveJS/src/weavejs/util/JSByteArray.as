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
		public static const ENCODING_AMF0:int = 0;
		public static const ENCODING_AMF3:int = 3;
		
		private static const Amf0Types_kNumberType:int        =  0;
		private static const Amf0Types_kBooleanType:int       =  1;
		private static const Amf0Types_kStringType:int        =  2;
		private static const Amf0Types_kObjectType:int        =  3;
		private static const Amf0Types_kMovieClipType:int     =  4;
		private static const Amf0Types_kNullType:int          =  5;
		private static const Amf0Types_kUndefinedType:int     =  6;
		private static const Amf0Types_kReferenceType:int     =  7;
		private static const Amf0Types_kECMAArrayType:int     =  8;
		private static const Amf0Types_kObjectEndType:int     =  9;
		private static const Amf0Types_kStrictArrayType:int   = 10;
		private static const Amf0Types_kDateType:int          = 11;
		private static const Amf0Types_kLongStringType:int    = 12;
		private static const Amf0Types_kUnsupportedType:int   = 13;
		private static const Amf0Types_kRecordsetType:int     = 14;
		private static const Amf0Types_kXMLObjectType:int     = 15;
		private static const Amf0Types_kTypedObjectType:int   = 16;
		private static const Amf0Types_kAvmPlusObjectType:int = 17;
		
		private static const Amf3Types_kUndefinedType:int  = 0;
		private static const Amf3Types_kNullType:int       = 1;
		private static const Amf3Types_kFalseType:int      = 2;
		private static const Amf3Types_kTrueType:int       = 3;
		private static const Amf3Types_kIntegerType:int    = 4;
		private static const Amf3Types_kDoubleType:int     = 5;
		private static const Amf3Types_kStringType:int     = 6;
		private static const Amf3Types_kXMLType:int        = 7;
		private static const Amf3Types_kDateType:int       = 8;
		private static const Amf3Types_kArrayType:int      = 9;
		private static const Amf3Types_kObjectType:int     = 10;
		private static const Amf3Types_kAvmPlusXmlType:int = 11;
		private static const Amf3Types_kByteArrayType:int  = 12;
		
		private static const TWOeN23:Number = Math.pow(2, -23);
		private static const TWOeN52:Number = Math.pow(2, -52);
		
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
	
			if (marker == Amf0Types_kNumberType)
			{
				return this.readDouble();
			}
			else if (marker == Amf0Types_kBooleanType)
			{
				return this.readBoolean();
			}
			else if (marker == Amf0Types_kStringType)
			{
				return this.readUTF();
			}
			else if ((marker == Amf0Types_kObjectType) || (marker == Amf0Types_kECMAArrayType))
			{
				o = {};
	
				var ismixed:Boolean = (marker == Amf0Types_kECMAArrayType);
	
				if (ismixed)
					this.readUInt30();
	
				while (true)
				{
					var c1:int = data[pos++] & 0xFF;
					var c2:int = data[pos++] & 0xFF;
					var name:String = this.readString((c1 << 8) | c2);
					var k:int = data[pos++] & 0xFF;
					if (k == Amf0Types_kObjectEndType)
						break;
	
					this.pos--;
	
					o[name] = this.readObject();
				}
	
				return o;
			}
			else if (marker == Amf0Types_kStrictArrayType)
			{
				var size:int = this.readInt();
	
				var a:Array = [];
	
				for (var i:int = 0; i < size; ++i)
				{
					a.push(this.readObject());
				}
	
				return a;
			}
			else if (marker == Amf0Types_kTypedObjectType)
			{
				o = {};
	
				var typeName:String = this.readUTF();
				
				var propertyName:String = this.readUTF();
				var type:int = data[pos++] & 0xFF;
				while (type != Amf0Types_kObjectEndType)
				{
					value = this.readObject();
					o[propertyName] = value;
	
					propertyName = this.readUTF();
					type = data[pos++] & 0xFF;
				}
	
				return o;
			}
			else if (marker == Amf0Types_kAvmPlusObjectType)
			{
				return this.readAMF3Object();
			}
			else if (marker == Amf0Types_kNullType)
			{
				return null;
			}
			else if (marker == Amf0Types_kUndefinedType)
			{
				return undefined;
			}
			else if (marker == Amf0Types_kReferenceType)
			{
				var refNum:int = this.readUnsignedShort();
	
				value = this.objectTable[refNum];
	
				return value;
			}
			else if (marker == Amf0Types_kDateType)
			{
				return this.readDate();
			}
			else if (marker == Amf0Types_kLongStringType)
			{
				return this.readLongUTF();
			}
			else if (marker == Amf0Types_kXMLObjectType)
			{
				return this.readXML();
			}
			return undefined;
		}
	
		private function readAMF3Object():Object
		{
			var marker:int = data[pos++] & 0xFF;
			var ref:int, len:int, i:int, value:Object;
	
			if (marker == Amf3Types_kUndefinedType)
			{
				return undefined;
			}
			else if (marker == Amf3Types_kNullType)
			{
				return null;
			}
			else if (marker == Amf3Types_kFalseType)
			{
				return false;
			}
			else if (marker == Amf3Types_kTrueType)
			{
				return true;
			}
			else if (marker == Amf3Types_kIntegerType)
			{
				return this.readUInt29();
			}
			else if (marker == Amf3Types_kDoubleType)
			{
				return this.readDouble();
			}
			else if (marker == Amf3Types_kStringType)
			{
				return this.readStringAMF3();
			}
			else if (marker == Amf3Types_kXMLType)
			{
				return this.readXML();
			}
			else if (marker == Amf3Types_kDateType)
			{
				ref = this.readUInt29();
	
				if ((ref & 1) == 0)
					return this.objectTable[(ref >> 1)];
	
				var d:Number = this.readDouble();
				value = new Date(d);
				this.objectTable.push(value);
	
				return value;
			}
			else if (marker == Amf3Types_kArrayType)
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
			else if (marker == Amf3Types_kObjectType)
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
			else if (marker == Amf3Types_kAvmPlusXmlType)
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
			else if (marker == Amf3Types_kByteArrayType)
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
