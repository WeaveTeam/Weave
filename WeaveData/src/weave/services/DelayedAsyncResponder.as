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

	/**
	 * This is an AsyncResponder that uses StageUtils.callLater() on the result and fault functions.
	 * 
	 * @author adufilie
	 */
	public class DelayedAsyncResponder extends AsyncResponder
	{
		internal static function addResponder(destination:AsyncToken, result:Function, fault:Function = null, token:Object = null):void
		{
			destination.addResponder(new DelayedAsyncResponder(result, fault, token));
		}
		
		public function DelayedAsyncResponder(result:Function = null, fault:Function = null, token:Object = null)
		{
			super(result || noOp, fault || noOp, token);
		}
		
		private static function noOp(..._):void { } // does nothing
		/*
		override public function result(data:Object):void
		{
			WeaveAPI.StageUtils.callLater(null, super.result, arguments);
		}
		override public function fault(data:Object):void
		{
			WeaveAPI.StageUtils.callLater(null, super.fault, arguments);
		}
		*/
	}
}
