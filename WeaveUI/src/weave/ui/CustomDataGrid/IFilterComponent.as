
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
package weave.ui.CustomDataGrid
{
	import mx.core.IUIComponent;
	
	import weave.api.core.ILinkableObject;
	import weave.ui.CustomDataGrid.WeaveCustomDataGridColumn;

	public interface IFilterComponent extends IUIComponent, ILinkableObject
	{
		//method to map the Column to filtercomponent
		function mapColumnToFilter(column:WeaveCustomDataGridColumn):void;
		
		//to check whether filter value, has the default value or changed
		//if changed filterfunction is added for filtering
		function get isActive():Boolean;
		
		//function get mappedColumn():void;
		
		function filterFunction(obj:Object):Boolean;
	}
}