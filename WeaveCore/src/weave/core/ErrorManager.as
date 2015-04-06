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

package weave.core
{
	import flash.events.ErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.system.Capabilities;
	
	import mx.events.DynamicEvent;
	import mx.rpc.Fault;
	import mx.rpc.events.FaultEvent;
	
	import weave.api.core.IErrorManager;
	import weave.api.getCallbackCollection;
	import weave.compiler.StandardLib;
	import weave.utils.DebugUtils;
	import weave.utils.fixErrorMessage;
	
	/**
	 * This class is a central location for reporting and detecting errors.
	 * The callbacks for this object get called when an error is reported.
	 * 
	 * @author adufilie
	 */
	public class ErrorManager implements IErrorManager
	{
		private var _errors:Array = [];
		
		/**
		 * This is the list of all previously reported errors.
		 */
		public function get errors():Array
		{
			return _errors;
		}
		
		/**
		 * This function is intended to be the global error reporting mechanism for Weave.
		 * @param error An Error or a String describing the error.
		 * @param faultMessage A message associated with the error, if any.  If specified, the error will be wrapped in a Fault object.
		 * @param faultCessage Content associated with the error, if any.  If specified, the error will be wrapped in a Fault object.
		 */
		public function reportError(error:Object, faultMessage:String = null, faultContent:Object = null):void
		{
			if (error is DynamicEvent && error.error)
				error = error.error;
			if (error is FaultEvent)
			{
				// pull out the fault from the event
				var faultEvent:FaultEvent = error as FaultEvent;
				if (!faultMessage && faultEvent.message)
					faultMessage = StandardLib.asString(faultEvent.message.body);
				error = faultEvent.fault;
			}
			if (error is ErrorEvent)
				error = (error as ErrorEvent).text;
			if (error is String)
				error = new Error(error);
			if (error != null && !(error is Error))
				faultContent = faultContent == null ? error : [error, faultContent];
			if (!(error is Error) || faultMessage || faultContent != null)
			{
				// wrap the error in a Fault object
				if (!faultMessage && error is Error)
				{
					fixErrorMessage(error as Error);
					faultMessage = StandardLib.asString((error as Error).message);
				}
				var fault:Fault = new Fault('Error', faultMessage);
				fault.content = faultContent;
				fault.rootCause = error;
				error = fault;
			}
			
			var _error:Error = error as Error;
			if (!_error)
				throw new Error("Assertion failed");
			
			fixErrorMessage(_error);
			
			if (Capabilities.isDebugger)
			{
				trace('\n' + _error.getStackTrace() + '\n');
				//enterDebugger();
			}
			
			errors.push(_error);
			getCallbackCollection(this).triggerCallbacks();
		}
		
		public static function errorToString(error:Error):String
		{
			if (error is Fault)
			{
				var f:Fault = error as Fault;
				var errorString:String = '';
				if (f.faultDetail && (f.faultCode == IOErrorEvent.IO_ERROR || f.faultCode == SecurityErrorEvent.SECURITY_ERROR))
				{
					errorString = f.faultDetail;
				}
				else
				{
					errorString = f.faultCode;
					if (f.faultString)
						errorString += ': ' + f.faultString;
					if (f.faultDetail)
						errorString += ': ' + f.faultDetail;
					if (errorString == 'Error')
						errorString = "Communication error";
				}
				errorString = StandardLib.replace(errorString, 'Error: Error:', 'Error:');
				
				return errorString;
			}
			else if (Capabilities.isDebugger)
			{
				// get partial stack trace
				return error.message + '\rStack trace: ' + DebugUtils.getCompactStackTrace(error).join('; ');
			}
			else
			{
				return error.toString();
			}
		}
	}
}
