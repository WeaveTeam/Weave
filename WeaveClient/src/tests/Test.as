package tests
{
	import mx.utils.ObjectUtil;
	
	import weave.api.core.ICallbackCollection;
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.getSessionState;
	import weave.api.newLinkableChild;
	import weave.api.setSessionState;
	import weave.core.LinkableString;

	public class Test implements ILinkableObject
	{
		public const obj:Obj = newLinkableChild(this, Obj); // child of the Test
		public const myStr:LinkableString = newLinkableChild(this, LinkableString);
		
		private function debug(type:String = "grouped"):void
		{
			trace(type, obj.num.value, obj.str.value, obj.bool.value);
		}
		
		public function runTest():void
		{
			var objCallbacks:ICallbackCollection = getCallbackCollection(obj);
			objCallbacks.addImmediateCallback(this, debug, ["immediate"]);
			obj.num.addGroupedCallback(this, debug);
			obj.str.addGroupedCallback(this, debug);
			
			myStr.value = "Hello, world.";
			obj.bool.value = true; // this triggers obj's callbacks because obj.bool is a registered child
			// prints "immediate NaN (null) true
			
			var state:Object = getSessionState(this);
			trace(ObjectUtil.toString(state)); // {myStr: "Hello, world.", obj: {num: NaN, str: (null), bool: true}}

			setSessionState(obj, {num: 1, str: "one"}); // prints "immediate 1 one true"
			obj.num.value = 1; // no callback because it's already set to 1
			obj.str.setSessionState("two"); // prints "immediate 1 two true"
			obj.num.value = 2; // prints "immediate 2 two true"
			
			state = getSessionState(this);
			trace(ObjectUtil.toString(state)); // {myStr: "Hello, world.", obj: {num: 2, str: "two", bool: true}}
			
			objCallbacks.delayCallbacks();
			obj.num.value = 3; // no callback
			obj.str.value = "three"; // no callback
			objCallbacks.resumeCallbacks(); // prints "immediate 3 three true"
			
			// next frame, printout is "grouped 3 three true"
		}
	}
}
