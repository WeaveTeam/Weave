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

package weave
{
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.disposeObjects;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.core.SessionManager;
	import weave.core.weave_internal;
	import weave.data.CSVParser;
	import weave.resources.fonts.EmbeddedFonts;
	import weave.ui.SessionStateEditor;
	import weave.utils.DebugUtils;

	use namespace weave_internal;
	
	/**
	 * A list of global settings for a Weave instance.
	 */
	public class WeaveProperties implements ILinkableObject
	{
		public const version:LinkableString = new LinkableString("1.0 Beta 1"); // Weave version
		
		public function WeaveProperties()
		{
			constructor();
		}
		/**
		 * This is the constructor code. The code is in a separate function because constructors do not get compiled.
		 */
		private function constructor():void
		{
			version.lock(); // don't allow changing the version
			
			// register all properties as children of this object
			for each (var propertyName:String in (WeaveAPI.SessionManager as SessionManager).getLinkablePropertyNames(this))
				registerLinkableChild(this, this[propertyName] as ILinkableObject);
			
			rServiceURL.addImmediateCallback(null, handleRServiceURLChange);
		}
		
		private function handleRServiceURLChange():void
		{
			if (rServiceURL.value == '/WeaveServices')
				rServiceURL.value += '/RService';
		}

		public static const DEFAULT_FONT_FAMILY:String = EmbeddedFonts.SophiaNubian;
		public static const DEFAULT_FONT_SIZE:Number = 10;
		public static const DEFAULT_AXIS_FONT_SIZE:Number = 11;
		public static const DEFAULT_BACKGROUND_COLOR:Number = 0xCCCCCC;
		public static const DATA_GRID:String = "DataGrid";
		public static const TEXT_EDITOR:String = "TextArea";
		
		private static const WIKIPEDIA_URL:String = "Wikipedia|http://en.wikipedia.org/wiki/Special:Search?search=";
		private static const GOOGLE_URL:String = "Google|http://www.google.com/search?q=";
		private static const GOOGLE_MAPS_URL:String = "Google Maps|http://maps.google.com/maps?t=h&q=";
		private static const GOOGLE_IMAGES_URL:String = "Google Images|http://images.google.com/images?q=";
		
		//TEMPORARY SOLUTION -- only embedded fonts work on axis, and there is only one embedded font right now.
		public static function verifyFontFamily(value:String):Boolean { return value == DEFAULT_FONT_FAMILY; }
		private function verifyFontSize(value:Number):Boolean { return value > 2; }
		private function verifyAlpha(value:Number):Boolean { return 0 <= value && value <= 1; };
		private function verifyWindowSnapGridSize(value:Number):Boolean { return value >= 1; }
		private function verifySessionStateEditor(value:String):Boolean { return value == DATA_GRID || value == TEXT_EDITOR; }

		public const dataInfoURL:LinkableString = new LinkableString(); // file to link to for metadata information
		
//		public const showViewBar:LinkableBoolean = new LinkableBoolean(false); // show/hide Viws TabBar
		public const windowSnapGridSize:LinkableNumber = new LinkableNumber(5, verifyWindowSnapGridSize); // window snap grid size in pixels
		
		public const cssStyleSheetName:LinkableString = new LinkableString("weaveStyle.css"); // CSS Style Sheet Name/URL
		public const backgroundColor:LinkableNumber = new LinkableNumber(DEFAULT_BACKGROUND_COLOR, isFinite);
		
		
		// enable/disable advanced features
		public const enableMouseWheel:LinkableBoolean = new LinkableBoolean(true);
		public const enableDynamicTools:LinkableBoolean = new LinkableBoolean(true); // move/resize/add/remove/close tools
		public const showColorController:LinkableBoolean = new LinkableBoolean(true); // Show Color Controller option tools menu
		public const showProbeToolTipEditor:LinkableBoolean = new LinkableBoolean(true);  // Show Probe Tool Tip Editor tools menu
		public const showEquationEditor:LinkableBoolean = new LinkableBoolean(true); // Show Equation Editor option tools menu
		public const showAttributeSelector:LinkableBoolean = new LinkableBoolean(true); // Show Attribute Selector tools menu
		public const enableAddDataTable:LinkableBoolean = new LinkableBoolean(true); // Add Data Table option tools menu
		public const enableAddScatterplot:LinkableBoolean = new LinkableBoolean(true); // Add Scatterplot option tools menu
		public const enableAddMap:LinkableBoolean = new LinkableBoolean(true); // Add Map option tools menu
		public const enableAddBarChart:LinkableBoolean = new LinkableBoolean(true); // Add Bar Chart option tools menu
		public const enableAddColormapHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Colormap Histogram option tools menu
		public const enableAddHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Histogram option tools menu
		public const enableAdd2DHistogram:LinkableBoolean = new LinkableBoolean(true); // Add 2D Histogram option tools menu
		public const enableAddTimeSliderTool:LinkableBoolean = new LinkableBoolean(true); // Add Time Slider Tool option tools menu
		public const enableAddPieChart:LinkableBoolean = new LinkableBoolean(true); // Add Pie Chart option tools menu
		public const enableAddPieChartHistogram:LinkableBoolean = new LinkableBoolean(true); // Add Pie Chart option tools menu
		public const enableAddLineChart:LinkableBoolean = new LinkableBoolean(true); // Add Line Chart option tools menu
		public const enableAddThermometerTool:LinkableBoolean = new LinkableBoolean(true); // Add Thermometer Tool option tools menu
		public const enableAddGaugeTool:LinkableBoolean = new LinkableBoolean(true); // Add Gauge Tool option tools menu
		public const enableAddDimensionSliderTool:LinkableBoolean = new LinkableBoolean(true); // Add Dimension Slider Tool option tools menu		
		public const enableAddColorLegend:LinkableBoolean = new LinkableBoolean(true); // Add Color legend Tool option tools menu		
		public const enableAddRScriptEditor:LinkableBoolean = new LinkableBoolean(true); // Add R Script Editor option tools menu		
		public const enableNewUserWizard:LinkableBoolean = new LinkableBoolean(true); // Add New User Wizard option tools menu		
		public const enableAddDataFilter:LinkableBoolean = new LinkableBoolean(true);
		
//		public const enableAddStickFigurePlot:LinkableBoolean = new LinkableBoolean(true); // Add Stick Figure Plot option tools menu
//		public const enableAddRadViz:LinkableBoolean = new LinkableBoolean(true); // Add RadViz option tools menu
//		public const enableAddRadViz2:LinkableBoolean = new LinkableBoolean(true); // Add RadViz option tools menu
//		public const enableAddSP2:LinkableBoolean = new LinkableBoolean(true); // Add SP2 option tools menu
//		public const enableAddWordle:LinkableBoolean = new LinkableBoolean(true); // Add Wordle option tools menu		
//		public const enableAddRamachandranPlot:LinkableBoolean = new LinkableBoolean(true); // Add RamachandranPlot option tools menu		
//		public const enableAddSurfacePlotter:LinkableBoolean = new LinkableBoolean(true); // Add Surface Plotter option tools menu
		
		public const enablePanelCoordsPercentageMode:LinkableBoolean = new LinkableBoolean(true); // resize/position tools when window gets resized (percentage based rather than absolute)
		public const enableToolAttributeEditing:LinkableBoolean = new LinkableBoolean(true); // edit the bindings of tool vis attributes
		public const showVisToolCloseDialog:LinkableBoolean = new LinkableBoolean(false); // show "close this window?" yes/no box
		public const enableToolSelection:LinkableBoolean = new LinkableBoolean(true); // enable/disable the selection tool
		public const enableToolProbe:LinkableBoolean = new LinkableBoolean(true);
		public const enableRightClick:LinkableBoolean = new LinkableBoolean(true);
		
		public const enableProbeAnimation:LinkableBoolean = new LinkableBoolean(true);
		public const enableGeometryProbing:LinkableBoolean = new LinkableBoolean(true); // use the geometry probing (default to on even though it may be slow for mapping)
		public const enableSessionMenu:LinkableBoolean = new LinkableBoolean(true); // all sessioning
		public const enableSessionBookmarks:LinkableBoolean = new LinkableBoolean(true);
		public const enableSessionEdit:LinkableBoolean = new LinkableBoolean(true);
		public const enableSessionImport:LinkableBoolean = new LinkableBoolean(true);
		public const enableSessionExport:LinkableBoolean = new LinkableBoolean(true);

		public const enableUserPreferences:LinkableBoolean = new LinkableBoolean(true); // open the User Preferences Panel
		
		public const enableSearchForRecord:LinkableBoolean = new LinkableBoolean(true); // allow user to right click search for record
		
		public const enableMenuBar:LinkableBoolean = new LinkableBoolean(true); // top menu for advanced features
		public const enableTaskbar:LinkableBoolean = new LinkableBoolean(true); // taskbar for minimize/restore
		public const enableSubsetControls:LinkableBoolean = new LinkableBoolean(true); // creating subsets
		public const enableExportToolImage:LinkableBoolean = new LinkableBoolean(true); // print/export tool images
		public const enableExportApplicationScreenshot:LinkableBoolean = new LinkableBoolean(true); // print/export application screenshot
		public const enableExportDataTable:LinkableBoolean = new LinkableBoolean(true); // print/export data table
		
		public const enableDataMenu:LinkableBoolean = new LinkableBoolean(true); // enable/disable Data Menu
		public const enableRefreshHierarchies:LinkableBoolean = new LinkableBoolean(true);
		public const enableNewDataset:LinkableBoolean = new LinkableBoolean(true); // enable/disable New Dataset option
		public const enableAddWeaveDataSource:LinkableBoolean = new LinkableBoolean(true); // enable/disable Add WeaveDataSource option
		public const enableAddGrailsDataSource:LinkableBoolean = new LinkableBoolean(true);
		
		public const enableWindowMenu:LinkableBoolean = new LinkableBoolean(true); // enable/disable Window Menu
		public const enableGoFullscreen:LinkableBoolean = new LinkableBoolean(true); // enable/disable Fullscreen
		public const enableCloseAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Close All Windows
		public const enableRestoreAllMinimizedWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Restore All Minimized Windows 
		public const enableMinimizeAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Minimize All Windows
		public const enableCascadeAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Cascade All Windows
		public const enableTileAllWindows:LinkableBoolean = new LinkableBoolean(true); // enable/disable Tile All Windows
		
		public const enableSelectionsMenu:LinkableBoolean = new LinkableBoolean(true);// enable/disable Selections Menu
		public const enableSaveCurrentSelection:LinkableBoolean = new LinkableBoolean(true);// enable/disable Save Current Selection option
		public const enableClearCurrentSelection:LinkableBoolean = new LinkableBoolean(true);// enable/disable Clear Current Selection option
		public const enableManageSavedSelections:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage Saved Selections option
		
		public const enableSubsetsMenu:LinkableBoolean = new LinkableBoolean(true);// enable/disable Subsets Menu
		public const enableCreateSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Create subset from selected records option
		public const enableRemoveSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Remove selected records from subset option
		public const enableShowAllRecords:LinkableBoolean = new LinkableBoolean(true);// enable/disable Show All Records option
		public const enableSaveCurrentSubset:LinkableBoolean = new LinkableBoolean(true);// enable/disable Save current subset option
		public const enableManageSavedSubsets:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage saved subsets option
		
		public const enableAddDataSource:LinkableBoolean = new LinkableBoolean(true);// enable/disable Manage saved subsets option
		public const enableEditDataSource:LinkableBoolean = new LinkableBoolean(true);
		
		public const dashboardMode:LinkableBoolean = new LinkableBoolean(false);	 // enable/disable borders/titleBar on windows
		
		public const enableFullscreen:LinkableBoolean = new LinkableBoolean(true); // enable/disable going fullscreen from Window menu
		
		public const enableAboutMenu:LinkableBoolean = new LinkableBoolean(true); //enable/disable About Menu
		
		public function get enableDebugAlert():LinkableBoolean { return DebugUtils.enableDebugAlert; } // show debug_trace strings in alert boxes
		public const showKeyTypeInColumnTitle:LinkableBoolean = new LinkableBoolean(false);
		
		// cosmetic options
		public const pageTitle:LinkableString = new LinkableString("Open Indicators Weave"); // title to show in browser window
		public const showCopyright:LinkableBoolean = new LinkableBoolean(true); // copyright at bottom of page

		// probing and selection
		public const selectionBlurringAmount:LinkableNumber = new LinkableNumber(4);
		public const selectionAlphaAmount:LinkableNumber    = new LinkableNumber(0.5, verifyAlpha);

		// dashed lines for the perimeter of the rectangle used for selection and zooming
		public const dashedSelectionBox:LinkableString = new LinkableString("5,5", verifyDashedSelectionBox);
		public function verifyDashedSelectionBox(csv:String):Boolean
		{
			if (csv === null) return false;
			
			var parser:CSVParser = new CSVParser();
			var rows:Array = parser.parseCSV(csv);
			
			if (rows.length == 0)
				return false;
			
			var values:Array = rows[0];
/*			if (values.length % 2 == 1) // length is odd with at least 1 element--push last element
			{
				var lastValue:String = values[values.length - 1];
				if (lastValue == 0)
					lastValue = 1;
				else
					lastValue = 0;
				
				values.push(lastValue);
			}
*/			
			var foundNonZero:Boolean = false;
			for (var i:int = 0; i < values.length; ++i)
			{
				var value:int = int(values[i]);
				if (isNaN(value)) return false;
				if (value < 0) return false;
				if (value != 0)
					foundNonZero = true;
			}
			
			return foundNonZero;
		}
		
		public const panelTitleFontColor:LinkableNumber = new LinkableNumber(0xffffff, isFinite);
		public const panelTitleFontSize:LinkableNumber = new LinkableNumber(10, verifyFontSize);
		public const panelTitleFontFamily:LinkableString = new LinkableString("Verdana");
		public const panelTitleFontBold:LinkableBoolean = new LinkableBoolean(false);
		public const panelTitleFontItalic:LinkableBoolean = new LinkableBoolean(false);
		public const panelTitleFontUnderline:LinkableBoolean = new LinkableBoolean(false);
				
		public const axisFontColor:LinkableNumber = new LinkableNumber(0x000000, isFinite);
		public const axisFontSize:LinkableNumber = new LinkableNumber(DEFAULT_AXIS_FONT_SIZE, verifyFontSize);
		public const axisFontFamily:LinkableString = new LinkableString(DEFAULT_FONT_FAMILY, verifyFontFamily);
		public const axisFontBold:LinkableBoolean = new LinkableBoolean(true);
		public const axisFontItalic:LinkableBoolean = new LinkableBoolean(false);
		public const axisFontUnderline:LinkableBoolean = new LinkableBoolean(false);
		
		public const probeInnerGlowColor:LinkableNumber = new LinkableNumber(0xffffff, isFinite);
		public const probeInnerGlowAlpha:LinkableNumber = new LinkableNumber(1, verifyAlpha);
		public const probeInnerGlowBlur:LinkableNumber = new LinkableNumber(5);
		public const probeInnerGlowStrength:LinkableNumber = new LinkableNumber(10);
		
		public const probeOuterGlowColor:LinkableNumber    = new LinkableNumber(0, isFinite);
		public const probeOuterGlowAlpha:LinkableNumber    = new LinkableNumber(1, verifyAlpha);
		public const probeOuterGlowBlur:LinkableNumber 	   = new LinkableNumber(3);
		public const probeOuterGlowStrength:LinkableNumber = new LinkableNumber(3);
		
		public const shadowDistance:LinkableNumber  = new LinkableNumber(2);
		public const shadowAngle:LinkableNumber    	= new LinkableNumber(45);
		public const shadowColor:LinkableNumber 	= new LinkableNumber(0x000000, isFinite);
		public const shadowAlpha:LinkableNumber 	= new LinkableNumber(0.5, verifyAlpha);
		public const shadowBlur:LinkableNumber 		= new LinkableNumber(4);
		
		public const probeToolTipBackgroundAlpha:LinkableNumber = new LinkableNumber(1.0, verifyAlpha);
		public const probeToolTipBackgroundColor:LinkableNumber = new LinkableNumber(NaN);
		public const probeToolTipFontColor:LinkableNumber = new LinkableNumber(0x000000, isFinite);
		
		public const enableProbeLines:LinkableBoolean = new LinkableBoolean(true);

		public const sessionStateEditor:LinkableString = new LinkableString("", verifySessionStateEditor);
		
		// temporary?
		public const rServiceURL:LinkableString = new LinkableString("/WeaveServices/RService"); // url of Weave R service
		
		//default URL
		public const searchServiceURLs:LinkableString = new LinkableString(WIKIPEDIA_URL+"\n"+GOOGLE_URL+"\n"+GOOGLE_IMAGES_URL+"\n"+GOOGLE_MAPS_URL);
		
		// when this is true, a rectangle will be drawn around the screen bounds with the background
		public const debugScreenBounds:LinkableBoolean = new LinkableBoolean(false);

		//--------------------------------------------
		// BACKWARDS COMPATIBILITY
		[Deprecated(replacement="panelTitleFontFamily")] public function get panelTitleFontStyle():LinkableString { return panelTitleFontFamily; }
		[Deprecated(replacement="dashboardMode")] public function get enableToolBorders():LinkableBoolean
		{
			var temp:LinkableBoolean = new LinkableBoolean();
			var callback:Function = function():void
			{
				dashboardMode.value = !temp.value;
				disposeObjects(temp);
			}
			return registerLinkableChild(this, temp, callback);
		}
		[Deprecated(replacement="dashboardMode")] public function get enableBorders():LinkableBoolean { return this['enableToolBorders']; }
		[Deprecated(replacement="enableSessionExport")] public function get enableExportSessionState():LinkableBoolean { return enableSessionExport; }
		[Deprecated(replacement="enableSessionBookmarks")] public function get enableSavePoint():LinkableBoolean { return enableSessionBookmarks; }
		[Deprecated(replacement="showProbeToolTipEditor")] public function get showProbeColumnEditor():LinkableBoolean { return showProbeToolTipEditor; }
		[Deprecated(replacement="enableAddWeaveDataSource")] public function get enableAddOpenIndicatorsDataSource():LinkableBoolean { return enableAddWeaveDataSource; }
		[Deprecated(replacement="enablePanelCoordsPercentageMode")] public function get enableToolAutoResizeAndPosition():LinkableBoolean { return enablePanelCoordsPercentageMode; }
		[Deprecated(replacement="rServiceURL")] public function get rServicesURL():LinkableString
		{
			var temp:LinkableString = new LinkableString();
			var callback:Function = function():void
			{
				if (temp.value != '/OpenIndicatorsDataServices')
					rServiceURL.value = temp.value + '/RService';
				disposeObjects(temp);
			};
			return registerLinkableChild(this, temp, callback);
		}
		//--------------------------------------------
	}
}
