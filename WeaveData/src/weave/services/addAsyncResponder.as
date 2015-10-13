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
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import weave.core.ProgressIndicator;

	/**
	 * This is shorthand for adding an AsyncResponder to an AsyncToken.
	 * @param destination The AsyncToken to add a responder to.
	 * @param result function(event:ResultEvent, token:Object = null):void
	 * @param fault function(event:FaultEvent, token:Object = null):void
	 * @param token Passed as a parameter to the result or fault function.
	 * 
	 * @author adufilie
	 */
	public function addAsyncResponder(destination:AsyncToken, result:Function, fault:Function = null, token:Object = null):void
	{
		if (result == null)
			result = noOp;
		if (fault == null)
			fault = noOp;
		
		//DelayedAsyncResponder.addResponder(destination, result, fault, token);
		
		var Responder:Class = ProgressIndicator.debug ? DebugAsyncResponder : AsyncResponder;
		destination.addResponder(new Responder(result, fault, token) as IResponder);
	}
}

import flash.system.Capabilities;

import mx.rpc.AsyncResponder;

import weave.utils.DebugUtils;

internal function noOp(..._):void { }

internal class DebugAsyncResponder extends AsyncResponder
{
	public var data:Object;
	public var token:Object;
	public var stackTrace_constructor:String;
	public var stackTrace_result:String;
	public var stackTrace_fault:String;
	
	public function DebugAsyncResponder(result:Function, fault:Function, token:Object = null)
	{
		super(result, fault, token);
		
		this.token = token;
		stackTrace_constructor = getStackTrace('constructor');
	}
	
	override public function result(data:Object):void
	{
		this.data = data;
		stackTrace_result = getStackTrace('result');
		super.result(data);
	}
	
	override public function fault(data:Object):void
	{
		this.data = data;
		stackTrace_result = getStackTrace('fault');
		super.fault(data);
	}
	
	private static function getStackTrace(functionName:String, skipAdditionalLines:int = 0):String
	{
		if (!Capabilities.isDebugger)
			return null;
		return DebugUtils.getCompactStackTrace([functionName + '()'].concat(new Error().getStackTrace().split('\n').slice(2 + skipAdditionalLines)).join('\n')).join('\n');
	}
}
