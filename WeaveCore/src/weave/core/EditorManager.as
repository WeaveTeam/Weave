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

package weave.core
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.ILinkableObject;
	import weave.api.getCallbackCollection;
	import weave.api.newDisposableChild;
	import weave.api.ui.IEditorManager;
	import weave.api.ui.ILinkableObjectEditor;

	/**
	 * Manages implementations of ILinkableObjectEditor.
	 */
	public class EditorManager implements IEditorManager
	{
		private const _editorLookup:Dictionary = new Dictionary(true);
		
		/**
		 * @inheritDoc
		 */
		public function registerEditor(linkableObjectOrClass:Object, editorType:Class):void
		{
			var editorQName:String = getQualifiedClassName(editorType);
			var interfaceQName:String = getQualifiedClassName(ILinkableObjectEditor);
			if (!ClassUtils.classImplements(editorQName, interfaceQName))
				throw new Error(editorQName + " does not implement " + interfaceQName);
			
			_editorLookup[linkableObjectOrClass] = editorType;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getEditorClass(linkableObjectOrClass:Object):Class
		{
			var editorClass:Class = _editorLookup[linkableObjectOrClass] as Class;
			if (editorClass)
				return editorClass;
			
			var classQName:String = linkableObjectOrClass as String || getQualifiedClassName(linkableObjectOrClass);
			var superClasses:Array = ClassUtils.getClassExtendsList(classQName);
			superClasses.unshift(classQName);
			for (var i:int = 0; i < superClasses.length; i++)
			{
				classQName = superClasses[i];
				var classDef:Class = ClassUtils.getClassDefinition(classQName);
				editorClass = _editorLookup[classDef] as Class
				if (editorClass)
					return editorClass;
			}
			return null;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getNewEditor(obj:ILinkableObject):ILinkableObjectEditor
		{
			var Editor:Class = getEditorClass(obj);
			if (Editor)
			{
				var editor:ILinkableObjectEditor = newDisposableChild(obj, Editor); // when the object goes away, make the editor go away
				editor.setTarget(obj);
				return editor;
			}
			return null;
		}
		
		private const labels:Dictionary = new Dictionary(true);
		
		/**
		 * @inheritDoc
		 */
		public function setLabel(object:ILinkableObject, label:String):void
		{
			labels[object] = label;
			getCallbackCollection(this).triggerCallbacks();
		}
		
		/**
		 * @inheritDoc
		 */
		public function getLabel(object:ILinkableObject):String
		{
			return labels[object];
		}
	}
}
