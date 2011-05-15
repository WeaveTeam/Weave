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

package org.oicweave.utils
{
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import mx.utils.Base64Decoder;
	import mx.utils.Base64Encoder;

	/**
	 * ByteArrayUtils
	 * This class contains static functions used for reading binary arrays.
	 * 
	 * @author adufilie
	 */	
	public class ByteArrayUtils
	{
		/**
		 * staticDecoder, staticEncoder, tempByteArray
		 * These objects are only used for temporary results.
		 */
		private static const staticDecoder:Base64Decoder = new Base64Decoder();
		private static const staticEncoder:Base64Encoder = new Base64Encoder();
		private static const tempByteArray:ByteArray = new ByteArray();

		/**
		 * Base64 Array decoding functions:
		 * 
		 * Each of these functions decodes a Base64 string into a ByteArray and
		 * then reads the resulting binary array into an Array object.
		 */
		// convert base64 string to ByteArray and extract the individual values into an Array
		public static function decodeStringArray(encodedString:String):Array
		{
			try {
				staticDecoder.reset();
				staticDecoder.decode(encodedString);
				return deserializeStringArray(staticDecoder.toByteArray());
			} catch (e:Error) { trace(e); }
			return [];
		}
		public static function decodeIntArray(encodedString:String):Array
		{
			try {
				staticDecoder.reset();
				staticDecoder.decode(encodedString);
				return deserializeIntArray(staticDecoder.toByteArray());
			} catch (e:Error) { trace(e); }
			return [];
		}
		public static function decodeFloatArray(encodedString:String):Array
		{
			try {
				staticDecoder.reset();
				staticDecoder.decode(encodedString);
				return deserializeFloatArray(staticDecoder.toByteArray());
			} catch (e:Error) { trace(e); }
			return [];
		}
		public static function decodeDoubleArray(encodedString:String):Array
		{
			try {
				staticDecoder.reset();
				staticDecoder.decode(encodedString);
				return deserializeDoubleArray(staticDecoder.toByteArray());
			} catch (e:Error) { trace(e); }
			return [];
		}

		/**
		 * Base64 Array encoding functions:
		 * 
		 * Each of these functions converts an Array into a ByteArray
		 * and then encodes the result into a Base64 String.
		 */
		// convert base64 string to ByteArray and extract the individual values into an Array
		public static function encodeStringArray(array:Array):String
		{
			tempByteArray.clear();
			staticEncoder.reset();
			staticEncoder.insertNewLines = false;
			staticEncoder.encodeBytes(serializeStringArray(array, tempByteArray));
			return staticEncoder.toString();
		}
		public static function encodeIntArray(array:Array):String
		{
			tempByteArray.clear();
			staticEncoder.reset();
			staticEncoder.insertNewLines = false;
			staticEncoder.encodeBytes(serializeIntArray(array, tempByteArray));
			return staticEncoder.toString();
		}
		public static function encodeFloatArray(array:Array):String
		{
			tempByteArray.clear();
			staticEncoder.reset();
			staticEncoder.insertNewLines = false;
			staticEncoder.encodeBytes(serializeFloatArray(array, tempByteArray));
			return staticEncoder.toString();
		}
		public static function encodeDoubleArray(array:Array):String
		{
			tempByteArray.clear();
			staticEncoder.reset();
			staticEncoder.insertNewLines = false;
			staticEncoder.encodeBytes(serializeDoubleArray(array, tempByteArray));
			return staticEncoder.toString();
		}

		/**
		 * Binary Array reading functions:
		 * 
		 * Each of these functions reads a binary array of numbers into an Array.
		 */
		public static function deserializeStringArray(byteArray:ByteArray):Array
		{
			var length:int = byteArray.length;
			var array:Array = new Array();
			var buffer:ByteArray = new ByteArray();
			var byte:int;
			for (var i:int = 0; i < length; i++)
			{
				byte = byteArray.readByte();
				if (byte == 0) // if \0 char is found (end of string)
				{
					array.push(buffer.toString()); // copy the string
					buffer.clear(); // reset the buffer
				}
				else
					buffer.writeByte(byte); // copy the byte to the string buffer
			}
            return array;
		}
		public static function deserializeIntArray(byteArray:ByteArray):Array
		{
			var length:int = Math.floor(byteArray.length / 4); // int is 4 bytes
			var array:Array = new Array(length);
			for (var i:int = 0; i < length; i++)
				array[i] = byteArray.readInt();
            return array;
		}
		public static function deserializeFloatArray(byteArray:ByteArray):Array
		{
			var length:int = Math.floor(byteArray.length / 4); // float is 4 bytes
			var array:Array = new Array(length);
			for (var i:int = 0; i < length; i++)
				array[i] = byteArray.readFloat();
            return array;
		}
		public static function deserializeDoubleArray(byteArray:ByteArray):Array
		{
			var length:int = Math.floor(byteArray.length / 8); // double is 8 bytes
			var array:Array = new Array(length);
			for (var i:int = 0; i < length; i++)
				array[i] = byteArray.readDouble();
            return array;
		}

		/**
		 * Binary Array generating functions:
		 * 
		 * Each of these functions copies an Array into a binary array of numbers.
		 */
		public static function serializeStringArray(array:Array, existingOutputByteArray:ByteArray = null):ByteArray
		{
			var output:ByteArray = existingOutputByteArray;
			if (output == null)
				output = new ByteArray();
			var str:String;
			var i:int, j:int, iEnd:int, jEnd:int;
			for (i = 0, iEnd = array.length; i < iEnd; i++)
			{
				str = array[i];
				for (j = 0, jEnd = str.length; j < jEnd; j++)
					output.writeByte(str.charCodeAt(j));
				output.writeByte(0);
			}
            return output;
		}
		public static function serializeIntArray(array:Array, existingOutputByteArray:ByteArray = null):ByteArray
		{
			var output:ByteArray = existingOutputByteArray;
			if (output == null)
				output = new ByteArray();
			var length:int = array.length;
			for (var i:int = 0; i < length; i++)
				output.writeInt(array[i]); // 4-byte int
            return output;
		}
		public static function serializeFloatArray(array:Array, existingOutputByteArray:ByteArray = null):ByteArray
		{
			var output:ByteArray = existingOutputByteArray;
			if (output == null)
				output = new ByteArray();
			var length:int = array.length;
			for (var i:int = 0; i < length; i++)
				output.writeFloat(array[i]); // 4-byte float
            return output;
		}
		public static function serializeDoubleArray(array:Array, existingOutputByteArray:ByteArray = null):ByteArray
		{
			var output:ByteArray = existingOutputByteArray;
			if (output == null)
				output = new ByteArray();
			var length:int = array.length;
			for (var i:int = 0; i < length; i++)
				output.writeDouble(array[i]); // 8-byte double
            return output;
		}
		
		/**
		 * This function reads an object that has been AMF3-serialized into a ByteArray.
		 * @param serializedObject The ByteArray that contains the AMF3 serialization of an object.
		 * @return The result of calling serializedObject.readObject(), or null if the deserialization fails.
		 */
		public static function readObject(serializedObject:ByteArray):Object
		{
			try
			{
				return serializedObject.readObject();
			}
			catch (e:Error)
			{
				// deserialization failed
			}
			return null;
		}

		/**
		 * This function reads an object that has been AMF3-serialized into a ByteArray and compressed.
		 * @param compressedSerializedObject The ByteArray that contains the compressed AMF3 serialization of an object.
		 * @return The result of calling uncompress() and readObject() on the ByteArray, or null if an error occurs.
		 */
		public static function readCompressedObject(compressedSerializedObject:ByteArray):Object
		{
			try
			{
//				var packed:int = compressedSerializedObject.bytesAvailable;
//				var time:int = getTimer();
				
				compressedSerializedObject.uncompress();
				
//				var unpacked:int = compressedSerializedObject.bytesAvailable;
//				trace(packed,'/',unpacked,'=',Math.round(packed/unpacked*100) + '%',getTimer()-time,'ms');
				
				return compressedSerializedObject.readObject();
			}
			catch (e:Error)
			{
				// decompression/deserialization failed
				//trace(e.getStackTrace());
			}
			return null;
		}
	}
}
