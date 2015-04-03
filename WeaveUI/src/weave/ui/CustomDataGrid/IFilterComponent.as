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

package weave.ui.CustomDataGrid
{
	import mx.core.IUIComponent;
	
	import weave.api.core.ILinkableObject;
	import weave.ui.CustomDataGrid.DataGridColumnForQKeyWithFilterAndGraphics;

	public interface IFilterComponent extends IUIComponent, ILinkableObject
	{
		//method to map the Column to filtercomponent
		function mapColumnToFilter(column:DataGridColumnForQKeyWithFilterAndGraphics):void;
		
		//to check whether filter value, has the default value or changed
		//if changed filterfunction is added for filtering
		function get isActive():Boolean;
		
		//function get mappedColumn():void;
		
		function filterFunction(obj:Object):Boolean;
	}
}