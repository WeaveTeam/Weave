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
	 * UI component used for displaying options for data mining algorithm inputs
	 * Consists of a label and a combobox
	 * @spurushe
	 */
	import mx.containers.HBox;
	import mx.controls.ComboBox;
	import mx.controls.Label;
	
	import weave.ui.Indent;

	public class ChoiceInputComponent extends Indent
	{
		public var choiceBox:ComboBox = new ComboBox();
		public var identifier:String = new String();
		
		public function ChoiceInputComponent(_identifier:String = null, _objects:Array = null)
		{
			this.identifier = _identifier;
			choiceBox.dataProvider = _objects;
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			this.addChild(choiceBox);
			
		}
	}
}