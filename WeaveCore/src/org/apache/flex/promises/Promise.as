////////////////////////////////////////////////////////////////////////////////
//
//  Licensed to the Apache Software Foundation (ASF) under one or more
//  contributor license agreements.  See the NOTICE file distributed with
//  this work for additional information regarding copyright ownership.
//  The ASF licenses this file to You under the Apache License, Version 2.0
//  (the "License"); you may not use this file except in compliance with
//  the License.  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
////////////////////////////////////////////////////////////////////////////////

// Modified for Weave by changing all private symbols to protected and added newPromise() used by then()

package org.apache.flex.promises
{

import org.apache.flex.promises.enums.PromiseState;
import org.apache.flex.promises.interfaces.IThenable;
import org.apache.flex.promises.vo.Handler;

public class Promise implements IThenable
{


	//--------------------------------------------------------------------------
	//
	//    Constructor
	//
	//--------------------------------------------------------------------------
	
	public function Promise(resolver:Function) 
	{
		handlers_ = new Vector.<Handler>();
		
		state_ = PromiseState.PENDING;
		
		doResolve_(resolver, resolve_, reject_);
	}



	//--------------------------------------------------------------------------
	//
	//    Variables
	//
	//--------------------------------------------------------------------------
	
	protected var handlers_:Vector.<Handler>;
	
	protected var state_:PromiseState;
	
	protected var value_:*;
	
	
	
	//--------------------------------------------------------------------------
	//
	//    Methods
	//
	//--------------------------------------------------------------------------
	
	//----------------------------------
	//    doResolve_
	//----------------------------------
	
	protected function doResolve_(fn:Function, onFulfilled:Function, 
								onRejected:Function):void
	{
		var done:Boolean = false;
		
		try
		{
			fn(function (value:*):void {
				if (done)
				{
					return;
				}
				
				done = true;
				
				onFulfilled(value);
			}, function (reason:*):void {
				if (done)
				{
					return;
				}
				
				done = true;
				
				onRejected(reason);
			});
		}
		catch (e:Error)
		{
			if (done)
			{
				return;
			}
			
			done = true;
			
			onRejected(e);
		}
	}
	
	//----------------------------------
	//    fulfill_
	//----------------------------------
	
	protected function fulfill_(result:*):void
	{
		state_ = PromiseState.FULFILLED;
		
		value_ = result;
		
		processHandlers_();
	}
	
	//----------------------------------
	//    handle_
	//----------------------------------
	
	protected function handle_(handler:Handler):void
	{
		if (state_ === PromiseState.PENDING)
		{
			handlers_.push(handler);
		}
		else
		{
			if (state_ === PromiseState.FULFILLED && 
				handler.onFulfilled != null)
			{
				handler.onFulfilled(value_);
			}
			
			if (state_ === PromiseState.REJECTED && 
				handler.onRejected != null)
			{
				handler.onRejected(value_);
			}
		}
	}
	
	//----------------------------------
	//    processHandlers_
	//----------------------------------
	
	protected function processHandlers_():void
	{
		for (var i:int = 0, n:int = handlers_.length; i < n; i++)
		{
			handle_(handlers_.shift());
		}
	}
	
	//----------------------------------
	//    reject_
	//----------------------------------
	
	protected function reject_(error:*):void
	{
		state_ = PromiseState.REJECTED;
		
		value_ = error;
		
		processHandlers_();
	}
	
	//----------------------------------
	//    resolve_
	//----------------------------------
	
	protected function resolve_(result:*):void
	{
		try 
		{
			if (result && 
				(typeof(result) === 'object' || 
				 typeof(result) === 'function') &&
				Object(result).hasOwnProperty('then') &&
				result.then is Function)
			{
				doResolve_(result.then, resolve_, reject_);
			}
			else 
			{
				fulfill_(result);
			}
		}
		catch (e:Error)
		{
			reject_(e);
		}
	}
	
	protected function newPromise(resolver:Function):Promise
	{
		return new Promise(resolver);
	}

	//----------------------------------
	//    then
	//----------------------------------

	public function then(onFulfilled:Function = null, 
						 onRejected:Function = null):IThenable
	{
		return newPromise(function (resolve:Function, reject:Function):* {
			handle_(new Handler(function (result:*):* {
				if (typeof(onFulfilled) === 'function')
				{
					try
					{
						return resolve(onFulfilled(result));
					}
					catch (e:Error)
					{
						return reject(e);
					}
				}
				else
				{
					return resolve(result);
				}
			}, function (error:*):* {
				if (typeof(onRejected) === 'function')
				{
					try
					{
						return resolve(onRejected(error));
					}
					catch (e:Error)
					{
						return reject(e);
					}
				}
				else
				{
					return reject(error);
				}
			}))
		});
	}

}
}