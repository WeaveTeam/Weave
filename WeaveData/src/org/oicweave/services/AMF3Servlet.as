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

package org.oicweave.services
{
	import mx.rpc.AsyncToken;
	
	import org.oicweave.utils.ByteArrayUtils;

	/**
	 * AMF3Servlet
	 * This is an extension of Servlet that deserializes AMF3 result objects and handles special cases where an ErrorMessage is returned.
	 * 
	 * @author adufilie
	 */	
	public class AMF3Servlet extends Servlet
	{
		/**
		 * @param servletURL The URL of the servlet (everything before the question mark in a URL request).
		 * @param methodParamName This is the name of the URL parameter that specifies the method to be called on the servlet.
		 */
		public function AMF3Servlet(servletURL:String)
		{
			// params get sent as a compressed AMF3-serialized object
			super(servletURL, "methodName", REQUEST_FORMAT_BINARY);
		}
		
		/**
		 * This function makes a remote procedure call.
		 * @param methodName The name of the method to call.
		 * @param methodParameters The parameters to use when calling the method.
		 * @return An AsyncToken generated for the call.
		 */
		override public function invokeAsyncMethod(methodName:String, methodParameters:Object = null):AsyncToken
		{
			//  if these parameters are coming from a DelayedAsyncInvocation object, call super.invokeAsyncMethod().
			if (methodParameters is DelayedParameters)
				return super.invokeAsyncMethod(methodName, (methodParameters as DelayedParameters).methodParameters);
			
			// create a wrapper object for these parameters to serve as a flag to say that they are coming from a DelayedAsyncInvocation object.
			methodParameters = new DelayedParameters(methodParameters);
			var token:DelayedAsyncInvocation = new DelayedAsyncInvocation(
					this, methodName, methodParameters, ByteArrayUtils.readCompressedObject, true
				);
			token.invoke();
			return token;
		}
	}
}
/**
 * This class is a wrapper for a parameters object and serves as a flag to say
 * that the parameters are being passed from a DelayedAsyncInvocation object.
 */
internal class DelayedParameters
{
	public function DelayedParameters(methodParameters:Object)
	{
		this.methodParameters = methodParameters;
	}
	
	public var methodParameters:Object;
}
