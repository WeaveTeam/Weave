package weave.ui
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.containers.BoxDirection;
	import mx.containers.DividedBox;
	import mx.containers.dividedBoxClasses.BoxDivider;
	import mx.core.mx_internal;
	import mx.events.ChildExistenceChangedEvent;
	
	import avmplus.getQualifiedClassName;
	
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.core.DynamicState;
	import weave.api.core.ILinkableVariable;
	import weave.compiler.StandardLib;
	import weave.core.LinkableDynamicDisplayObject;
	import weave.core.LinkableHashMap;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.UIUtils;

	use namespace mx_internal;
	
	public class FlexibleLayout extends DividedBox implements ILinkableVariable
	{
		private static const ID:String = 'id';
		private static const FLEX:String = 'flex';
		private static const DIRECTION:String = 'direction';
		private static const CHILDREN:String = 'children';
		
		public function FlexibleLayout()
		{
			setStyle('horizontalGap', 8);
			setStyle('verticalGap', 8);
			minWidth = 16;
			minHeight = 16;
			percentWidth = 100;
			percentHeight = 100;
			linkBindableProperty(_direction, this, 'direction');
			UIUtils.linkDisplayObjects(this, _children);
			this.addEventListener(ChildExistenceChangedEvent.CHILD_ADD, handleChildAdd);
			this.addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, handleChildRemove);
		}
		
		private const _flex:LinkableNumber = registerLinkableChild(this, new LinkableNumber(1));
		private const _direction:LinkableString = registerLinkableChild(this, new LinkableString(BoxDirection.VERTICAL, verifyDirection), adjustChildFlexValues, true);
		private const _children:LinkableHashMap = registerLinkableChild(this, new LinkableHashMap(), adjustChildFlexValues, true);
		private var _childNamesForMapChildInput:Array;
		private const _originalParents:Dictionary = new Dictionary(true);
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			try
			{
				super.updateDisplayList(unscaledWidth, unscaledHeight);
			}
			catch (e:Error)
			{
				// ignore getChildAt() errors
				if (e.errorID != 2006)
					throw e;
			}
		}
		
		private function handleChildAdd(event:ChildExistenceChangedEvent):void
		{
			var child:DisplayObject = event.relatedObject;
			var parent:DisplayObject = UIUtils.getPreviousParent(child);
			if (parent && !(parent is FlexibleLayout))
				_originalParents[child] = parent;
		}
		private function handleChildRemove(event:ChildExistenceChangedEvent):void
		{
			var child:DisplayObject = event.relatedObject;
			var parent:DisplayObjectContainer = _originalParents[child];
			delete _originalParents[child];
			if (parent && !objectWasDisposed(child))
				UIUtils.spark_addChild(parent, child);
		}
		
		private function verifyDirection(dir:String):Boolean
		{
			return dir == BoxDirection.HORIZONTAL || dir == BoxDirection.VERTICAL;
		}
		
		override mx_internal function stopDividerDrag(divider:BoxDivider, trigger:MouseEvent):void
		{
			super.stopDividerDrag(divider, trigger);
			adjustChildFlexValues(true);
		}
		
		private function adjustChildFlexValues(fromUser:Boolean = false):void
		{
			var children:Array = _children.getObjects(FlexibleLayout);
			var flexValues:Array = [];
			var child:FlexibleLayout;
			var value:Number;
			
			if (fromUser)
			{
				for each (child in children)
					flexValues.push(direction == BoxDirection.HORIZONTAL ? child.percentWidth : child.percentHeight);
			}
			else
			{
				for each (child in children)
					flexValues.push(child._flex.value);
			}
			
			var sum:Number = StandardLib.sum(flexValues);
			var smallest:Number = Math.min.apply(Math, flexValues);
			for (var i:int = 0; i < children.length; i++)
			{
				child = children[i];
				value = flexValues[i];
				
				if (direction == BoxDirection.HORIZONTAL)
					child.percentWidth = value / smallest * 100;
				else
					child.percentHeight = value / smallest * 100;
				child._flex.value = value / sum;
			}
		}
		
		private function _mapChildOutput(dynamicState:Object, i:int, a:Array):Object
		{
			var output:Object = dynamicState[DynamicState.SESSION_STATE];
			if (DynamicState.isDynamicStateArray(output) && output.length == 1 && output[0][DynamicState.CLASS_NAME] == 'Array')
				output = output[0][DynamicState.SESSION_STATE];
			return output;
		}
		
		private function _mapChildInput(state:Object, i:int, a:Array):Object
		{
			var objectName:String = _childNamesForMapChildInput[i] || 'child' + i;
			var className:String = getQualifiedClassName(state is Array ? LinkableDynamicDisplayObject : FlexibleLayout);
			return DynamicState.create(objectName, className, state);
		}
		
		public function getSessionState():Object
		{
			var children:Array = _children.getSessionState().map(_mapChildOutput);
			var state:Object = {};
			state[FLEX] = _flex.value || 1;
			state[DIRECTION] = _direction.value;
			if (children.length == 1)
			{
				state[ID] = children[0];
				delete state[CHILDREN];
			}
			else
			{
				delete state[ID];
				state[CHILDREN] = children;
			}
			return state;
		}
		
		public function setSessionState(state:Object):void
		{
			if (!state)
				state = {};
			
			var id:Array = state[ID] is String ? [state[ID] as String] : state[ID] as Array;
			var flex:Number = state[FLEX];
			var direction:String = state[DIRECTION] as String;
			var children:Array = id ? [id] : (state[CHILDREN] as Array || []);
			
			_childNamesForMapChildInput = _children.getNames();
			children = children.map(_mapChildInput);
			
			getCallbackCollection(this).delayCallbacks();
			
			_flex.value = flex;
			_direction.value = direction;
			_children.setSessionState(children, true);
			adjustChildFlexValues();
			
			getCallbackCollection(this).resumeCallbacks();
		}
	}
}