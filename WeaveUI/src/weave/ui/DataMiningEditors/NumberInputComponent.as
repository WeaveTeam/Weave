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
package weave.ui.DataMiningEditors
{
	/**
	 * UI component used for collecting numerical data mining algorithm inputs
	 * Consists of a label and a textinput
	 * @spurushe
	 */
	import weave.ui.Indent;
	import weave.ui.TextInputWithPrompt;

	public class NumberInputComponent extends Indent
	{
		public var numberInput:TextInputWithPrompt = new TextInputWithPrompt();
		public var identifier:String = new String();
		
		public function NumberInputComponent(_identifier:String, _inputPrompt:String)
		{
			this.identifier = _identifier;
			numberInput.prompt = _inputPrompt;
		}
		
		
		override protected function createChildren():void
		{
			super.createChildren();
			this.addChild(numberInput);
			
		}
	}
}