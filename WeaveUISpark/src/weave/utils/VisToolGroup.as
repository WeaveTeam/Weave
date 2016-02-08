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
	import weave.api.data.IColumnWrapper;
	import weave.api.data.IDynamicKeyFilter;
	import weave.api.data.IDynamicKeySet;
	import weave.api.newLinkableChild;
	import weave.api.registerLinkableChild;
	import weave.api.ui.IVisToolGroup;
	import weave.data.AttributeColumns.BinnedColumn;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.KeySets.DynamicKeyFilter;
	import weave.data.KeySets.DynamicKeySet;

	/**
	 * This is an encapsulation of a set of references to global objects used by a visualization tool.
	 *
	 * @author pkovac 
	 * @author adufilie
	 */
	public class VisToolGroup implements IVisToolGroup
	{
		//TODO: create a corresponding Class that has, for each setting here,
		// a corresponding LinkableHashMap containing possible choices
		
		private const _colorColumn:IColumnWrapper = registerLinkableChild(this, new DynamicColumn(ColorColumn));
		private const _probeKeySet:IDynamicKeySet = newLinkableChild(this, DynamicKeySet);
		private const _selectionKeySet:IDynamicKeySet = newLinkableChild(this, DynamicKeySet);
		private const _subsetKeyFilter:IDynamicKeyFilter = newLinkableChild(this, DynamicKeyFilter);
		
		public function get colorColumn():IColumnWrapper { return _colorColumn; }
		public function get probeKeySet():IDynamicKeySet { return _probeKeySet; }
		public function get selectionKeySet():IDynamicKeySet { return _selectionKeySet; } 
		public function get subsetKeyFilter():IDynamicKeyFilter { return _subsetKeyFilter; }
		
		//TODO: object which specifies transformation from IQualifiedKey to color value... instead of nested color/bin/filter columns
		
		public function getColorColumn():ColorColumn { return _colorColumn.getInternalColumn() as ColorColumn; }
		public function getColorBinColumn():BinnedColumn { var cc:ColorColumn = getColorColumn(); return cc ? cc.getInternalColumn() as BinnedColumn : null; }
		public function getColorDataColumn():FilteredColumn { var bc:BinnedColumn = getColorBinColumn(); return bc ? bc.getInternalColumn() as FilteredColumn : null; }
	}
}
