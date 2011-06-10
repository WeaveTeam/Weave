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
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.StageDisplayState;
	import flash.errors.IllegalOperationError;
	import flash.events.ContextMenuEvent;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BevelFilter;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.LoaderContext;
	import flash.system.System;
	import flash.text.TextField;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.ui.MouseCursor;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import mx.binding.utils.BindingUtils;
	import mx.containers.HBox;
	import mx.containers.VDividedBox;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.HSlider;
	import mx.controls.Label;
	import mx.controls.ProgressBar;
	import mx.controls.ProgressBarLabelPlacement;
	import mx.controls.TabBar;
	import mx.controls.Text;
	import mx.controls.TextArea;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.ChildExistenceChangedEvent;
	import mx.events.FlexEvent;
	import mx.managers.CursorManagerPriority;
	import mx.managers.PopUpManager;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.skins.halo.HaloBorder;
	import mx.utils.ObjectUtil;
	
	import weave.KeySetContextMenuItems;
	import weave.Reports.WeaveReport;
	import weave.SearchEngineUtils;
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableDisplayObject;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.data.IDataSource;
	import weave.api.data.IProgressIndicator;
	import weave.api.data.IQualifiedKey;
	import weave.api.getCallbackCollection;
	import weave.api.getLinkableDescendants;
	import weave.api.getSessionState;
	import weave.api.newLinkableChild;
	import weave.api.services.IURLRequestUtils;
	import weave.api.setSessionState;
	import weave.compiler.StandardLib;
	import weave.core.DynamicState;
	import weave.core.ErrorManager;
	import weave.core.ExternalSessionStateInterface;
	import weave.core.LinkableBoolean;
	import weave.core.SessionManager;
	import weave.core.SessionStateLog;
	import weave.core.StageUtils;
	import weave.core.weave_internal;
	import weave.data.AttributeColumns.ColorColumn;
	import weave.data.AttributeColumns.FilteredColumn;
	import weave.data.AttributeColumns.KeyColumn;
	import weave.data.ColumnReferences.HierarchyColumnReference;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.KeySets.KeyFilter;
	import weave.data.KeySets.KeySet;
	import weave.primitives.AttributeHierarchy;
	import weave.services.DelayedAsyncResponder;
	import weave.services.LocalAsyncService;
	import weave.services.ProgressIndicator;	
	
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.AutoResizingTextArea;
	import weave.ui.ColorBinEditor;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.DatasetLoader;
	import weave.ui.DraggablePanel;
	import weave.ui.EquationEditor;
	import weave.ui.ErrorLogPanel;
	import weave.ui.ExportSessionStatePanel;
	import weave.ui.JRITextEditor;
	import weave.ui.MarkerSettingsComponent;
	import weave.ui.NewUserWizard;
	import weave.ui.OICLogoPane;
	import weave.ui.PenTool;
	import weave.ui.PrintPanel;
	import weave.ui.ProbeToolTipEditor;
	import weave.ui.RTextEditor;
	import weave.ui.SelectionManager;
	import weave.ui.SessionStateEditor;
	import weave.ui.SessionStatesDisplay;
	import weave.ui.SubsetManager;
	import weave.ui.WizardPanel;
	import weave.ui.annotation.SessionedTextBox;
	import weave.ui.controlBars.VisTaskbar;
	import weave.ui.controlBars.WeaveMenuBar;
	import weave.ui.controlBars.WeaveMenuItem;
	import weave.ui.editors.AddDataSourceComponent;
	import weave.ui.editors.EditDataSourceComponent;
	import weave.ui.settings.GlobalUISettings;
	import weave.ui.settings.InteractivitySubMenu;
	import weave.utils.BitmapUtils;
	import weave.utils.CSSUtils;
	import weave.utils.CustomCursorManager;
	import weave.utils.DebugUtils;
	import weave.utils.DrawUtils;
	import weave.utils.NumberUtils;
	import weave.visualization.tools.CollaborationTool;
	import weave.visualization.tools.ColorBinLegendTool;
	import weave.visualization.tools.CompoundBarChartTool;
	import weave.visualization.tools.CompoundRadVizTool;
	import weave.visualization.tools.DataTableTool;
	import weave.visualization.tools.DimensionSliderTool;
	import weave.visualization.tools.GaugeTool;
	import weave.visualization.tools.Histogram2DTool;
	import weave.visualization.tools.HistogramTool;
	import weave.visualization.tools.LineChartTool;
	import weave.visualization.tools.MapTool;
	import weave.visualization.tools.PieChartHistogramTool;
	import weave.visualization.tools.PieChartTool;
	import weave.visualization.tools.RadVizTool;
	import weave.visualization.tools.RamachandranPlotTool;
	import weave.visualization.tools.SP2;
	import weave.visualization.tools.ScatterPlotTool;
	import weave.visualization.tools.StickFigureGlyphTool;
	import weave.visualization.tools.ThermometerTool;
	import weave.visualization.tools.TimeSliderTool;
	import weave.visualization.tools.WeaveWordleTool;

	use namespace weave_internal;

	
	/**	
 	 * A class that extends Application to provide a workspace to add tools, handle setting of settings from files, etc.
	 * 
	 * @author abaumann
 	 */
	public class VisApplication extends Application implements ILinkableObject
	{
		MXClasses; // Referencing this allows all Flex classes to be dynamically created at runtime.

		{ /** BEGIN STATIC CODE BLOCK **/ 
			Weave.initialize(); // referencing this here causes all WeaveAPI implementations to be registered.
		} /** END STATIC CODE BLOCK **/ 
		
		/**
		 * Global VisApplication instance
		 */
		private static var _thisInstance:VisApplication = null;
		/**
		 * Gets the global VisApplication instance.
		 */
		public static function get instance():VisApplication
		{
			return _thisInstance;
		}

		/**
		 * Optional menu bar (top of the screen) and task bar (bottom of the screen).  These would be used for an advanced analyst
		 * view to add new tools, manage windows, do advanced tasks, etc.
		 */
		private var _weaveMenu:WeaveMenuBar = null;
		
		/**
		 * The XML file that defines the default layout of the page if no parameter is passed that specifies another file to use
		 */
		private var _configFileXML:XML = null;
		
		/**
		 * This will be used to incorporate branding into any weave view.  Linkable to the Open Indicators Consortium website.
		 */
		private var _oicLogoPane:OICLogoPane = new OICLogoPane();

		/**
		 * Constructor.
		 */
		public function VisApplication()
		{
			super();
			this.setStyle('backgroundColor',Weave.properties.backgroundColor.value);
			this.pageTitle = "Open Indicators Weave";

			visDesktop = new VisDesktop();
			
			// resize to parent size each frame because percentWidth,percentHeight doesn't seem reliable when application is nested
			addEventListener(Event.ENTER_FRAME, function(..._):*{
				if (!parent)
					return;
				
				width = parent.width;
				height = parent.height;
			}, true);
			
			getCallbackCollection(WeaveAPI.ErrorManager).addGroupedCallback(this, ErrorLogPanel.openErrorLog);
			
			Weave.root.childListCallbacks.addImmediateCallback(this, handleWeaveListChange);
			
			_thisInstance = this;
			
			setStyle("paddingLeft", 0);
			setStyle("paddingRight", 0);
			setStyle("paddingTop", 0);
			setStyle("paddingBottom", 0);
			
			setStyle("marginLeft", 0);
			setStyle("marginRight", 0);
			setStyle("marginTop", 0);
			setStyle("marginBottom", 0);
			
			setStyle("verticalGap", 0);
			setStyle("horizingalGap", 0);

			// default has menubar and taskbar unless specified otherwise in config file
			Weave.properties.enableMenuBar.addGroupedCallback(this, toggleMenuBar);
			Weave.properties.enableTaskbar.addGroupedCallback(this, toggleTaskBar, true);
			
			Weave.properties.pageTitle.addGroupedCallback(this, updatePageTitle);
			
			this.autoLayout = true;
			
			// no scrolling -- need to make "workspaces" you can switch between
			this.horizontalScrollPolicy = "off";
			this.verticalScrollPolicy   = "off";
			
			visDesktop.verticalScrollPolicy   = "off";
			visDesktop.horizontalScrollPolicy = "off";
			
			getCallbackCollection(Weave.root.getObject(Weave.SAVED_SELECTION_KEYSETS)).addGroupedCallback(this, setupSelectionsMenu);
			getCallbackCollection(Weave.root.getObject(Weave.SAVED_SUBSETS_KEYFILTERS)).addGroupedCallback(this, setupSubsetsMenu);

			this.addEventListener(FlexEvent.APPLICATION_COMPLETE, setupConnection );
			
			getCallbackCollection(Weave.properties).addGroupedCallback(this, setupVisMenuItems);
			
			Weave.properties.enableExportToolImage.addGroupedCallback(this, setupContextMenu);
			Weave.properties.dataInfoURL.addGroupedCallback(this, setupContextMenu);
			Weave.properties.enableSubsetControls.addGroupedCallback(this, setupContextMenu);
			Weave.properties.enableRightClick.addGroupedCallback(this, setupContextMenu);
			Weave.properties.enableAddDataSource.addGroupedCallback(this, setupContextMenu);
			Weave.properties.enableEditDataSource.addGroupedCallback(this, setupContextMenu);
			Weave.properties.backgroundColor.addGroupedCallback(this, handleBackgroundColorChange, true);
		}

		/**
		 * This needed to be a function because FlashVars can't be fetched till the application loads.
		 */
		private function setupConnection( e:FlexEvent ):void
		{
			getFlashVars();
			if (getFlashVarConnectionName() != null)
			{
				// disable interface until connected to admin console
				var _this:VisApplication = this;
				_this.enabled = false;
				var errorHandler:Function = function(..._):void
				{
					Alert.show("Unable to connect to the Admin Console.\nYou will not be able to save your session state to the server.", "Connection error");
					_this.enabled = true;
				};
				var pendingAdminService:LocalAsyncService = new LocalAsyncService(this, false, getFlashVarConnectionName());
				pendingAdminService.errorCallbacks.addGroupedCallback(this, errorHandler);
				// when admin console responds, set adminService
				DelayedAsyncResponder.addResponder(
					pendingAdminService.invokeAsyncMethod("ping"),
					function(..._):*
					{
						//Alert.show("Connected to Admin Console");
						_this.enabled = true;
						adminService = pendingAdminService;
						toggleMenuBar();
						StageUtils.callLater(this,setupVisMenuItems,null,false);
					},
					errorHandler
				);
			}
			loadPage();
		}
		
		private function handleBackgroundColorChange():void
		{
			VisApplication.instance.setStyle("backgroundGradientColors", [Weave.properties.backgroundColor.value, Weave.properties.backgroundColor.value]);
		}
		
		/**
		 * The desktop is the entire viewable area minus the space for the optional menu bar and taskbar
		 */
		public var visDesktop:VisDesktop = null;

		/**
		 * The mapping for the flash vars.
		 */
		private var _flashVars:Object;
		private function getFlashVarConnectionName():String
		{
			return _flashVars['adminSession'] as String;
		}

		/**
		 * Gets the name of the config file.
		 */
		private function getFlashVarConfigFileName():String
		{
			if (_flashVars[CONFIG_FILE_FLASH_VAR_NAME] == undefined)
				return null;
			
			return unescape(_flashVars[CONFIG_FILE_FLASH_VAR_NAME] as String);
		}
		
		/**
		 * @return true, false, or undefined depending what the 'editable' FlashVar is set to.
		 */
		private function getFlashVarEditable():*
		{
			var name:String = 'editable';
			if (_flashVars.hasOwnProperty(name))
				return StandardLib.asBoolean(_flashVars['editable'] as String);
			return undefined;
		}
		
		/**
		 * Gets the flash vars.
		 */
		private function getFlashVars():void
		{
			// We want FlashVars to take priority over the address bar parameters.
			_flashVars = LoaderInfo(this.root.loaderInfo).parameters;
			
			// check address bar for any variables not found in FlashVars
			try
			{
				var urlParams:URLVariables = new URLVariables(ExternalInterface.call("window.location.search.substring", 1)); // text after '?'
				for (var key:String in urlParams)
					if (!_flashVars.hasOwnProperty(key))
						_flashVars[key] = urlParams[key];
				// backwards compatibility with old param name
				if (!_flashVars.hasOwnProperty(CONFIG_FILE_FLASH_VAR_NAME) && urlParams.hasOwnProperty('defaults'))
					_flashVars[CONFIG_FILE_FLASH_VAR_NAME] = urlParams['defaults'];
			}
			catch(e:Error) { }
		}
		public const CONFIG_FILE_FLASH_VAR_NAME:String = 'file';

		private function get _applicationVBox():Application { return application as Application; }
		
		private var _maxProgressBarValue:int = 0;
		private var _progressBar:ProgressBar = new ProgressBar;
		private function handleProgressIndicatorCounterChange():void
		{
			var pendingCount:int = WeaveAPI.ProgressIndicator.getTaskCount();
			var tempString:String = pendingCount + " Pending Request" + (pendingCount == 1 ? '' : 's');
			
			_progressBar.label = tempString;

			if (pendingCount == 0)				// hide progress bar and text area
			{
				_progressBar.visible = false;
				_progressBar.setProgress(0, 1); // reset progress bar
				
				_maxProgressBarValue = 0;
			}
			else								// display progress bar and text area
			{
				if (visDesktop.visible == false)
					return;
				
				_progressBar.alpha = .8;
				
				if (pendingCount > _maxProgressBarValue)
					_maxProgressBarValue = pendingCount;
				
				_progressBar.setProgress(WeaveAPI.ProgressIndicator.getNormalizedProgress(), 1); // progress between 0 and 1
				_progressBar.visible = true;
			}
			
		}
		
		private var _selectionIndicatorText:Text = new Text;
		private var selectionKeySet:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
		private function handleSelectionChange():void
		{
			_selectionIndicatorText.text = selectionKeySet.keys.length.toString() + " Records Selected";
			try
			{
				if (selectionKeySet.keys.length == 0)
				{
					if (visDesktop == _selectionIndicatorText.parent)
						visDesktop.removeChild(_selectionIndicatorText);
				}
				else
				{
					if (visDesktop != _selectionIndicatorText.parent)
						visDesktop.addChild(_selectionIndicatorText);
				}
			}
			catch (e:Error) { }
		}
		
		override protected function createChildren():void
		{
			super.createChildren();
			
			_applicationVBox.addChild(visDesktop);
			visDesktop.percentWidth = 100;
			visDesktop.percentHeight = 100;

			// Code for selection indicator
			getCallbackCollection(selectionKeySet).addGroupedCallback(this, handleSelectionChange, true);
			_selectionIndicatorText.setStyle("color", 0xFFFFFF);
			_selectionIndicatorText.opaqueBackground = 0x000000;
			_selectionIndicatorText.setStyle("bottom", 0);
			_selectionIndicatorText.setStyle("right", 0);
			
			getCallbackCollection(WeaveAPI.ProgressIndicator).addGroupedCallback(this, handleProgressIndicatorCounterChange, true);
			visDesktop.addChild(_progressBar);
			_progressBar.visible = false;
			_progressBar.x = 0;
			_progressBar.setStyle("bottom", 0);
			_progressBar.setStyle("trackHeight", 16); //TODO: global UI setting instead of 12?
			_progressBar.setStyle("borderColor", 0x000000);
			_progressBar.setStyle("color", 0xFFFFFF); //color of text
			_progressBar.setStyle("barColor", "haloBlue");
			_progressBar.setStyle("trackColors", [0x000000, 0x000000]);
			_progressBar.labelPlacement = ProgressBarLabelPlacement.CENTER;
			_progressBar.label = '';
			_progressBar.mode = "manual"; 
			_progressBar.minHeight = 16;
			_progressBar.minWidth = 135; // constant

			Weave.properties.backgroundColor.value = getStyle("backgroundColor");
			
			visDesktop.addEventListener(ChildExistenceChangedEvent.CHILD_REMOVE, function(e:Event):void { setupWindowMenu() } );
		}

		private var adminService:LocalAsyncService = null;
		
		
		private var sessionStates:Array = new Array();	//Where the session states are stored.
		private var sessionCount:int = 0;
		private var sessionTotal:int = 0;				//For naming purposes.
		
		private function saveAction():void{
			
			var dynObject:DynamicState = new DynamicState();
			
			sessionTotal++;
			sessionCount = sessionStates.length;
			dynObject.sessionState = getSessionState(Weave.root);
			dynObject.objectName = "Weave Session State " + ( sessionTotal + 1 );
			sessionStates[sessionCount] = dynObject;
			
		}
		
		private function copySessionStateToClipboard():void
		{
			System.setClipboard(Weave.getSessionStateXML().toXMLString());
		}
		
		private function saveSessionStateToServer():void
		{
			var fileSaveDialogBox:AlertTextBox;
			fileSaveDialogBox = PopUpManager.createPopUp(this,AlertTextBox) as AlertTextBox;
			fileSaveDialogBox.textInput = getFlashVarConfigFileName();
			fileSaveDialogBox.title = "Save File";
			fileSaveDialogBox.message = "Save current Session State to server?";
			fileSaveDialogBox.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, handleFileSaveClose);
			PopUpManager.centerPopUp(fileSaveDialogBox);
		}
		
		private function handleFileSaveClose(event:AlertTextBoxEvent):void
		{
			if (event.confirm)
				savePreviewSessionState(event.textInput);
		}
		
		private function savePreviewSessionState(fileName:String):void
		{
			if (adminService == null)
			{
				Alert.show("Not connected to Admin Console.\nSession State was not saved.", "Error");
				return;
			}
			
			// temporarily disable sessioning so config saved to server has sessioning disabled.
			_disableSetupVisMenuItems = true; // stop the session settings from changing the vis menu
			Weave.properties.enableSessionMenu.value = false;
			Weave.properties.enableSessionEdit.value = false;
			
			var token:AsyncToken = adminService.invokeAsyncMethod(
					'saveWeaveFile',
					[Weave.getSessionStateXML().toXMLString(), fileName, true]
				);
			token.addResponder(new DelayedAsyncResponder(
					function(event:ResultEvent, token:Object = null):void
					{
						Alert.show(String(event.result), "Admin Console Response");
					},
					function(event:FaultEvent, token:Object = null):void
					{
						Alert.show(event.fault.message, event.fault.name);
					},
					null
				));
			
			Weave.properties.enableSessionMenu.value = true;
			Weave.properties.enableSessionEdit.value = true;
			_disableSetupVisMenuItems = false;
			setupVisMenuItems();
		}
		
		// this function may be called by the Admin Console to close this window
		public function closeWeavePopup():void
		{
			ExternalInterface.call("window.close()");
		}

		private function toggleMenuBar():void
		{
			DraggablePanel.showRollOverBorders = adminService || getFlashVarEditable();
			if (Weave.properties.enableMenuBar.value || adminService || getFlashVarEditable())
			{
				if (!_weaveMenu)
				{
					_weaveMenu = new WeaveMenuBar();

					//trace("MENU BAR ADDED");
					_weaveMenu.percentWidth = 100;
					StageUtils.callLater(this,setupVisMenuItems,null,false);
					
					_applicationVBox.addChildAt(_weaveMenu, 0);
					
					if (_applicationVBox == _oicLogoPane.parent)
						_applicationVBox.removeChild(_oicLogoPane);
				}
				
				// always show menu bar when admin service is present
				_weaveMenu.alpha = Weave.properties.enableMenuBar.value ? 1.0 : 0.3;
			}
			// otherwise there is no menu bar, (which normally includes the oiclogopane, so add one to replace it)
			else
			{
				try
				{
		   			if (_weaveMenu && _applicationVBox == _weaveMenu.parent)
						_applicationVBox.removeChild(_weaveMenu);

		   			_weaveMenu = null;
					
					_applicationVBox.addChildAt(_oicLogoPane, _applicationVBox.numChildren);
					_applicationVBox.setStyle("horizontalAlign", "right");
				}
				catch(error:Error)
				{
					trace(error.getStackTrace());
				}
			}
		}
		
		private var _dataMenu:WeaveMenuItem  = null;
		private var _exportMenu:WeaveMenuItem  = null;
		private var _sessionMenu:WeaveMenuItem = null;
		private var _toolsMenu:WeaveMenuItem   = null;
		private var _windowMenu:WeaveMenuItem  = null;
		private var _selectionsMenu:WeaveMenuItem = null;
		private var _subsetsMenu:WeaveMenuItem = null;
		private var _aboutMenu:WeaveMenuItem   = null;

		private var _disableSetupVisMenuItems:Boolean = false; // this flag disables the setupVisMenuItems() function temporarily while true
		
		private function setupVisMenuItems():void
		{
			if (_disableSetupVisMenuItems)
				return;
			
			if (!_weaveMenu)
				return;
			
			_weaveMenu.validateNow();
			
			//TEMPORARY SOLUTION -- enable sessioning if loaded through admin console
			if (!Weave.properties.enableSessionMenu.value || !Weave.properties.enableSessionEdit.value)
			{
				if (adminService != null)
				{
					Weave.properties.enableSessionMenu.value = true;
					Weave.properties.enableSessionEdit.value = true;
				}
			}
			
			_weaveMenu.removeAllMenus();
			
			if (Weave.properties.enableDataMenu.value)
			{
				_dataMenu = _weaveMenu.addMenuToMenuBar("Data", false);
				_weaveMenu.addMenuItemToMenu(_dataMenu,
					new WeaveMenuItem("Refresh all data source hierarchies",
						function ():void {
							var sources:Array = Weave.root.getObjects(IDataSource);
							for each (var source:IDataSource in sources)
								(source.attributeHierarchy as AttributeHierarchy).value = null;
						},
						null,
						function():Boolean { return Weave.properties.enableRefreshHierarchies.value }
					)
				);

				if(Weave.properties.enableAddDataSource.value)
					_weaveMenu.addMenuItemToMenu(_dataMenu,new WeaveMenuItem("Add New Datasource",AddDataSourceComponent.showAsPopup));
				
				if(Weave.properties.enableEditDataSource.value)
					_weaveMenu.addMenuItemToMenu(_dataMenu,new WeaveMenuItem("Edit Datasources",EditDataSourceComponent.showAsPopup));
			}
			
			
			if (Weave.properties.enableExportToolImage.value)
			{
				_exportMenu = _weaveMenu.addMenuToMenuBar("Export", false);
				if (Weave.properties.enableExportApplicationScreenshot.value)
					_weaveMenu.addMenuItemToMenu(_exportMenu, new WeaveMenuItem("Save or Print Application Screenshot...", printOrExportImage, [this]));
			}
			
			if (Weave.properties.enableDynamicTools.value)
			{
				_toolsMenu = _weaveMenu.addMenuToMenuBar("Tools", false);

				createToolMenuItem(Weave.properties.showColorController, "Show Color Controller", ColorBinEditor.openDefaultEditor);
				createToolMenuItem(Weave.properties.showProbeToolTipEditor, "Show Probe ToolTip Editor", ProbeToolTipEditor.openDefaultEditor );
				createToolMenuItem(Weave.properties.showEquationEditor, "Show Equation Editor", createGlobalObject, [EquationEditor, "EquationEditor"]);
				createToolMenuItem(Weave.properties.showAttributeSelector, "Show Attribute Selector", AttributeSelectorPanel.openDefaultSelector);
				
				createToolMenuItem(Weave.properties.enableNewUserWizard, "New User Wizard", function():void {
					var userUI:NewUserWizard = new NewUserWizard();
					WizardPanel.createWizard(instance,userUI);
				});
				createToolMenuItem(Weave.properties.enableAddTimeSliderTool, "Add Collaboration Tool", createGlobalObject, [CollaborationTool, "CollaborationTool"]);

				_weaveMenu.addSeparatorToMenu(_toolsMenu);
				
				createToolMenuItem(Weave.properties.enableAddBarChart, "Add Bar Chart", createGlobalObject, [CompoundBarChartTool]);
				createToolMenuItem(Weave.properties.enableAddColormapHistogram, "Add Color Histogram", createColorHistogram);
				createToolMenuItem(Weave.properties.enableAddColorLegend, "Add Color Legend", createGlobalObject, [ColorBinLegendTool]);
				createToolMenuItem(Weave.properties.enableAddCompoundRadViz, "Add CompoundRadViz", createGlobalObject, [CompoundRadVizTool]);
				createToolMenuItem(Weave.properties.enableAddDataTable, "Add Data Table", createGlobalObject, [DataTableTool]);
				createToolMenuItem(Weave.properties.enableAddDimensionSliderTool, "Add Dimension Slider Tool", createGlobalObject, [DimensionSliderTool]);
				createToolMenuItem(Weave.properties.enableAddGaugeTool, "Add Gauge Tool", createGlobalObject, [GaugeTool]);
				createToolMenuItem(Weave.properties.enableAddHistogram, "Add Histogram", createGlobalObject, [HistogramTool]);
				createToolMenuItem(Weave.properties.enableAdd2DHistogram, "Add 2D Histogram", createGlobalObject, [Histogram2DTool]);
				createToolMenuItem(Weave.properties.enableAddRScriptEditor, "Add JRI Script Editor", createGlobalObject, [JRITextEditor]);
				createToolMenuItem(Weave.properties.enableAddLineChart, "Add Line Chart", createGlobalObject, [LineChartTool]);
				createToolMenuItem(Weave.properties.enableAddMap, "Add Map", createGlobalObject, [MapTool]);
				createToolMenuItem(Weave.properties.enableAddPieChart, "Add Pie Chart", createGlobalObject, [PieChartTool]);
				createToolMenuItem(Weave.properties.enableAddPieChartHistogram, "Add Pie Chart Histogram", createGlobalObject, [PieChartHistogramTool]);
				createToolMenuItem(Weave.properties.enableAddRScriptEditor, "Add R Script Editor", createGlobalObject, [RTextEditor]);
				createToolMenuItem(Weave.properties.enableAddRadViz, "Add RadViz", createGlobalObject, [RadVizTool]);
				createToolMenuItem(Weave.properties.enableAddRamachandranPlot, "Add RamachandranPlot", createGlobalObject, [RamachandranPlotTool]);
				createToolMenuItem(Weave.properties.enableAddScatterplot, "Add Scatterplot", createGlobalObject, [ScatterPlotTool]);
				createToolMenuItem(Weave.properties.enableAddThermometerTool, "Add Thermometer Tool", createGlobalObject, [ThermometerTool]);
				createToolMenuItem(Weave.properties.enableAddTimeSliderTool, "Add Time Slider Tool", createGlobalObject, [TimeSliderTool]);	
			}
			
			if (Weave.properties.enableSelectionsMenu.value)
			{	
				_selectionsMenu = _weaveMenu.addMenuToMenuBar("Selections", true);
				setupSelectionsMenu();
			}
			
			if (Weave.properties.enableSubsetsMenu.value)
			{	
				_subsetsMenu = _weaveMenu.addMenuToMenuBar("Subsets", true);
				setupSubsetsMenu();
			}
			
			
			if (Weave.properties.enableSessionMenu.value)
			{
				_sessionMenu = _weaveMenu.addMenuToMenuBar("Session", false);
				
				if (Weave.properties.enableSessionBookmarks.value)
				{
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Create session state save point", saveAction));
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Show saved session states", SessionStatesDisplay.openDefaultEditor, [sessionStates]));
				}
				
				_weaveMenu.addSeparatorToMenu(_sessionMenu);
				
				if (Weave.properties.enableSessionEdit.value)
				{
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Edit session state", SessionStateEditor.openDefaultEditor));
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Copy session state to clipboard", copySessionStateToClipboard));
					
					_weaveMenu.addSeparatorToMenu(_sessionMenu);
					
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Import session state ...", handleImportSessionState));
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Export session state...", handleExportSessionState));
				}

				_weaveMenu.addSeparatorToMenu(_sessionMenu);

				if (adminService)
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Save session state to server", saveSessionStateToServer));
				
				_weaveMenu.addSeparatorToMenu(_sessionMenu);
				
				if (Weave.properties.enableUserPreferences.value)
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("User interface preferences", GlobalUISettings.openGlobalEditor));
			}
			
			if (Weave.properties.enableWindowMenu.value)
			{	
				_windowMenu = _weaveMenu.addMenuToMenuBar("Window", true);
				setupWindowMenu();
			}
			
			if (Weave.properties.enableAboutMenu.value)
			{
				_aboutMenu = _weaveMenu.addMenuToMenuBar("About", false);
				
				_weaveMenu.addMenuItemToMenu(_aboutMenu, new WeaveMenuItem("Weave Version: " + Weave.properties.version.value));
				
				_weaveMenu.addMenuItemToMenu(_aboutMenu, new WeaveMenuItem("Visit http://www.openindicators.org", function ():void {
					navigateToURL(new URLRequest("http://www.openindicators.org"), "_blank");
				}));
			}
		}
		
		private function createToolMenuItem(toggle:LinkableBoolean, title:String, callback:Function, params:Array = null):void
		{
			if (toggle.value)
				_weaveMenu.addMenuItemToMenu(_toolsMenu, new WeaveMenuItem(title, callback, params));
		}
		
		private function toggleTaskBar():void
		{
			if (Weave.properties.enableTaskbar.value)
			{
				VisTaskbar.instance.percentWidth = 100;
					
				// The task bar should be at the bottom of the page
				if (!VisTaskbar.instance.parent)
				{
					addChild(VisTaskbar.instance);
//					PopUpManager.addPopUp(_visTaskbar, this);
				}
			}
			else
			{
				VisTaskbar.instance.restoreAllComponents();

				if (VisTaskbar.instance.parent)
				{
					removeChild(VisTaskbar.instance);
//					PopUpManager.removePopUp(_visTaskbar);
				}
			}
		}
		
		private var _alreadyLoaded:Boolean = false;
		private var _configFileName:String = null;
		/**
		 * This function will load all the tools, settings, etc
		 *
 		 * @author abaumann
		 */
		private function loadPage():void
		{
			// We only want to do this page loading once
			if (_alreadyLoaded)
				return;
			
			if (!getFlashVarConnectionName())
				enabled = false;
			
			// Name for the file that defines layout and tool settings.  This is extracted from a parameter passed to the HTML page.
			_configFileName = getFlashVarConfigFileName(); 	
	
			if (_configFileName == null)
			{
				_configFileName = "defaults.xml";
			}
			
			var noCacheHack:String = "?" + (new Date()).getTime(); // prevent flex from using cache
		
			WeaveAPI.URLRequestUtils.getURL(new URLRequest(_configFileName + noCacheHack), handleConfigFileDownloaded, handleConfigFileFault);
			
			_alreadyLoaded = true;
		}
		
		private var _stateLoaded:Boolean = false;
		private function loadSessionState(state:XML):void
		{
			_configFileXML = state;
			var i:int = 0;
			
			StageUtils.callLater(this,toggleMenuBar,null,false);
			
			if (!getFlashVarConnectionName())
				enabled = true;
			
			// backwards compatibility:
			var stateStr:String = state.toXMLString();
			while (stateStr.indexOf("org.openindicators") >= 0)
			{
				stateStr = stateStr.replace("org.openindicators", "weave");
				state = XML(stateStr);
			}
			var tag:XML;
			for each (tag in state.descendants("OpenIndicatorsServletDataSource"))
				tag.setLocalName("WeaveDataSource");
			for each (tag in state.descendants("OpenIndicatorsDataSource"))
				tag.setLocalName("WeaveDataSource");
			for each (tag in state.descendants("WMSPlotter2"))
				tag.setLocalName("WMSPlotter");
			for each (tag in state.descendants("SessionedTextArea"))
			{
				tag.setLocalName("SessionedTextBox");
				tag.appendChild(<enableBorders>true</enableBorders>);
				tag.appendChild(<htmlText>{tag.textAreaString.text()}</htmlText>);
				tag.appendChild(<panelX>{tag.textAreaWindowX.text()}</panelX>);
				tag.appendChild(<panelY>{tag.textAreaWindowY.text()}</panelY>);
			}
			
			// add missing attribute titles
			for each (var hierarchy:XML in _configFileXML.descendants('hierarchy'))
				for each (tag in hierarchy.descendants("attribute"))
					if (!String(tag.@title) && tag.@name)
						tag.@title = tag.@name;

			Weave.setSessionStateXML(_configFileXML, true);
			fixCommonSessionStateProblems();

			if (_weaveMenu && _toolsMenu)
			{
				var reportsMenuItems:Array = getReportsMenuItems();
				if (reportsMenuItems.length > 0)
				{
					_weaveMenu.addSeparatorToMenu(_toolsMenu);
					
					for each(var reportMenuItem:WeaveMenuItem in reportsMenuItems)
					{
						_weaveMenu.addMenuItemToMenu(_toolsMenu, reportMenuItem);
					}
				}	
			}
			
			// handle dynamic changes to the session state that change what CSS file to use
			Weave.properties.cssStyleSheetName.addGroupedCallback(
				this,
				function():void
				{
					CSSUtils.loadStyleSheet(Weave.properties.cssStyleSheetName.value);
				},
				true
			);

			// generate the context menu items
			setupContextMenu();

			// Set the name of the CSS style we will be using for this application.  If weaveStyle.css is present, the style for
			// this application can be defined outside the code in a CSS file.
			this.styleName = "application";	
			
			_stateLoaded = true;
			
			//Sets the initial session state for an undo.
			var dynamicSess:DynamicState = new DynamicState();
			dynamicSess.sessionState = getSessionState(Weave.root);	
			dynamicSess.objectName = "Weave Session State 1";
			
			sessionStates[0] = dynamicSess;
		}
		
		/**
		 * This function will fix common problems that appear in saved session states.
		 */
		private function fixCommonSessionStateProblems():void
		{
			// An empty subset is not of much use.  If the subset is empty, reset it to include all records.
			var subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
			if (subset.includeMissingKeys.value == false && subset.included.keys.length == 0 && subset.excluded.keys.length == 0)
				subset.includeMissingKeys.value = true;
		}
		
		private function handleWeaveListChange():void
		{
			if (Weave.root.childListCallbacks.lastObjectAdded is DraggablePanel)
				StageUtils.callLater(this,setupWindowMenu,null,false); // add panel to menu items
		}
		
		private function createColorHistogram():void
		{
			var name:String = Weave.root.generateUniqueName("ColorHistogramTool");
			var colorHistogram:HistogramTool = createGlobalObject(HistogramTool, name);
			colorHistogram.plotter.dynamicColorColumn.globalName = Weave.DEFAULT_COLOR_COLUMN;
		}
		
		private function createGlobalObject(classDef:Class, name:String = null):*
		{
			var className:String = getQualifiedClassName(classDef).split("::")[1];

			if (name == null)
				name = Weave.root.generateUniqueName(className);
			var object:* = Weave.root.requestObject(name, classDef, false);
			if (object is DraggablePanel)
				(object as DraggablePanel).restorePanel();
			// put panel in front
			Weave.root.setNameOrder([name]);

			return object;
		}
		
		private function setupSelectionsMenu():void
		{
			if (_weaveMenu && _selectionsMenu)
				SelectionManager.setupMenu(_weaveMenu, _selectionsMenu);
		}
		private function setupSubsetsMenu():void
		{
			if (_weaveMenu && _subsetsMenu)
				SubsetManager.setupMenu(_weaveMenu, _subsetsMenu);
		}

		private function get topPanel():DraggablePanel
		{
			var children:Array = Weave.root.getObjects(DraggablePanel);
			while (children.length)
			{
				var panel:DraggablePanel = children.pop() as DraggablePanel;
				if (panel.visible)
					return panel;
			}
			
			return null;
		}
		
		private function setupWindowMenu():void
		{
			if (!(_weaveMenu && _windowMenu && Weave.properties.enableWindowMenu.value))
				return;
			
			if (_windowMenu.children)
				_windowMenu.children.removeAll();
			
			
			var label:*;
			var click:Function;
			var enable:*;
			
			// minimize
			label = "Minimize This Window";
			click = function():void {
					if (topPanel)
						topPanel.minimizePanel();
				};
			enable = function():Boolean {
					return (topPanel && topPanel.minimizable.value);
				};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem(label, click, null, enable) );
			
			
			// maximize/restore
			label = function():String { 
					if ( topPanel && topPanel.maximized.value) 
						return 'Restore Panel Size'; 
					return 'Maximize This Window';
				};
			click = function():void { 
			    	if (topPanel)
			    		topPanel.toggleMaximized();
			    };
			enable = function():Boolean {
					return (topPanel && topPanel.maximizable.value);
				};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem(label, click, null, enable));
			
			// close
			click = function():void { 
				if (topPanel)
					topPanel.removePanel();
			};
			enable = function():Boolean {
				return (topPanel && topPanel.closeable.value);
			};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Close This Window", click, null, enable));
				
			// Minimize All Windows: Get a list of all panels and call minimizePanel() on each sequentially
			click = function():void {
				for each (panel in Weave.root.getObjects(DraggablePanel))
					panel.minimizePanel();
			};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Minimize All Windows", click, null, Weave.properties.enableMinimizeAllWindows.value) );
			
			// Restore all minimized windows: Get a list of all panels and call restorePanel() on each sequentially
			click = function():void {
				for each (panel in Weave.root.getObjects(DraggablePanel))
					panel.restorePanel();
			};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Restore All Mimimized Windows", click, null, Weave.properties.enableRestoreAllMinimizedWindows.value ));
			
			// Close All Windows: Get a list of all panels and call removePanel() on each sequentially
			click = function():void {
				for each (panel in Weave.root.getObjects(DraggablePanel))
					panel.removePanel();
			};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Close All Windows", click, null, Weave.properties.enableCloseAllWindows.value));
			
			// cascade windows
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Cascade All Windows", cascadeWindows, null, Weave.properties.enableCascadeAllWindows.value ));
			
			// tile windows
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Tile All Windows", tileWindows, null, Weave.properties.enableTileAllWindows.value ));
			
			
			label = function():String {
				if ( stage && stage.displayState == StageDisplayState.FULL_SCREEN) 
					return 'Exit Fullscreen'; 
				
				return 'Go Fullscreen';
			};
			click = function():void{
				if (stage && stage.displayState == StageDisplayState.NORMAL )
				{
					// set full screen display
					stage.displayState = StageDisplayState.FULL_SCREEN;
				}
				else if (stage)
				{
					// set normal display
					stage.displayState = StageDisplayState.NORMAL;
				}
			};
			_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem(label, click, null, Weave.properties.enableGoFullscreen.value));
			_weaveMenu.addSeparatorToMenu(_windowMenu);

			var panels:Array = Weave.root.getObjects(DraggablePanel);
			for (var i:int = 0; i < panels.length; i++)
			{	
				var panel:DraggablePanel = panels[i] as DraggablePanel;
				var newToolMenuItem:WeaveMenuItem = createWindowMenuItem(panel, _weaveMenu, _windowMenu);
				if (_weaveMenu)
					_weaveMenu.addMenuItemToMenu(_windowMenu, newToolMenuItem);
			}
		}
		
		private function createWindowMenuItem(panel:DraggablePanel, destinationMenuBar:WeaveMenuBar, destinationMenuItem:WeaveMenuItem):WeaveMenuItem
		{
			var label:Function = function():String
			{
				var menuLabel:String = "untitled ";
				if(panel.title && panel.title.replace(" ", "").length > 0) 
					menuLabel = panel.title;
				else
					menuLabel += " window";
				
				
				if(panel.minimized.value)
				{
					menuLabel = ">\t" + menuLabel;
				}
				
				return menuLabel;
			}
			var click:Function = function():void
			{
		   		if (panel.minimizedComponentVersion != null)
		   			panel.minimizedComponentVersion.restoreFunction();
		   		else
					panel.restorePanel();
			}
			var newToolMenuItem:WeaveMenuItem = new WeaveMenuItem(label, click);
			 
			newToolMenuItem.type = WeaveMenuItem.TYPE_RADIO;
			newToolMenuItem.groupName = "activeWindows";
			newToolMenuItem.toggledFunction = function ():Boolean {
				return newToolMenuItem.relevantItemPointer == topPanel;
			};
			newToolMenuItem.relevantItemPointer = panel;
			
			addEventListener(FlexEvent.REMOVE, function(e:Event):void {
				if(destinationMenuBar && destinationMenuItem)
					destinationMenuBar.removeMenuItemFromMenu(newToolMenuItem, destinationMenuItem);
			});
										
			return newToolMenuItem;
		}

		/**
		 * Handle a file fault when trying to download the config file -- for now, this just pops up a window showing that the file could not be downloaded.
		 */
		private function handleConfigFileFault(event:FaultEvent, token:Object = null):void
		{
			//if connection name exists then user might be creating a new config file.
			if (getFlashVarConnectionName() == '' || getFlashVarConnectionName() == null)
			{
				Alert.show("Missing client config file.  Please provide a defaults.xml file that specifies what to show in this situation.", "Missing Config File");
			}		
		}

		/**
		 * This function arranges all DraggablePanels along a diagonal
		 * 
		 * @author kmanohar
		 */
		private function cascadeWindows():void
		{
			var panels:Array = getWindowsOnStage();
			if(!panels.length) return;			
			
			var increment:Number = 50/panels.length;
			var dist:Number = 0 ;
			
			for each( var dp:DraggablePanel in panels)
			{				
				dp.panelX.value = dp.panelY.value = dist.toString()+"%";			
				dp.panelHeight.value = dp.panelWidth.value = "50%" ;	
				
				dist += increment;
			}
		}
		
		/**
		 * This function tiles all the DraggablePanels on stage
		 * 
		 * @TODO create a ui for this so the user can specify how to divide the stage
		 * 
		 * @author kmanohar
		 */		
		private function tileWindows():void
		{
			var panels:Array = getWindowsOnStage();
 			var numPanels:uint = panels.length;
			if(!numPanels) return;
			
			var gridLength:Number = Math.ceil(Math.sqrt(numPanels));
			
			var rows:uint = gridLength; 
			var columns:uint = gridLength;
			
			if(gridLength*gridLength != numPanels)
			{	
				rows = Math.round(Math.sqrt(numPanels));
				columns = gridLength;
			}			
						
			var xPos:Number = 0;
			var yPos:Number = 0 ;
			var width:Number = 100/((stage.stageWidth > stage.stageHeight) ? rows : columns);
			var height:Number = 100/((stage.stageWidth > stage.stageHeight) ? columns : rows);
			
			var i:int = 0;
			for each( var dp:DraggablePanel in panels)
			{				
				dp.panelX.value = xPos.toString() + "%";
				dp.panelY.value = yPos.toString() + "%";
				
				dp.panelHeight.value = height.toString() + "%";
				dp.panelWidth.value = width.toString() + "%";
				if( i == (panels.length - 1))
				{
					// expand to fill the width of stage
					dp.panelWidth.value = (100-xPos).toString() + "%";
				}
				
				xPos += width;
				if(xPos >= 100) xPos = 0;
				if( !xPos) yPos += height ;
				i++;
			}
		}
		
		/**
		 * @return an Array containing all DraggablePanels on stage that are not minimized
		 *
 		 * @author kmanohar
		 */		
		private function getWindowsOnStage():Array
		{
			var panels:Array = Weave.root.getObjects(DraggablePanel);
			var panelsOnStage:Array = [];
			
			for each( var panel:DraggablePanel in panels )
			{				
				if(!panel.minimized.value) 
					panelsOnStage.push(panel);
			}
			return panelsOnStage;
		}
		
		/**
		 * This function handles parsing the config file once it has downloaded.
		 */
		private function handleConfigFileDownloaded(event:ResultEvent, token:Object = null):void
		{
			var xml:XML = null;
			try
			{
				xml = XML(event.result);
			}
			catch (e:Error)
			{
				WeaveAPI.ErrorManager.reportError(e);
			}
			if (xml)
				loadSessionState(xml);
			if (getFlashVarEditable())
			{
				Weave.properties.enableMenuBar.value = true;
				Weave.properties.enableSessionMenu.value = true;
				Weave.properties.enableSessionEdit.value = true;
				Weave.properties.enableUserPreferences.value = true;
			}
			else if (getFlashVarEditable() === false) // triple equals because it may also be undefined
			{
				Weave.properties.enableMenuBar.value = false;
				Weave.properties.dashboardMode.value = true;
			}
			
			// enable JavaScript API after initial session state has loaded.
			WeaveAPI.initializeExternalInterface();
			
			if (getFlashVarEditable())
				addHistorySlider();
		}
		
		private var log:SessionStateLog;
		private function addHistorySlider():void
		{
			// beta undo/redo feature
			log = new SessionStateLog(Weave.root);
			
			var hb:HBox = new HBox();
			hb.percentWidth = 100;
			addChildAt(hb, 0);
			
			var undoButton:Button = new Button();
			undoButton.label="<";
			undoButton.addEventListener(MouseEvent.CLICK,function(..._):void{ log.undo(); });
			hb.addChild(undoButton);
			
			var redoButton:Button = new Button();
			redoButton.label=">";
			redoButton.addEventListener(MouseEvent.CLICK,function(..._):void{ log.redo(); });
			hb.addChild(redoButton);
			
			var hs:HSlider = new HSlider();
			hb.addChild(hs);
			hs.percentWidth = 100;
			hs.setStyle("bottom", 0);
			hs.minimum = 0;
			hs.liveDragging = true;
			hs.tickInterval = 1;
			hs.snapInterval = 1;
			hs.addEventListener(Event.CHANGE, handleHistorySlider);
			function handleHistorySlider():void
			{
				var delta:int = hs.value - log.undoHistory.length;
				if (delta < 0)
					log.undo(-delta);
				else
					log.redo(delta);
			}
			
			getCallbackCollection(log).addImmediateCallback(this, updateHistorySlider, null, true);
			function updateHistorySlider():void
			{
				hs.maximum = log.undoHistory.length + log.redoHistory.length;
				hs.value = log.undoHistory.length;
			}
		}

		
		private var _printToolMenuItem:ContextMenuItem = null;
		/**
		 * This function creates the context menu for this application by getting context menus from each
		 * class that defines them 
		 *  
		 * @TODO generalize this better...
		 * 
		 * @author abaumann 
		 */
		private function setupContextMenu():void
		{ 
			//if (contextMenu == null)
				contextMenu = new ContextMenu();
			
			// Hide the default Flash menu
			contextMenu.hideBuiltInItems();
			
			CustomContextMenuManager.removeAllContextMenuItems();
			
			if (Weave.properties.enableRightClick.value)
			{
				// Add item for the DataTableTool
				DataTableTool.createContextMenuItems(this);
				
				// Add item for the DatasetLoader
				//DatasetLoader.createContextMenuItems(this);
				
				if (Weave.properties.enableSubsetControls.value)
				{
					// Add context menu item for selection related items (subset creation, etc)	
					KeySetContextMenuItems.createContextMenuItems(this);
				}
				
				if(Weave.properties.enableMarker.value)
				{
					MarkerSettingsComponent.createContextMenuItems(this);
				}
				
				SessionedTextBox.createContextMenuItems(this);
				PenTool.createContextMenuItems(this);
					
				//HelpPanel.createContextMenuItems(this);
				if (Weave.properties.dataInfoURL.value)
					addLinkContextMenuItem("Show Information About This Dataset...", Weave.properties.dataInfoURL.value);
				
				// Add context menu item for VisTools (right now this is exporting of an image, will also have printing of an image, etc -- for
				// one tool at a time)
				createExportToolImageContextMenuItem();
				_printToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination("Print Application Image", this, handleContextMenuItemSelect, "4 exportMenuItems");
				
				
				
				
				// Add context menu items for handling search queries
				SearchEngineUtils.createContextMenuItems(this);
				// Additional record queries can be defined in the config file.  Here they are extracted and added as context menu items with their
				// associated actions.
				if (_configFileXML)
				{
					for(var i:int = 0; i < _configFileXML.recordQuery.length(); i++)
					{
						SearchEngineUtils.addSearchQueryContextMenuItem(_configFileXML.recordQuery[i], this);	
					}
				}
			}
		}

		// Create the context menu items for exporting panel images.  
		private var _panelPrintContextMenuItem:ContextMenuItem = null;
		protected var panelSettingsContextMenuItem:ContextMenuItem = null;
		private function createExportToolImageContextMenuItem():Boolean
		{				
			if(Weave.properties.enableExportToolImage.value)
			{
				// Add a listener to this destination context menu for when it is opened
				contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
				
				// Create a context menu item for printing of a single tool with title and logo
				_panelPrintContextMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(
						"Print/Export Panel Image...", 
						this,
						function(event:ContextMenuEvent):void { printOrExportImage(_panelToExport); },
						"4 exportMenuItems"
					);
				// By default this menu item is disabled so that it does not show up unless we right click on a tool
				_panelPrintContextMenuItem.enabled = false;
				
				return true;
			}
			
			return false;
		}
		// Handler for when the context menu is opened.  In here we will keep track of what tool we were over when we right clicked so 
		// that we can export an image of just this tool.  We also change the text in the context menu item for exporting an image of 
		// this tool so it  says the name of the tool to export.
		private var _panelToExport:DraggablePanel = null;
		private function handleContextMenuOpened(event:ContextMenuEvent):void
		{
			// When the context menu is opened, save a pointer to the active tool, this is the tool we want to export an image of
			_panelToExport = DraggablePanel.activePanel;
			
			// If this tool is valid (we are over a tool), then we want this menu item enabled, otherwise don't allow users to choose it
			if(_panelToExport != null)
			{
				_panelPrintContextMenuItem.caption = "Print/Export " + _panelToExport.title + " Image...";
				_panelPrintContextMenuItem.enabled = true;
			}
			else
			{
				_panelPrintContextMenuItem.caption = "Print/Export Panel Image...";
				_panelPrintContextMenuItem.enabled = false;	
			}
		}
		
		/** 
		 * Static methods to encapsulate the list of reports within the ObjectRepository
		 * addReportsToMenu loops through the reports in the Object Repository and 
		 * adds them to the tools menu
		 */
		public static function getReportsMenuItems():Array
		{
			var reportsMenuItems:Array = [];
			//add reports to tools menu
			for each (var report:WeaveReport in Weave.root.getObjects(WeaveReport))
			{
				reportsMenuItems.push(new WeaveMenuItem(Weave.root.getName(report), WeaveReport.requestReport, [report]));
			}	
			
			return reportsMenuItems;
		}
		
		private var _sessionFileLoader:FileReference = null;
		private function handleImportSessionState():void
		{			
			if (_sessionFileLoader == null)
			{
				_sessionFileLoader = new FileReference();
				
				_sessionFileLoader.addEventListener(Event.SELECT,   function (e:Event):void { _sessionFileLoader.load(); _configFileName = _sessionFileLoader.name; } );
				_sessionFileLoader.addEventListener(Event.COMPLETE, function (e:Event):void {loadSessionState( XML(e.target.data) );} );
			}
			
			_sessionFileLoader.browse([new FileFilter("XML", "*.xml")]);
		}
		
		private function handleExportSessionState():void
		{		
			
			var exportSessionStatePanel:ExportSessionStatePanel = new ExportSessionStatePanel();
			
			exportSessionStatePanel = PopUpManager.createPopUp(this,ExportSessionStatePanel,false) as ExportSessionStatePanel;
			PopUpManager.centerPopUp(exportSessionStatePanel);
		}
		
		public function printOrExportImage(component:UIComponent):void
		{
			if (!component)
				return;
			
			var visMenuVisible:Boolean    = (_weaveMenu ? _weaveMenu.visible : false);
			var visTaskbarVisible:Boolean = (VisTaskbar.instance ? VisTaskbar.instance.visible : false);
			
			if (_weaveMenu)    _weaveMenu.visible    = false;
			if (VisTaskbar.instance) VisTaskbar.instance.visible = false;

			//initialize the print format
			var printPopUp:PrintPanel = new PrintPanel();
   			printPopUp = PopUpManager.createPopUp(this,PrintPanel,true) as PrintPanel;
   			PopUpManager.centerPopUp(printPopUp);
   			printPopUp.applicationTitle = Weave.properties.pageTitle.value;
   			//add current snapshot to Print Format
			printPopUp.componentToScreenshot = component;
			
			if (_weaveMenu)  _weaveMenu.visible    = visMenuVisible;
			if (VisTaskbar.instance) VisTaskbar.instance.visible = visTaskbarVisible;	
		}

		/**
		 * Update the page title.
		 */
		public function updatePageTitle():void
		{
			ExternalInterface.call("setTitle", Weave.properties.pageTitle.value);
		}
		
		/** 
		 * Add a context menu item that goes to an associated url in a new browser window/tab
		 */
		private function addLinkContextMenuItem(text:String, url:String, separatorBefore:Boolean=false):void
		{
			CustomContextMenuManager.createAndAddMenuItemToDestination(text, 
															  this, 
                                                              function(e:Event):void { navigateToURL(new URLRequest(url), "_blank"); },
                                                              "linkMenuItems");	
		}

		/**
		 * @TODO This should be removed -- ideally VisApplication has no context menu items itself, only other classes do
		 */
		protected function handleContextMenuItemSelect(event:ContextMenuEvent):void
		{
			if (event.currentTarget == _printToolMenuItem)
   			{
   				printOrExportImage(this);
   			}
   			
		}
		
//		private function testColumn(column:IAttributeColumn):void
//		{
//			var key:IQualifiedKey;
//			var keys:Array = column ? column.keys : [];
//			trace(getQualifiedClassName(column), column);
//			trace("keys: "+keys);
//			for each (key in keys)
//			{
//				var debug:String = "key = "+key.keyType+'#'+key.localName+":";
//				for each (var type:Class in [null, Number, String, Boolean])
//				{
//					var value:* = column.getValueFromKey(key, type);
//					var typeStr:String = type ? String(type) : '('+getQualifiedClassName(value)+')';
//					debug += "\n\t"+typeStr+":\t"+value;
//				}
//				trace(debug);
//			}
//		}
		
		private function trace(...args):void
		{
			DebugUtils.debug_trace(VisApplication, args);
		}	
	}
}
