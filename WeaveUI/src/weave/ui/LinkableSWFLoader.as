package weave.ui
{
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	
	import mx.controls.SWFLoader;
	
	import weave.api.core.ILinkableContainer;
	import weave.api.core.ILinkableHashMap;
	import weave.api.linkBindableProperty;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableString;
	import weave.core.UIUtils;
	
	public class LinkableSWFLoader extends SWFLoader implements ILinkableContainer
	{
		public const sourceValue:LinkableString = registerLinkableChild(this, new LinkableString(""));
		
		public function LinkableSWFLoader()
		{
			super();
			linkBindableProperty(sourceValue,this,"source");
			loadForCompatibility = true;
			loaderContext = new LoaderContext(false, new ApplicationDomain());
			this.percentHeight = 100;
			this.percentWidth = 100;
//			this.source = "local_obesity.xml";
			sourceValue.value = "weave.swf?editable=false";
			UIUtils.linkDisplayObjects(this,children);
			
		}
		
		override public function get loadForCompatibility():Boolean{
			return super.loadForCompatibility;
		}
		override public function set loadForCompatibility(value:Boolean):void{
			super.loadForCompatibility = value;
		}
		
		// UI children
		public const children:LinkableHashMap = newLinkableChild(this, LinkableHashMap);
		public function getLinkableChildren():ILinkableHashMap { return children; }
		
	}
}