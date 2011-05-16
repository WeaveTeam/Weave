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

package weave.visualization.plotters
{
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.api.linkSessionState;
	import weave.api.unlinkSessionState;
	import weave.data.AttributeColumns.AlwaysDefinedColumn;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.AttributeColumns.EquationColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.SortedIndexColumn;
	import weave.visualization.plotters.styles.SolidFillStyle;
	
	/**
	 * BarChartPlotter
	 * 
	 * @author adufilie
	 */
	public class BarChartPlotter extends AbstractSimplifiedPlotter
	{
		public function BarChartPlotter()
		{
			super(BoundsPlotter);
			init();
		}
		private function init():void
		{
			// xMin (starting X point) of each bar is derived from the sorted index.
			// Since visualization tools scale any data range to fit the screen space, this will give us bars that all line up next to each other
			var xMinEquation:EquationColumn = boundsPlotter.xMinData.requestLocalObject(EquationColumn, true);
			xMinEquation.equation.value = "getNumber(xStart) + getNumber(sortIndex) * (1 + getNumber(xSpacing))";
			_sortColumn = xMinEquation.requestVariable("sortIndex", SortedIndexColumn, true);
			_xBarStart = xMinEquation.requestVariable("xStart", LinkableNumber, true);
			_xBarSpacing = xMinEquation.requestVariable("xSpacing", LinkableNumber, true);
			_xBarStart.value = 0;
			_xBarSpacing.value = 0;
			
			// the sort column uses a filtered column that updates when a subset is created
			_filteredSortColumn = _sortColumn.requestLocalObject(FilteredColumn, true);
			linkSessionState(keySet.keyFilter, _filteredSortColumn.filter);
			
			// xMax
			var xMaxEquation:EquationColumn = boundsPlotter.xMaxData.requestLocalObject(EquationColumn, true);
			xMaxEquation.equation.value = "getNumber(xMin) + 1";
			var xMinVariable:EquationColumn = xMaxEquation.requestVariable("xMin", EquationColumn, true);
			linkSessionState(xMinEquation, xMinVariable);

			// the yMin of each bar (starting Y point) uses a column with the same value for each key, the value 0
			var zero:AlwaysDefinedColumn = boundsPlotter.yMinData.requestLocalObject(AlwaysDefinedColumn, false);
			// set the default value for the alwaysDefinedColumn to be 0, this will make the yMinData use 0 for all records
			zero.defaultValue.setSessionState(0); // default: bars start from zero
			
			// register the public properties
			registerSpatialProperties(yBarBegin, yBarEnd, sortColumn, xBarStart, xBarSpacing);
			registerNonSpatialProperties(colorColumn, alphaColumn);
			
			setKeySource(yBarEnd);
			
			linkSortToHeight.value = false;
		}

		public const linkSortToHeight:LinkableBoolean = newNonSpatialProperty(LinkableBoolean, handleLinkSortToHeight);
		private function handleLinkSortToHeight():void
		{
			// if the sort column is linked to the height column, use the same column for yBarEnd as for sortColumn
			if(linkSortToHeight.value)
			{
				linkSessionState(yBarEnd, sortColumn);
			}
			else
			{
				unlinkSessionState(yBarEnd, sortColumn);
			}
		}

		private var _sortColumn:SortedIndexColumn;
		private var _filteredSortColumn:FilteredColumn;
		private var _xBarStart:LinkableNumber;
		private var _xBarSpacing:LinkableNumber;

		// the private plotter being simplified
		private function get boundsPlotter():BoundsPlotter { return internalPlotter as BoundsPlotter; }

		public function get xBarStart():LinkableNumber { return _xBarStart; }
		public function get xBarSpacing():LinkableNumber { return _xBarSpacing; }
		
		public function get yBarBegin():DynamicColumn { return boundsPlotter.yMinData; }
		public function get yBarEnd():DynamicColumn { return boundsPlotter.yMaxData; }
		public function get sortColumn():DynamicColumn { return _filteredSortColumn.internalDynamicColumn; }
		public function get colorColumn():AlwaysDefinedColumn { return (boundsPlotter.fillStyle.internalObject as SolidFillStyle).color; }
		public function get alphaColumn():AlwaysDefinedColumn { return (boundsPlotter.fillStyle.internalObject as SolidFillStyle).alpha; }
	}
}
