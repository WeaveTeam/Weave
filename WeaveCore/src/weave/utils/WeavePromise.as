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

package weave.utils
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import org.apache.flex.promises.Promise;
	
	import weave.api.core.DynamicState;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.compiler.Compiler;
	import weave.compiler.StandardLib;
	
	/**
	 * Use this when you need a Promise chain that depends on ILinkableObjects.
	 * 
	 * Adds support for <code>depend(...linkableObjects)</code>
	 */
	public class WeavePromise extends Promise
	{
		public function WeavePromise(relevantContext:Object, resolver:Function)
		{
			super(resolver);
			this.relevantContext = relevantContext;
			this.resolver = resolver;
		}
		
		private var _resolver:Function;
		private var resolve:Function;
		
		private function hijackedResolver(resolve:Function, reject:Function):void
		{
			this.resolve = resolve;
			_resolver(localResolve, reject);
		}
		
		private function localResolve(value:Object):void
		{
			
		}

		public function depend(...dependencies):Promise
		{
			this.dependencies = dependencies;
			return then(onFulfilled, onRejected);
		}
		
		private var relevantContext:Object;
		private var dependencies:Array;
		
		private function initPromise(resolve:Function, reject:Function):void
		{
			this.resolve = resolve;
			for each (var ilo:ILinkableObject in dependencies)
			{
				getCallbackCollection(ilo).addGroupedCallback(relevantContext, groupedCallback, true);
			}
		}
		
		private function groupedCallback():void
		{
			this.resolve(value);
		}
	}
}
