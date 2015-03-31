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

package weave.ui
{
	import flash.events.Event;
	
	import mx.containers.ViewStack;
	
	/**
	 * Crash prevention.
	 * Prevents ViewStack from setting historyManagementEnabled = true.
	 * Prevents commitProperties() from adding event listener that calls HistoryManager.unregister(this);
	 */	
	public class CustomViewStack extends ViewStack
	{
		override public function set historyManagementEnabled(value:Boolean):void
		{
			super.historyManagementEnabled = false;
		}
		
		private var inCommitProperties:Boolean = false;
		
		override protected function commitProperties():void
		{
			inCommitProperties = true;
			super.commitProperties();
			inCommitProperties = false;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			if (inCommitProperties && type == Event.REMOVED_FROM_STAGE && useCapture == false && priority == 0 && useWeakReference == true)
				return;
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
	}
}

/*
Error: ReferenceError: BrowserHistory is not defined
	at flash.external::ExternalInterface$/_toAS()
	at flash.external::ExternalInterface$/call()
	at mx.managers::BrowserManagerImpl/setup()
	at mx.managers::BrowserManagerImpl/initForHistoryManager()
	at mx.managers::HistoryManagerImpl()
	at mx.managers::HistoryManagerImpl$/getInstance()
	at mx.core::Singleton$/getInstance()[E:\dev\4.5.1\frameworks\projects\framework\src\mx\core\Singleton.as:113]
	at mx.managers::HistoryManager$/get impl()
	at mx.managers::HistoryManager$/unregister()
	at mx.containers::ViewStack/removedFromStageHandler()
	at flash.display::DisplayObjectContainer/addChild()
	at mx.core::Container/http://www.adobe.com/2006/flex/mx/internal::createContentPane()
	at mx.core::Container/createOrDestroyScrollbars()
	at mx.core::Container/createScrollbarsIfNeeded()
	at mx.core::Container/createContentPaneAndScrollbarsIfNeeded()
	at mx.core::Container/validateDisplayList()
	at mx.managers::LayoutManager/validateDisplayList()
	at mx.managers::LayoutManager/doPhasedInstantiation()
	at mx.managers::LayoutManager/doPhasedInstantiationCallback()
*/
