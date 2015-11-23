package weave.ui
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import mx.containers.BoxDirection;
	import mx.containers.DividedBox;
	import mx.containers.dividedBoxClasses.BoxDivider;
	import mx.core.UIComponent;
	import mx.core.mx_internal;
	import mx.events.ChildExistenceChangedEvent;
	
	import avmplus.getQualifiedClassName;
	
	import weave.api.getCallbackCollection;
	import weave.api.linkBindableProperty;
	import weave.api.objectWasDisposed;
	import weave.api.registerLinkableChild;
	import weave.api.core.DynamicState;
	import weave.api.core.ILinkableVariable;
	import weave.compiler.Compiler;
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
		private static var LinkableDynamicDisplayObject_QName:String;
		private static var FlexibleLayout_QName:String;
		
		public function FlexibleLayout()
		{
			if (!LinkableDynamicDisplayObject_QName)
				LinkableDynamicDisplayObject_QName = getQualifiedClassName(LinkableDynamicDisplayObject);
			if (!FlexibleLayout_QName)
				FlexibleLayout_QName = getQualifiedClassName(FlexibleLayout);
			
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
		private const _originalParents:Dictionary = new Dictionary(true);
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			try
			{
				// workaround for missing divider bug
				while (numChildren > 0 && numDividers < numChildren - 1)
				{
					var child:UIComponent = getChildAt(0) as UIComponent;
					if (!child.includeInLayout)
						break; // prevent infinite loop
					// dispatching this event causes DividedBox to create another divider
					child.dispatchEvent(new Event("includeInLayoutChanged"));
				}
				
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
			return dynamicState[DynamicState.SESSION_STATE];
		}
		
		public function getSessionState():Object
		{
			var children:Array = _children.getSessionState().map(_mapChildOutput);
			var state:Object = {};
			state[FLEX] = _flex.value || 1;
			state[DIRECTION] = _direction.value;
			if (children.length == 1 && children[0] is Array)
				state[ID] = children[0];
			else
				state[CHILDREN] = children;
			return state;
		}
		
		private function simplifyState(state:Object):Object
		{
			var children:Array = state[CHILDREN] as Array;
			if (!children)
				return state;
			if (children.length == 1)
				return simplifyState(children[0]);
			
			var simpleChildren:Array = [];
			for (var i:int = 0; i < children.length; i++)
			{
				var child:Object = simplifyState(children[i]);
				if (child[CHILDREN] is Array && child[DIRECTION] === state[DIRECTION])
				{
					var childChildren:Array = child[CHILDREN] as Array;
					for (var ii:int = 0; ii < childChildren.length; ii++)
					{
						var childChild:Object = childChildren[ii];
						childChild[FLEX] *= child[FLEX];
						simpleChildren.push(childChild);
					}
				}
				else
				{
					simpleChildren.push(child);
				}
			}
			state[CHILDREN] = simpleChildren;
			return state;
		}
				
		public function setSessionState(state:Object):void
		{
			if (!state)
				state = {};
			
			try
			{
				state = simplifyState(state);
			}
			catch (e:Error)
			{
				trace(debugId(this), 'received invalid state:', Compiler.stringify(state, null, '\t'));
			}
			
			var id:Array = state[ID] is String ? [state[ID] as String] : state[ID] as Array;
			var flex:Number = state[FLEX];
			var direction:String = state[DIRECTION] as String;
			var children:Array = id ? [id] : (state[CHILDREN] as Array || []).concat();
			
			for (var i:int = 0; i < children.length; i++)
			{
				var objectName:String = 'child' + i;
				var child:Object = children[i];
				if (child is Array)
					child = DynamicState.create(objectName, LinkableDynamicDisplayObject_QName, child);
				else
					child = DynamicState.create(objectName, FlexibleLayout_QName, child);
				children[i] = child;
			}
			
			getCallbackCollection(this).delayCallbacks();
			
			_flex.value = flex;
			_direction.value = direction;
			_children.setSessionState(children, true);
			adjustChildFlexValues();
			
			getCallbackCollection(this).resumeCallbacks();
		}
	}
}