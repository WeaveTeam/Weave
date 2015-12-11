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

package weavejs.util
{
	internal class WeavePromiseHandler
	{
		public var onFulfilled:Function;
		public var onRejected:Function;
		public var next:WeavePromise;
		
		public function WeavePromiseHandler(onFulfilled:Function, onRejected:Function, next:WeavePromise)
		{
			this.next = next;
			this.onFulfilled = onFulfilled;
			this.onRejected = onRejected;
		}
		
		public function onResult(result:Object):void
		{
			wasCalled = true;
			try
			{
				next.setResult(onFulfilled(result));
			}
			catch (e:Error)
			{
				onError(e);
			}
		}
		
		public function onError(error:Object):void
		{
			wasCalled = true;
			try
			{
				next.setError(onRejected(error));
			}
			catch (e:Error)
			{
				next.setError(e);
			}
		}
		
		/**
		 * Used as a flag to indicate whether or not this handler has been called 
		 */
		public var wasCalled:Boolean = false;
	}
}
