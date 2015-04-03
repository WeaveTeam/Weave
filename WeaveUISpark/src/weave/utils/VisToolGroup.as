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
