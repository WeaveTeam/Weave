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
	
	import mx.containers.TabNavigator;
	
	/**
	 * Crash prevention.
	 * Prevents TabNavigator from setting historyManagementEnabled = true.
	 * Prevents commitProperties() from adding event listener that calls HistoryManager.unregister(this);
	 */	
	public class CustomTabNavigator extends TabNavigator
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
	at mx.managers::HistoryManager$/register()
	at mx.containers::ViewStack/commitProperties()
	at mx.containers::TabNavigator/commitProperties()
	at mx.core::UIComponent/validateProperties()
	at mx.managers::LayoutManager/validateClient()
	at mx.core::UIComponent/validateNow()
	at weave.ui::ControlPanel/adjustControls()[C:\Weave\WeaveUI\src\weave\ui\ControlPanel.mxml:195]
	at weave.ui::ControlPanel/set targets()[C:\Weave\WeaveUI\src\weave\ui\ControlPanel.mxml:182]
	at weave.ui::ControlPanel/save()[C:\Weave\WeaveUI\src\weave\ui\ControlPanel.mxml:243]
	at weave.ui::ControlPanel/handleAddedToStage()[C:\Weave\WeaveUI\src\weave\ui\ControlPanel.mxml:335]
	at weave.ui::ControlPanel/___ControlPanel_DraggablePanel1_addedToStage()[C:\Weave\WeaveUI\src\weave\ui\ControlPanel.mxml:25]
	at flash.display::DisplayObjectContainer/addChildAt()
	at mx.core::UIComponent/http://www.adobe.com/2006/flex/mx/internal::$addChildAt()
	at mx.core::Container/addChildAt()
	at mx.containers::Panel/addChildAt()
	at mx.core::Container/addChild()
	at mx.core::Container/createComponentFromDescriptor()
	at mx.core::Container/createComponentsFromDescriptors()
	at mx.containers::Panel/createComponentsFromDescriptors()
	at mx.core::Container/createChildren()
	at mx.containers::Panel/createChildren()
	at weave.ui::DraggablePanel/createChildren()[C:\Weave\WeaveUI\src\weave\ui\DraggablePanel.mxml:242]
	at weave.visualization.tools::SimpleVisTool/createChildren()[C:\Weave\WeaveUI\src\weave\visualization\tools\SimpleVisTool.as:113]
	at weave.visualization.tools::MapTool/createChildren()[C:\Weave\WeaveUI\src\weave\visualization\tools\MapTool.mxml:269]
	at mx.core::UIComponent/initialize()
	at mx.core::Container/initialize()
	at weave.ui::DraggablePanel/initialize()
	at weave.visualization.tools::MapTool/initialize()
	at mx.core::UIComponent/http://www.adobe.com/2006/flex/mx/internal::childAdded()
	at mx.core::UIComponent/addChildAt()
	at spark.components::Group/addDisplayObjectToDisplayList()
	at spark.components::Group/http://www.adobe.com/2006/flex/mx/internal::elementAdded()
	at spark.components::Group/addElementAt()
	at spark.components::Group/addElement()
	at weave.ui::BasicLinkableLayoutManager/addComponent()[C:\Weave\WeaveUISpark\src\weave\ui\BasicLinkableLayoutManager.as:65]
	at Function/weave.core:UIUtils/linkLayoutManager/weave.core:componentListCallback()[C:\Weave\WeaveCore\src\weave\core\UIUtils.as:217]
	at Function/http://adobe.com/AS3/2006/builtin::apply()
	at weave.core::CallbackCollection/_runCallbacksImmediately()[C:\Weave\WeaveCore\src\weave\core\CallbackCollection.as:195]
	at weave.core::ChildListCallbackInterface/runCallbacks()[C:\Weave\WeaveCore\src\weave\core\ChildListCallbackInterface.as:70]
	at weave.core::LinkableHashMap/createAndSaveNewObject()[C:\Weave\WeaveCore\src\weave\core\LinkableHashMap.as:295]
	at weave.core::LinkableHashMap/initObjectByClassName()[C:\Weave\WeaveCore\src\weave\core\LinkableHashMap.as:246]
	at weave.core::LinkableHashMap/requestObject()[C:\Weave\WeaveCore\src\weave\core\LinkableHashMap.as:170]
	at weave.core::ExternalSessionStateInterface/requestObject()[C:\Weave\WeaveCore\src\weave\core\ExternalSessionStateInterface.as:158]
	at Function/http://adobe.com/AS3/2006/builtin::apply()
	at JavaScript$/handleJsonCall()[C:\Weave\WeaveAPI\src\JavaScript.as:236]
	at Function/http://adobe.com/AS3/2006/builtin::apply()
	at flash.external::ExternalInterface$/_callIn()
	at Function/<anonymous>()
	at flash.external::ExternalInterface$/_evalJS()
	at flash.external::ExternalInterface$/call()
	at JavaScript$/exec()[C:\Weave\WeaveAPI\src\JavaScript.as:428]
	at WeaveAPI$/callExternalWeaveReady()[C:\Weave\WeaveAPI\src\WeaveAPI.as:286]
	at VisApplication/handleConfigFileDownloaded()[C:\Weave\WeaveUI\src\weave\application\VisApplication.as:306]
	at mx.rpc::AsyncResponder/result()[E:\dev\4.5.1\frameworks\projects\rpc\src\mx\rpc\AsyncResponder.as:95]
	at CustomAsyncResponder/result()[C:\Weave\WeaveData\src\weave\services\URLRequestUtils.as:600]
	at mx.rpc::AsyncToken/http://www.adobe.com/2006/flex/mx/internal::applyResult()[E:\dev\4.5.1\frameworks\projects\rpc\src\mx\rpc\AsyncToken.as:239]
*/
