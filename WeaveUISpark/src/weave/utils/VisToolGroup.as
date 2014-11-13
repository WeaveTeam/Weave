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
	import weave.api.core.ILinkableObject;
	import weave.api.data.IKeyFilter;
	import weave.api.data.IKeySet;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableDynamicObject;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.FilteredColumn;

	/**
	 * This is an encapsulation of a set of references to global objects used by a visualization tool.
	 *
	 * @author pkovac 
	 * @author adufilie
	 */
	public class VisToolGroup implements ILinkableObject
	{
		//TODO: create a corresponding Class that has, for each setting here, a corresponding LinkableHashMap containing possible choices 
		
		
		public const colorColumn:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(ColorColumn));
		public const probeKeySet:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IKeySet));
		public const selectionKeySet:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IKeySet));
		public const subsetKeyFilter:LinkableDynamicObject = registerLinkableChild(this, new LinkableDynamicObject(IKeyFilter));
		
		//TODO: object which specifies transformation from IQualifiedKey to color value... instead of nested color/bin/filter columns
		
		public function getColorColumn():ColorColumn { return colorColumn.internalObject as ColorColumn; }
		public function getColorBinColumn():BinnedColumn { return getColorColumn().getInternalColumn() as BinnedColumn; }
		public function getColorDataColumn():FilteredColumn { return getColorBinColumn().getInternalColumn() as FilteredColumn; }
		
		public function getProbe():IKeySet { return probeKeySet.internalObject as IKeySet; }
		public function getSelection():IKeySet { return selectionKeySet.internalObject as IKeySet; }
		public function getSubset():IKeyFilter { return subsetKeyFilter.internalObject as IKeyFilter; }
	}
}
