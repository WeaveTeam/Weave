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

package weave.services
{
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	
	import weave.api.WeaveAPI;

	/**
	 * This is an AsyncResponder that uses StageUtils.callLater() on the result and fault functions.
	 * 
	 * @author adufilie
	 */
	public class DelayedAsyncResponder extends AsyncResponder
	{
		public static function addResponder(destination:AsyncToken, result:Function, fault:Function, token:Object = null):void
		{
			destination.addResponder(new DelayedAsyncResponder(result, fault, token));
		}
		
		public function DelayedAsyncResponder(result:Function = null, fault:Function = null, token:Object = null)
		{
			super(result || noOp, fault || noOp, token);
		}
		
		private static function noOp(..._):void { } // does nothing
		
		override public function result(data:Object):void
		{
			WeaveAPI.StageUtils.callLater(null, super.result, arguments);
		}
		override public function fault(data:Object):void
		{
			WeaveAPI.StageUtils.callLater(null, super.fault, arguments);
		}
	}
}
