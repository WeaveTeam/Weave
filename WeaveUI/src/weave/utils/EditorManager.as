/*
    Weave (Web-based Analysis and Visualization Environment)
    Copyright (C) 2008-2011 University of Massachusetts Lowell

    This file is a part of Weave.

    Weave is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License, Version 3,
    as published by the Free Software Foundation.

    Weave is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/
package weave.utils
{
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.utils.StringUtil;
	
	import weave.api.core.ILinkableObject;
	import weave.api.newDisposableChild;
	import weave.api.registerDisposableChild;
	import weave.api.ui.ILinkableObjectEditor;
	import weave.core.ClassUtils;

	public class EditorManager
	{
		private static const _editorLookup:Dictionary = new Dictionary();
		
		/**
		 * This function will register an ILinkableObjectEditor Class corresponding to an ILinkableObject Class.
		 * @param objType A Class that implements ILinkableObject
		 * @param editorType The corresponding Class implementing ILinkableObjectEditor
		 */
		public static function registerEditor(objType:Class, editorType:Class):void
		{
			_editorLookup[objType] = editorType;
		}
		
		/**
		 * @param obj An object or Class implementing ILinkableObject.
		 * @return The Class implementing ILinkableObjectEditor that was previously registered for the given type of object or one of its superclasses.
		 */
		public static function getEditorClass(linkableObjectOrClass:Object):Class
		{
			var interfaceQName:String = getQualifiedClassName(ILinkableObjectEditor);
			var classQName:String = linkableObjectOrClass as String || getQualifiedClassName(linkableObjectOrClass);
			var superClasses:Array = ClassUtils.getClassExtendsList(classQName);
			superClasses.unshift(classQName);
			for (var i:int = 0; i < superClasses.length; i++)
			{
				classQName = superClasses[i];
				var classDef:Class = ClassUtils.getClassDefinition(classQName);
				var editorClass:Class = _editorLookup[classDef] as Class
				if (editorClass != null)
				{
					var editorQName:String = getQualifiedClassName(editorClass);
					if (ClassUtils.classImplements(editorQName, interfaceQName))
					{
						return editorClass;
					}
					else
					{
						delete _editorLookup[classDef];
						throw new Error(editorQName + " does not implement " + interfaceQName);
					}
				}
			}
			return null;
		}
		
		public static function getNewEditor(obj:ILinkableObject):ILinkableObjectEditor
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
	}
}
