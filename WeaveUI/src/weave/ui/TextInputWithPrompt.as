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
package weave.ui
{
	import flash.events.FocusEvent;
	
	import mx.controls.TextInput;
	import mx.core.mx_internal;
	use namespace mx_internal;

	/**
	 * This is a TextInput control that allows setting a prompt such as "Enter search text"
	 * that appears faded out when the user has not entered any text.
	 * 
	 * @author adufilie
	 */
	public class TextInputWithPrompt extends TextInput
	{
		public function TextInputWithPrompt()
		{
			super();
			showPrompt();
		}
		
		public function asTextInput():TextInput { return this; }
		
		protected static const PROMPT_TEXT_ALPHA:Number = 0.5; // alpha of text when prompt is shown
		protected static const DEFAULT_TEXT_ALPHA:Number = 1.0; // alpha of text when prompt is not shown
		
		private var _promptIsShown:Boolean = false; // to know if the prompt is shown or not
		private var _prompt:String = ''; // for storing the prompt text

		/**
		 * If this is set to true, all the text will be selected when focus is given to the TextInput.
		 */
		[Bindable] public var autoSelect:Boolean = true;
		
		/**
		 * This is the prompt that is shown when no text has been entered.
		 */
		[Bindable]
		public function get prompt():String
		{
			return _prompt;
		}
		public function set prompt(value:String):void
		{
			_prompt = value;
			if (_promptIsShown)
				super.text = _prompt; // bypass local setter
		}
		
		/**
		 * This function makes sure the prompt text gets replaced with an empty String.
		 */
		override public function get text():String
		{
			if (_promptIsShown)
				return '';
			return super.text;
		}
		
		/**
		 * Setting the text causes the prompt to disappear. 
		 */
		override public function set text(value:String):void
		{
			if (value)
			{
				hidePrompt();
				super.text = value; // bypass local setter
			}
			else
			{
				showPrompt();
			}
		}
		
		/**
		 * This function initializes the alpha of the text when the TextField gets created.
		 */
		override mx_internal function createTextField(childIndex:int):void
		{
			super.createTextField(childIndex);
			if (_promptIsShown)
				textField.alpha = PROMPT_TEXT_ALPHA;
			else
				textField.alpha = DEFAULT_TEXT_ALPHA;
		}

		/**
		 * This function shows the prompt.
		 */
		private function showPrompt():void
		{
			if (!_promptIsShown && !_hasFocus)
			{
				_promptIsShown = true;
				super.text = _prompt; // bypass local setter
				if (textField)
					textField.alpha = PROMPT_TEXT_ALPHA;
			}
		}
		
		/**
		 * This function hides the prompt.
		 */
		private function hidePrompt():void
		{
			if (_promptIsShown)
			{
				_promptIsShown = false;
				super.text = ''; // bypass local setter
				if (textField)
					textField.alpha = DEFAULT_TEXT_ALPHA;
			}
		}
		
		private var _hasFocus:Boolean = false;
		
		/**
		 * This function hides the prompt if it is shown, and selects all if autoSelect is true.
		 */
		override protected function focusInHandler(event:FocusEvent):void
		{
			_hasFocus = true;
			hidePrompt();
			
			if (autoSelect)
			{
				selectionBeginIndex = 0;
				selectionEndIndex = text.length;
			}
			
			super.focusInHandler(event);
		}
		
		/**
		 * This function makes the prompt reappear if the text is empty.
		 */
		override protected function focusOutHandler(event:FocusEvent):void
		{
			_hasFocus = false;
			if (!text)
				showPrompt();

			super.focusOutHandler(event);
		}
	}
}
