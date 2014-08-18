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
