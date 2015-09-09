/* ***** BEGIN LICENSE BLOCK *****
 *
 * This file is part of Weave.
 *
 * The Initial Developer of Weave is the Institute for Visualization
 * and Perception Research at the University of Massachusetts Lowell.
 * Portions created by the Initial Developer are Copyright (C) 2008-2015
 * the Initial Developer. All Rights Reserved.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this file,
 * You can obtain one at http://mozilla.org/MPL/2.0/.
 * 
 * ***** END LICENSE BLOCK ***** */

package weave.services
{
	import flash.utils.ByteArray;
	
	import mx.rpc.AsyncToken;
	
	import weave.compiler.Compiler;

	/**
	 * This is an extension of Servlet that deserializes AMF3 result objects and handles special cases where an ErrorMessage is returned.
	 * 
	 * @author adufilie
	 */	
	public class AMF3Servlet extends Servlet
	{
		public static var debug:Boolean = false;
		
		private var _invokeImmediately:Boolean = true;
		
		/**
		 * @param servletURL The URL of the servlet (everything before the question mark in a URL request).
		 * @param invokeImmediately Set this to false if you don't want the ProxyAsyncTokens created by invokeAsyncMethod() to be invoked automatically.
		 */
		public function AMF3Servlet(servletURL:String, invokeImmediately:Boolean = true)
		{
			// params get sent as an AMF3-serialized object
			super(servletURL, "method", REQUEST_FORMAT_BINARY);
			this._invokeImmediately = invokeImmediately;
		}
		
		/**
		 * This function makes a remote procedure call to a Weave AMF3 servlet.  As a special case, if
		 * methodParameters is an Array and the last item is a ByteArray, the bytes will be appended after
		 * the initial AMF3 serialization of the preceeding parameters to allow additional content that can
		 * be treated as a stream in Java.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return A ProxyAsyncToken that you can add responders to.
		 *         If the constructor parameter <code>invokeImmediately</code> was set to false,
		 *         you will have to manually call invoke() on the returned token.
		 */
		override public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			if (debug)
				trace('RPC', methodName, Compiler.stringify(methodParameters));
			
			var pt:ProxyAsyncToken = new ProxyAsyncToken(super.invokeAsyncMethod, arguments, readCompressedObject);
			if (_invokeImmediately)
				pt.invoke();
			return pt;
		}
		
		/**
		 * This function reads an object that has been AMF3-serialized into a ByteArray and compressed.
		 * @param compressedSerializedObject The ByteArray that contains the compressed AMF3 serialization of an object.
		 * @return The result of calling uncompress() and readObject() on the ByteArray, or null if the RPC returns void.
		 * @throws Error If unable to read the result.
		 */
		public static function readCompressedObject(compressedSerializedObject:ByteArray):Object
		{
			// length may be zero for void result
			if (compressedSerializedObject.length == 0)
				return null;
			
			//var packed:int = compressedSerializedObject.bytesAvailable;
			//var time:int = getTimer();
			
			compressedSerializedObject.uncompress();
			
			//var unpacked:int = compressedSerializedObject.bytesAvailable;
			//trace(packed,'/',unpacked,'=',Math.round(packed/unpacked*100) + '%',getTimer()-time,'ms');
			
			return compressedSerializedObject.readObject();
		}
	}
}
