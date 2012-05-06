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
	import flash.display.LoaderInfo;
	import flash.display.StageDisplayState;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.System;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import weave.api.WeaveAPI;
	import weave.api.core.ILinkableObject;
	import weave.api.data.ICSVExportable;
	import weave.api.data.IDataSource;
	import weave.api.getCallbackCollection;
	import weave.api.reportError;
	import weave.api.ui.IVisTool;
	import weave.compiler.StandardLib;
	import weave.core.ExternalSessionStateInterface;
	import weave.core.LinkableBoolean;
	import weave.core.weave_internal;
	import weave.data.AttributeColumns.DynamicColumn;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.KeySets.KeySet;
	import weave.editors.WeavePropertiesEditor;
	import weave.editors.managers.AddDataSourcePanel;
	import weave.editors.managers.EditDataSourcePanel;
	import weave.primitives.AttributeHierarchy;
	import weave.services.DelayedAsyncResponder;
	import weave.services.LocalAsyncService;
	import weave.ui.AlertTextBox;
	import weave.ui.AlertTextBoxEvent;
	import weave.ui.AttributeSelectorPanel;
	import weave.ui.CirclePlotterSettings;
	import weave.ui.ColorController;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.DraggablePanel;
	import weave.ui.EquationEditor;
	import weave.ui.ErrorLogPanel;
	import weave.ui.ExportSessionStatePanel;
	import weave.ui.MarkerSettingsComponent;
	import weave.ui.NewUserWizard;
	import weave.ui.OICLogoPane;
	import weave.ui.PenTool;
	import weave.ui.PrintPanel;
	import weave.ui.ProbeToolTipEditor;
	import weave.ui.QuickMenuPanel;
	import weave.ui.SelectionManager;
	import weave.ui.SessionStateEditor;
	import weave.ui.SubsetManager;
	import weave.ui.WeaveProgressBar;
	import weave.ui.WizardPanel;
	import weave.ui.annotation.SessionedTextBox;
	import weave.ui.collaboration.CollaborationEditor;
	import weave.ui.collaboration.CollaborationMenuBar;
	import weave.ui.collaboration.CollaborationTool;
	import weave.ui.controlBars.VisTaskbar;
	import weave.ui.controlBars.WeaveMenuBar;
	import weave.ui.controlBars.WeaveMenuItem;
	import weave.utils.DebugTimer;
	import weave.utils.EditorManager;
	import weave.utils.VectorUtils;
	import weave.visualization.layers.SelectablePlotLayer;
	import weave.visualization.plotters.GeometryPlotter;
	import weave.visualization.tools.MapTool;

	use namespace weave_internal;

	public class VisApplication extends VBox implements ILinkableObject
	{
		MXClasses; // Referencing this allows all Flex classes to be dynamically created at runtime.

		/**
		 * Constructor.
		 */
		public function VisApplication()
		{
			super();

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
			setStyle('backgroundAlpha', 1);
			
			// make it so the menu bar does not get hidden if the workspace size is too small.
			clipContent = false;
			autoLayout = true;
			
			// no scrolling
			horizontalScrollPolicy = "off";
			verticalScrollPolicy   = "off";
			visDesktop.verticalScrollPolicy   = "off";
			visDesktop.horizontalScrollPolicy = "off";

			waitForApplicationComplete();
		}

		
		/**
		 * This needs to be a function because FlashVars can't be fetched while the application is loading.
		 */
		private function waitForApplicationComplete():void
		{
			if (!root)
			{
				callLater(waitForApplicationComplete);
				return;
			}
			
			try {
				loaderInfo['uncaughtErrorEvents'].addEventListener(
					'uncaughtError',
					function(event:Object):void
					{
						reportError(event.error);
					}
				);
			} catch (e:Error) { }
			
			// resize to parent size each frame because percentWidth,percentHeight doesn't seem reliable when application is nested
			addEventListener(Event.ENTER_FRAME, updateWorkspaceSize);
			
			// special case - if an error occurred already
			if (WeaveAPI.ErrorManager.errors.length > 0)
				ErrorLogPanel.openErrorLog();
			
			getCallbackCollection(WeaveAPI.ErrorManager).addGroupedCallback(this, ErrorLogPanel.openErrorLog);
			Weave.root.childListCallbacks.addGroupedCallback(this, setupWindowMenu);
			Weave.properties.showCopyright.addGroupedCallback(this, toggleMenuBar);
			Weave.properties.enableMenuBar.addGroupedCallback(this, toggleMenuBar);
			Weave.properties.enableCollaborationBar.addGroupedCallback(this, toggleCollaborationMenuBar);
			Weave.properties.pageTitle.addGroupedCallback(this, updatePageTitle);
			
			getCallbackCollection(Weave.root.getObject(Weave.SAVED_SELECTION_KEYSETS)).addGroupedCallback(this, setupSelectionsMenu);
			getCallbackCollection(Weave.root.getObject(Weave.SAVED_SUBSETS_KEYFILTERS)).addGroupedCallback(this, setupSubsetsMenu);
			getCallbackCollection(Weave.properties).addGroupedCallback(this, setupVisMenuItems);
			Weave.properties.backgroundColor.addImmediateCallback(this, handleBackgroundColorChange, true);
			
			getFlashVars();
			handleFlashVarAllowDomain();
			
			// disable application until it's ready
			enabled = false;
			
			if (getFlashVarAdminConnectionName() != null)
			{
				// disable interface until connected to admin console
				var _this:VisApplication = this;
				_this.enabled = false;
				var resultHandler:Function = function(event:ResultEvent, token:Object = null):void
				{
					_this.enabled = true;
					adminService = pendingAdminService;
					setupVisMenuItems(); // make sure 'save session state to server' is shown
					downloadConfigFile();
				};
				var faultHandler:Function = function(event:FaultEvent = null, token:Object = null):void
				{
					Alert.show("Unable to connect to the Admin Console.\nYou will not be able to save your session state to the server.", "Connection error");
					// do not re-download config file if this function was called as a grouped callback.
					if (event) // event==null if called as grouped callback
					{
						_this.enabled = true;
						downloadConfigFile();
					}
				};
				var pendingAdminService:LocalAsyncService = new LocalAsyncService(this, false, getFlashVarAdminConnectionName());
				pendingAdminService.errorCallbacks.addGroupedCallback(this, faultHandler);
				// when admin console responds, set adminService
				DelayedAsyncResponder.addResponder(
					pendingAdminService.invokeAsyncMethod("ping"),
					resultHandler,
					faultHandler
				);
				
				// do nothing until admin console is connected.
				return;
			}
			else
			{
				downloadConfigFile();
			}
		}
		
		private function downloadConfigFile():void
		{
			if (Weave.handleWeaveReload())
			{
				handleConfigFileDownloaded();
			}
			else
			{
				// load the session state file
				var fileName:String = getFlashVarConfigFileName() || DEFAULT_CONFIG_FILE_NAME;
				var noCacheHack:String = "?" + (new Date()).getTime(); // prevent flex from using cache
				WeaveAPI.URLRequestUtils.getURL(new URLRequest(fileName + noCacheHack), handleConfigFileDownloaded, handleConfigFileFault, fileName);
			}
		}
		private function handleConfigFileDownloaded(event:ResultEvent = null, token:Object = null):void
		{
			var fileName:String = token as String;
			if (!event)
				loadSessionState(null, null);
			else
				loadSessionState(event.result, fileName);
			
			if (getFlashVarEditable())
			{
				Weave.properties.enableMenuBar.value = true;
				Weave.properties.enableSessionMenu.value = true;
				Weave.properties.enableWindowMenu.value = true;
				Weave.properties.enableUserPreferences.value = true;
			}
			else if (getFlashVarEditable() === false) // triple equals because it may also be undefined
			{
				Weave.properties.enableMenuBar.value = false;
				Weave.properties.dashboardMode.value = true;
			}
			
			// enable JavaScript API after initial session state has loaded.
			ExternalSessionStateInterface.tryAddCallback('runStartupJavaScript', Weave.properties.runStartupJavaScript);
			WeaveAPI.initializeExternalInterface(); // this calls weaveReady() in JavaScript
			Weave.properties.runStartupJavaScript(); // run startup script after weaveReady()
		}
		private function handleConfigFileFault(event:FaultEvent, token:Object = null):void
		{
			// When creating a new file through the admin console, don't report an error for the missing file.
			var adminDefault:Boolean = (getFlashVarAdminConnectionName() && !getFlashVarConfigFileName());
			if (adminDefault)
			{
				// The admin hasn't created a default configuration yet.
				// When we're creating a new config through the admin console, create a
				// WeaveDataSource so the admin doesn't have to add it manually every time.
				Weave.root.requestObject(null, WeaveDataSource, false);
				// It's convenient if the admin sets probed columns first so new tools will have default attributes selected.
				DraggablePanel.openStaticInstance(ProbeToolTipEditor);
			}
			else
			{
				reportError(event);
			}
			if (event.fault.faultCode == SecurityErrorEvent.SECURITY_ERROR)
				Alert.show("The server hosting the configuration file does not have a permissive crossdomain policy.", "Security sandbox violation");
		}
		
		
		private function handleBackgroundColorChange():void
		{
			var color:Number = Weave.properties.backgroundColor.value;
			this.setStyle('backgroundColor', color);
			
			//(WeaveAPI.topLevelApplication as UIComponent).setStyle("backgroundGradientColors", [color, color]);
		}
		
		/**
		 * The desktop is the entire viewable area minus the space for the optional menu bar and taskbar
		 */
		public const visDesktop:VisDesktop = new VisDesktop();

		/**
		 * The mapping for the flash vars.
		 */
		private var _flashVars:Object;
		public function get flashVars():Object { return _flashVars; }
		
		private function handleFlashVarAllowDomain():void
		{
			var domains:* = _flashVars['allowDomain'];
			if (domains is String)
				domains = [domains];
			for each (var domain:String in domains)
			{
				systemManager.allowDomain(domain);
				systemManager.allowInsecureDomain(domain);
			}
		}
		
		private function getFlashVarAdminConnectionName():String
		{
			return _flashVars['adminSession'] as String;
		}
		
		/**
		 * Gets the name of the config file.
		 */
		private function getFlashVarConfigFileName():String
		{
			return unescape(_flashVars[CONFIG_FILE_FLASH_VAR_NAME] || '');
		}
		
		/**
		 * @return true, false, or undefined depending what the 'editable' FlashVar is set to.
		 */
		private function getFlashVarEditable():*
		{
			var name:String = 'editable';
			if (_flashVars.hasOwnProperty(name))
				return StandardLib.asBoolean(_flashVars[name] as String);
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
				const DEPRECATED_FILE_PARAM_NAME:String = 'defaults';
				if (!_flashVars.hasOwnProperty(CONFIG_FILE_FLASH_VAR_NAME) && urlParams.hasOwnProperty(DEPRECATED_FILE_PARAM_NAME))
				{
					_flashVars[CONFIG_FILE_FLASH_VAR_NAME] = urlParams[DEPRECATED_FILE_PARAM_NAME];
					_usingDeprecatedFlashVar = true;
				}
			}
			catch(e:Error) { }
		}
		private static const CONFIG_FILE_FLASH_VAR_NAME:String = 'file';
		private static const DEFAULT_CONFIG_FILE_NAME:String = 'defaults.xml';
		private var _usingDeprecatedFlashVar:Boolean = false;
		private const DEPRECATED_FLASH_VAR_MESSAGE:String = "The 'defaults=' URL parameter is deprecated.  Use 'file=' instead.";

		private var _selectionIndicatorText:Text = new Text;
		private var selectionKeySet:KeySet = Weave.root.getObject(Weave.DEFAULT_SELECTION_KEYSET) as KeySet;
		private function handleSelectionChange():void
		{
			_selectionIndicatorText.text = selectionKeySet.keys.length.toString() + " Records Selected";
			try
			{
				if (selectionKeySet.keys.length == 0 || !Weave.properties.showSelectedRecordsText.value)
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
		
		private var historySlider:UIComponent = null;
		
		override protected function createChildren():void
		{
			super.createChildren();

			//UIComponentGlobals.catchCallLaterExceptions = true;
			//systemManager.addEventListener("callLaterError", reportError);

			this.addChild(visDesktop);
			visDesktop.percentWidth = 100;
			visDesktop.percentHeight = 100;
			Weave.properties.workspaceWidth.addImmediateCallback(this, updateWorkspaceSize);
			Weave.properties.workspaceHeight.addImmediateCallback(this, updateWorkspaceSize);
			Weave.properties.workspaceMultiplier.addImmediateCallback(this, updateWorkspaceSize);
			
			// Code for selection indicator
			getCallbackCollection(selectionKeySet).addGroupedCallback(this, handleSelectionChange, true);
			Weave.properties.showSelectedRecordsText.addGroupedCallback(this, handleSelectionChange, true);
			_selectionIndicatorText.setStyle("color", 0xFFFFFF);
			_selectionIndicatorText.opaqueBackground = 0x000000;
			_selectionIndicatorText.setStyle("bottom", 0);
			_selectionIndicatorText.setStyle("right", 0);
			
			PopUpManager.createPopUp(this, WeaveProgressBar);

			this.addChild(VisTaskbar.instance);
			WeaveAPI.StageUtils.addEventCallback(KeyboardEvent.KEY_DOWN,this,handleKeyPress);
		}
		
		private function handleKeyPress():void
		{
			var event:KeyboardEvent = WeaveAPI.StageUtils.keyboardEvent;
			if(event.ctrlKey && event.keyCode == 77)
			{
				var qmenu:QuickMenuPanel = PopUpManager.createPopUp(this,QuickMenuPanel) as QuickMenuPanel;
				PopUpManager.centerPopUp(qmenu);
			}
		}
		
		private function updateWorkspaceSize(..._):void
		{
			if (!this.parent)
				return;
			
			var w:Number = Weave.properties.workspaceWidth.value;
			var h:Number = Weave.properties.workspaceHeight.value;
			if (isFinite(w))
				this.width = w;
			else
				this.width = this.parent.width;
			if (isFinite(h))
				this.height = h;
			else
				this.height = this.parent.height;
			
			var workspace:Canvas = visDesktop.internalCanvas;
			var multiplier:Number = Weave.properties.workspaceMultiplier.value;
			var scale:Number = 1 / multiplier;
			workspace.scaleX = scale;
			workspace.scaleY = scale;
			workspace.width = workspace.parent.width * multiplier;
			workspace.height = workspace.parent.height * multiplier;
		}

		private var adminService:LocalAsyncService = null;
		
		
		private function copySessionStateToClipboard():void
		{
			System.setClipboard(Weave.getSessionStateXML().toXMLString());
		}
		
		private var _useWeaveExtensionWhenSavingToServer:Boolean;
		private function saveSessionStateToServer(useWeaveExtension:Boolean):void
		{
			if (adminService == null)
			{
				Alert.show("Not connected to Admin Console.", "Error");
				return;
			}
			
			_useWeaveExtensionWhenSavingToServer = useWeaveExtension;
			
			var fileName:String = getFlashVarConfigFileName().split("/").pop();
			fileName = Weave.fixWeaveFileName(fileName, _useWeaveExtensionWhenSavingToServer);
			
			var fileSaveDialogBox:AlertTextBox;
			fileSaveDialogBox = PopUpManager.createPopUp(this,AlertTextBox) as AlertTextBox;
			fileSaveDialogBox.textInput = fileName;
			fileSaveDialogBox.title = useWeaveExtension ? "Save Session History" : "Save Session State XML";
			fileSaveDialogBox.message = "Enter a filename";
			fileSaveDialogBox.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, handleFileSaveClose);
			PopUpManager.centerPopUp(fileSaveDialogBox);
		}
		
		private function handleFileSaveClose(event:AlertTextBoxEvent):void
		{
			if (event.confirm)
			{
				var fileName:String = event.textInput;
				fileName = Weave.fixWeaveFileName(fileName, _useWeaveExtensionWhenSavingToServer);
				
				var content:ByteArray;
				if (_useWeaveExtensionWhenSavingToServer)
				{
					content = Weave.createWeaveFileContent();
				}
				else
				{
					content = new ByteArray();
					content.writeMultiByte(Weave.getSessionStateXML().toXMLString(), "utf-8");
				}
				
				var token:AsyncToken = adminService.invokeAsyncMethod('saveWeaveFile', [content, fileName, true]);
				DelayedAsyncResponder.addResponder(
					token,
					function(event:ResultEvent, token:Object = null):void
					{
						Alert.show(String(event.result), "Admin Console Response");
					},
					function(event:FaultEvent, token:Object = null):void
					{
						reportError(event.fault, "Unable to connect to Admin Console");
					},
					null
				);
				
				setupVisMenuItems();
			}
		}
		
		// this function may be called by the Admin Console to close this window, needs to be public
		public function closeWeavePopup():void
		{
			ExternalInterface.call("window.close()");
		}

		/**
		 * Optional menu bar (bottom of screen) to control the collaboration service and interaction
		 * between users.
		 */
		private var _collabMenu:CollaborationMenuBar = null;
		
		private function toggleCollaborationMenuBar():void
		{
			if (!_collabMenu)
				_collabMenu = new CollaborationMenuBar();
			
			if( Weave.properties.enableCollaborationBar.value )
			{
				if( !_collabMenu.parent )
				{
					_collabMenu.percentWidth = 100;
					this.addChild(_collabMenu);
					_collabMenu.addedToStage();
				}
			} else {
				try
				{
					if( this == _collabMenu.parent ) {
						_collabMenu.dispose();
						this.removeChild(_collabMenu);
					}
					
				} catch( error:Error ) {
					reportError(error);
				}
			}
		}

		public function getMenuItems():ArrayCollection
		{
			return _weaveMenu.menubar.dataProvider as ArrayCollection;
		}
		
		/**
		 * This will be used to incorporate branding into any weave view.  Linkable to the Open Indicators Consortium website.
		 */
		private var _oicLogoPane:OICLogoPane = new OICLogoPane();
		
		/**
		 * Optional menu bar (top of the screen) and task bar (bottom of the screen).  These would be used for an advanced analyst
		 * view to add new tools, manage windows, do advanced tasks, etc.
		 */
		private var _weaveMenu:WeaveMenuBar = null;
		
		private function toggleMenuBar():void
		{
			if (!enabled)
			{
				callLater(toggleMenuBar);
				return;
			}
			
			if (!historySlider)
			{
				historySlider = EditorManager.getNewEditor(Weave.history) as UIComponent;
				this.addChildAt(historySlider, this.getChildIndex(visDesktop));
			}
			
			DraggablePanel.adminMode = adminService || getFlashVarEditable();
			if (Weave.properties.enableMenuBar.value || adminService || getFlashVarEditable())
			{
				if (!_weaveMenu)
				{
					_weaveMenu = new WeaveMenuBar();

					//trace("MENU BAR ADDED");
					_weaveMenu.percentWidth = 100;
					callLater(setupVisMenuItems);
					
					//PopUpManager.addPopUp(_weaveMenu, this);
					this.addChildAt(_weaveMenu, 0);
					
					if (this == _oicLogoPane.parent)
						this.removeChild(_oicLogoPane);
				}
				
				// always show menu bar when admin service is present
				historySlider.alpha = _weaveMenu.alpha = Weave.properties.enableMenuBar.value ? 1.0 : 0.3;
			}
			// otherwise there is no menu bar, (which normally includes the oiclogopane, so add one to replace it)
			else
			{
				historySlider.visible = historySlider.includeInLayout = false;
				try
				{
		   			if (_weaveMenu && this == _weaveMenu.parent)
						removeChild(_weaveMenu);

		   			_weaveMenu = null;
					
					if (Weave.properties.showCopyright.value)
					{
						addChild(_oicLogoPane);
					}
					else if (this == _oicLogoPane.parent)
						removeChild(_oicLogoPane);
				}
				catch(error:Error)
				{
					reportError(error);
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

		private function setupVisMenuItems():void
		{
			setupContextMenu();
			
			if (!_weaveMenu)
				return;
			
			_weaveMenu.validateNow();
			
			_weaveMenu.removeAllMenus();
			
			if (Weave.properties.enableDataMenu.value)
			{
				_dataMenu = _weaveMenu.addMenuToMenuBar("Data", false);
				if (Weave.properties.enableNewUserWizard)
				{
					_weaveMenu.addMenuItemToMenu(
						_dataMenu,
						new WeaveMenuItem(
							"Load my data",
							function():void
							{
								WizardPanel.createWizard(_this, new NewUserWizard());
							}
						)
					);
				}
				
				if (Weave.properties.enableRefreshHierarchies.value)
				{
					_weaveMenu.addMenuItemToMenu(_dataMenu,
						new WeaveMenuItem("Refresh all data source hierarchies",
							function ():void {
								var sources:Array = Weave.root.getObjects(IDataSource);
								for each (var source:IDataSource in sources)
									(source.attributeHierarchy as AttributeHierarchy).value = null;
							}
						)
					);
				}
				
				if (Weave.properties.enableAddDataSource.value)
					_weaveMenu.addMenuItemToMenu(_dataMenu, new WeaveMenuItem("Add New Datasource", AddDataSourcePanel.showAsPopup));
				
				if (Weave.properties.enableEditDataSource.value)
					_weaveMenu.addMenuItemToMenu(_dataMenu, new WeaveMenuItem("Edit Datasources", EditDataSourcePanel.showAsPopup));
			}
			
			
			if (Weave.properties.enableDynamicTools.value)
			{
				_toolsMenu = _weaveMenu.addMenuToMenuBar("Tools", false);

				createToolMenuItem(Weave.properties.showColorController, "Color Controller", DraggablePanel.openStaticInstance, [ColorController]);
				createToolMenuItem(Weave.properties.showProbeToolTipEditor, "Probe ToolTip Editor", DraggablePanel.openStaticInstance, [ProbeToolTipEditor]);
				createToolMenuItem(Weave.properties.showEquationEditor, "Equation Editor", DraggablePanel.openStaticInstance, [EquationEditor]);
				createToolMenuItem(Weave.properties.showCollaborationEditor, "Collaboration Settings", DraggablePanel.openStaticInstance, [CollaborationEditor]);
				
				var _this:VisApplication = this;

				if (!Weave.properties.dashboardMode.value)
				{
					_weaveMenu.addSeparatorToMenu(_toolsMenu);
					
					for each (var impl:Class in WeaveAPI.getRegisteredImplementations(IVisTool))
					{
						// TEMPORARY SOLUTION
						if (Weave.properties._toggleMap[impl] && !(Weave.properties._toggleMap[impl] as LinkableBoolean).value)
							continue;
						
						var displayName:String = WeaveAPI.getRegisteredImplementationDisplayName(impl);
						_weaveMenu.addMenuItemToMenu(_toolsMenu, new WeaveMenuItem("Add " + displayName, createGlobalObject, [impl]));
					}
				}
				
				_weaveMenu.addSeparatorToMenu(_toolsMenu);
				_weaveMenu.addMenuItemToMenu(_toolsMenu, new WeaveMenuItem(
					function():String { return (Weave.properties.dashboardMode.value ? "Disable" : "Enable") + " dashboard mode"; },
					function():void { Weave.properties.dashboardMode.value = !Weave.properties.dashboardMode.value; }
				));
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
			
			var showHistorySlider:Boolean = false;
			if (Weave.properties.enableSessionMenu.value || adminService)
			{
				_sessionMenu = _weaveMenu.addMenuToMenuBar("Session", false);
				_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Edit session state", SessionStateEditor.openDefaultEditor));
				_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Copy session state XML to clipboard", copySessionStateToClipboard));
				_weaveMenu.addSeparatorToMenu(_sessionMenu);
				_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Import session history...", handleImportSessionState));
				_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Export session history...", handleExportSessionState));
				_weaveMenu.addSeparatorToMenu(_sessionMenu);
				_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem(
					function():String { return (Weave.properties.showSessionHistoryControls.value ? "Hide" : "Show") + " session history controls"; },
					function():void { Weave.properties.showSessionHistoryControls.value = !Weave.properties.showSessionHistoryControls.value; }
				));
				if (Weave.ALLOW_PLUGINS)
				{
					_weaveMenu.addSeparatorToMenu(_sessionMenu);
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem("Manage plugins...", managePlugins));
				}
				if (Weave.properties.showCollaborationMenuItem.value)
				{
					_weaveMenu.addSeparatorToMenu(_sessionMenu);
					_weaveMenu.addMenuItemToMenu(
						_sessionMenu,
						new WeaveMenuItem(
							function():String
							{
								var collabTool:CollaborationTool = CollaborationTool.instance;
								return collabTool && collabTool.collabService.isConnected
									? "Open collaboration window"
									: "Connect to collaboration server (Beta)...";
							},
							DraggablePanel.openStaticInstance,
							[CollaborationTool]
						)
					);
				}
				if (adminService)
				{
					_weaveMenu.addSeparatorToMenu(_sessionMenu);
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem(
						"Save session state XML to server",
						function():void { saveSessionStateToServer(false); }
					));
					_weaveMenu.addSeparatorToMenu(_sessionMenu);
					_weaveMenu.addMenuItemToMenu(_sessionMenu, new WeaveMenuItem(
						"Save session history to server",
						function():void { saveSessionStateToServer(true); }
					));
				}
				
				showHistorySlider = Weave.properties.showSessionHistoryControls.value;
			}
			historySlider.visible = historySlider.includeInLayout = showHistorySlider;
			
			if (Weave.properties.enableWindowMenu.value || adminService)
			{
				_windowMenu = _weaveMenu.addMenuToMenuBar("Window", true);
				setupWindowMenu();
			}
			
			if (Weave.properties.enableAboutMenu.value)
			{
				_aboutMenu = _weaveMenu.addMenuToMenuBar("About", false);
				
				_weaveMenu.addMenuItemToMenu(_aboutMenu, new WeaveMenuItem("Weave Version: " + Weave.properties.version.value));
				_weaveMenu.addMenuItemToMenu(_aboutMenu, new WeaveMenuItem("Report a problem", function ():void {
					navigateToURL(new URLRequest("http://info.oicweave.org/projects/weave/issues/new"), "_blank");
				}));
				_weaveMenu.addMenuItemToMenu(_aboutMenu, new WeaveMenuItem("Visit OICWeave.org", function ():void {
					navigateToURL(new URLRequest("http://www.oicweave.org"), "_blank");
				}));
			}
		}
		
		private function createToolMenuItem(toggle:LinkableBoolean, title:String, callback:Function, params:Array = null):void
		{
			if (toggle.value)
				_weaveMenu.addMenuItemToMenu(_toolsMenu, new WeaveMenuItem(title, callback, params));
		}
		
		public function loadSessionState(fileContent:Object, fileName:String):void
		{
			DebugTimer.begin();
			try
			{
				// attempt to parse as a Weave archive
				if (fileContent)
				{
					Weave.loadWeaveFileContent(ByteArray(fileContent));
					if (_usingDeprecatedFlashVar)
						reportError(DEPRECATED_FLASH_VAR_MESSAGE);
				}
			}
			catch (error:Error)
			{
				// attempt to parse as xml
				var xml:XML = null;
				// check the first character because a non-xml string may still parse as a single xml text node.
				if (String(fileContent).charAt(0) == '<')
				{
					try
					{
						xml = XML(fileContent);
					}
					catch (xmlError:Error)
					{
						// invalid xml
						reportError(xmlError);
					}
				}
				else
				{
					// not an xml, so report the original error
					reportError(error);
				}
				
				if (xml)
				{
					// backwards compatibility:
					var stateStr:String = xml.toXMLString();
					while (stateStr.indexOf("org.openindicators") >= 0)
					{
						stateStr = stateStr.replace("org.openindicators", "weave");
						xml = XML(stateStr);
					}
					var tag:XML;
					for each (tag in xml.descendants("OpenIndicatorsServletDataSource"))
						tag.setLocalName("WeaveDataSource");
					for each (tag in xml.descendants("OpenIndicatorsDataSource"))
						tag.setLocalName("WeaveDataSource");
					for each (tag in xml.descendants("EmptyTool"))
						tag.setLocalName("CustomTool");
					for each (tag in xml.descendants("WMSPlotter2"))
						tag.setLocalName("WMSPlotter");
					for each (tag in xml.descendants("SessionedTextArea"))
					{
						tag.setLocalName("SessionedTextBox");
						tag.appendChild(<enableBorders>true</enableBorders>);
						tag.appendChild(<htmlText>{tag.textAreaString.text()}</htmlText>);
						tag.appendChild(<panelX>{tag.textAreaWindowX.text()}</panelX>);
						tag.appendChild(<panelY>{tag.textAreaWindowY.text()}</panelY>);
					}
					
					// add missing attribute titles
					for each (var hierarchy:XML in xml.descendants('hierarchy'))
					{
						for each (tag in hierarchy.descendants("attribute"))
						{
							if (!String(tag.@title) && tag.@name)
							{
								tag.@title = tag.@name;
								if (String(tag.@year))
									tag.@title += ' (' + tag.@year + ')';
							}
						}
					}
					
					Weave.loadWeaveFileContent(xml);
					
//					// An empty subset is not of much use.  If the subset is empty, reset it to include all records.
//					var subset:KeyFilter = Weave.root.getObject(Weave.DEFAULT_SUBSET_KEYFILTER) as KeyFilter;
//					if (subset.includeMissingKeys.value == false && subset.included.keys.length == 0 && subset.excluded.keys.length == 0)
//						subset.includeMissingKeys.value = true;
				}
			}
			DebugTimer.end('loadSessionState', fileName);

			callLater(toggleMenuBar);
			
			if (!getFlashVarAdminConnectionName())
				enabled = true;
			

			/*if (_weaveMenu && _toolsMenu)
			{
				var first:Boolean = true;
				//add reports to tools menu
				for each (var report:WeaveReport in Weave.root.getObjects(WeaveReport))
				{
					if (first)
						_weaveMenu.addSeparatorToMenu(_toolsMenu);
					first = false;
					
					var reportMenuItem:WeaveMenuItem = new WeaveMenuItem(Weave.root.getName(report), WeaveReport.requestReport, [report]);
					_weaveMenu.addMenuItemToMenu(_toolsMenu, reportMenuItem);
				}
			}*/
			
			// generate the context menu items
			setupContextMenu();

			// Set the name of the CSS style we will be using for this application.  If weaveStyle.css is present, the style for
			// this application can be defined outside the code in a CSS file.
			this.styleName = "application";	
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
			
			if (object is MapTool)
			{
				//(object as MapTool).toggleControlPanel();
				var layer:SelectablePlotLayer = (object as MapTool).visualization.layers.getObjects()[0] as SelectablePlotLayer;
				var geom:DynamicColumn = (layer.getDynamicPlotter().internalObject as GeometryPlotter).geometryColumn.internalDynamicColumn;
				AttributeSelectorPanel.openDefaultSelector(geom, "Geometry");
			}

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
			
			if (Weave.properties.enableUserPreferences.value || adminService)
				_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem("Preferences", WeavePropertiesEditor.openGlobalEditor));
			
			_weaveMenu.addSeparatorToMenu(_windowMenu);

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
			
			if (Weave.properties.enableFullScreen.value)
			{
				label = function():String {
					if ( stage && stage.displayState == StageDisplayState.FULL_SCREEN) 
						return 'Exit Full-screen mode'; 
					
					return 'Enter Full-screen mode';
				};
				click = function():void{
					if (stage && stage.displayState == StageDisplayState.NORMAL )
					{
						try
						{
							// set full screen display
							stage.displayState = StageDisplayState.FULL_SCREEN;
						}
						catch (e:Error)
						{
							Alert.show("This website has not enabled full-screen mode, so this option will now be disabled.", "Full-screen mode not allowed");
							Weave.properties.enableFullScreen.value = false;
						}
					}
					else if (stage)
					{
						// set normal display
						stage.displayState = StageDisplayState.NORMAL;
					}
				};
				_weaveMenu.addMenuItemToMenu(_windowMenu, new WeaveMenuItem(label, click, null, Weave.properties.enableFullScreen.value));
			}
			
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
			var newToolMenuItem:WeaveMenuItem = new WeaveMenuItem(label, panel.restorePanel);
			 
			newToolMenuItem.type = WeaveMenuItem.TYPE_RADIO;
			newToolMenuItem.groupName = "activeWindows";
			newToolMenuItem.toggledFunction = function():Boolean {
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
		 * This function arranges all DraggablePanels along a diagonal
		 * 
		 * @author kmanohar
		 */
		private function cascadeWindows():void
		{
			var panels:Array = getWindowsOnStage();
			if (!panels.length)
				return;
			
			var increment:Number = 50/panels.length;
			var dist:Number = 0 ;
			
			for each (var dp:DraggablePanel in panels)
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
			if (!numPanels)
				return;
			
			var gridLength:Number = Math.ceil(Math.sqrt(numPanels));
			
			var rows:uint = gridLength; 
			var columns:uint = gridLength;
			
			if (gridLength*gridLength != numPanels)
			{	
				rows = Math.round(Math.sqrt(numPanels));
				columns = gridLength;
			}			
						
			var xPos:Number = 0;
			var yPos:Number = 0 ;
			var width:Number = 100/((stage.stageWidth > stage.stageHeight) ? rows : columns);
			var height:Number = 100/((stage.stageWidth > stage.stageHeight) ? columns : rows);
			
			var i:int = 0;
			for each (var dp:DraggablePanel in panels)
			{				
				dp.panelX.value = xPos.toString() + "%";
				dp.panelY.value = yPos.toString() + "%";
				
				dp.panelHeight.value = height.toString() + "%";
				dp.panelWidth.value = width.toString() + "%";
				if (i == (panels.length - 1))
				{
					// expand to fill the width of stage
					dp.panelWidth.value = (100-xPos).toString() + "%";
				}
				
				xPos += width;
				if (xPos >= 100)
					xPos = 0;
				if (!xPos)
					yPos += height ;
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
			
			for each (var panel:DraggablePanel in panels)
			{
				if (!panel.minimized.value) 
					panelsOnStage.push(panel);
			}
			return panelsOnStage;
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
				// Add item for the DatasetLoader
				//DatasetLoader.createContextMenuItems(this);
				
				// Add context menu item for selection related items (subset creation, etc)	
				if (Weave.properties.enableSubsetControls.value)
					KeySetContextMenuItems.createContextMenuItems(this);
				
				if (Weave.properties.enableMarker.value)
					MarkerSettingsComponent.createContextMenuItems(this);
				
				if (Weave.properties.enableDrawCircle.value)
					CirclePlotterSettings.createContextMenuItems(this);
				
				if (Weave.properties.enableAnnotation.value)
					SessionedTextBox.createContextMenuItems(this);
				
				if (Weave.properties.enablePenTool.value)
					PenTool.createContextMenuItems(this);
					
				if (Weave.properties.dataInfoURL.value)
					addLinkContextMenuItem("Show Information About This Dataset...", Weave.properties.dataInfoURL.value);
				
				if (Weave.properties.enableExportToolImage.value)
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
				}
				
				if (Weave.properties.enableExportApplicationScreenshot.value)
					_printToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination("Print/Export Application Image", this, handleContextMenuItemSelect, "4 exportMenuItems");
				
				if (Weave.properties.enableExportCSV.value)
				{
					// Add a listener to this destination context menu for when it is opened
					contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
					
					// Create a context menu item for printing of a single tool with title and logo
					_exportCSVContextMenuItem	= CustomContextMenuManager.createAndAddMenuItemToDestination(
						"Export CSV", 
						this,
						function(event:ContextMenuEvent):void { exportCSV(_panelToExport ); },
						"4 exportMenuItems"
					);
					// By default this menu item is disabled so that it does not show up unless we right click on a tool
					_exportCSVContextMenuItem.enabled = false;				
				}
				
				// Add context menu items for handling search queries
				if (Weave.properties.enableSearchForRecord.value)
					SearchEngineUtils.createContextMenuItems(this);
			}
		}

		// Create the context menu items for exporting panel images.  
		private var _panelPrintContextMenuItem:ContextMenuItem = null;
		private  var _exportCSVContextMenuItem:ContextMenuItem = null;
		private var exportCSVfileRef:FileReference = new FileReference();	// CSV download file references
		public function exportCSV(component:UIComponent):void
		{
			if (!component)
				return;
			
			var visMenuVisible:Boolean = (_weaveMenu ? _weaveMenu.visible : false);
			var visTaskbarVisible:Boolean = (VisTaskbar.instance ? VisTaskbar.instance.visible : false);
			
			if (_weaveMenu)
				_weaveMenu.visible = false;
			if (VisTaskbar.instance)
				VisTaskbar.instance.visible = false;			
			
			try
			{
				if (component is ICSVExportable)
				{					
					var name:String = getQualifiedClassName(component).split(':').pop();
					var csvString:String = (component as ICSVExportable).exportCSV();
					if (csvString)
						exportCSVfileRef.save(csvString, "Weave_" + name + ".csv");
					else
						reportError("No data to export in " + (component as DraggablePanel).title);
				}				
				else
				{
					reportError("Component parameter must be either DataTable tool or SimpleVisTool" );
				}
			}
			catch (e:Error)
			{
				reportError(e);
			}			
			if (_weaveMenu)
				_weaveMenu.visible = visMenuVisible;
			if (VisTaskbar.instance)
				VisTaskbar.instance.visible = visTaskbarVisible;	
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
			_panelPrintContextMenuItem.caption = "Print/Export Image of " + (_panelToExport ? _panelToExport.title : "...");
			_panelPrintContextMenuItem.enabled = (_panelToExport != null);
			_exportCSVContextMenuItem.enabled = _panelToExport is ICSVExportable;
		}
		
		private var _weaveFileRef:FileReference = null;
		private function handleImportSessionState():void
		{
			if (!_weaveFileRef)
			{
				_weaveFileRef = new FileReference();
				_weaveFileRef.addEventListener(Event.SELECT,   function (e:Event):void { _weaveFileRef.load(); } );
				_weaveFileRef.addEventListener(Event.COMPLETE, function (e:Event):void { loadSessionState(e.target.data, _weaveFileRef.name); } );
			}
			_weaveFileRef.browse([new FileFilter("Weave files", "*.weave"),new FileFilter("All files", "*.*")]);
		}
		
		private function handleExportSessionState():void
		{		
			var exportSessionStatePanel:ExportSessionStatePanel = new ExportSessionStatePanel();
			exportSessionStatePanel = PopUpManager.createPopUp(this,ExportSessionStatePanel,false) as ExportSessionStatePanel;
			PopUpManager.centerPopUp(exportSessionStatePanel);
		}
		
		private function managePlugins():void
		{
			var popup:AlertTextBox;
			popup = PopUpManager.createPopUp(this, AlertTextBox) as AlertTextBox;
			popup.allowEmptyInput = true;
			popup.textInput = WeaveAPI.CSVParser.createCSV([Weave.getPluginList()]);
			popup.title = "Specify which plugins to load";
			popup.message = "List plugin .SWC files, separated by commas. Weave will reload itself if plugins have to be unloaded.";
			popup.addEventListener(AlertTextBoxEvent.BUTTON_CLICKED, handlePluginsChange);
			PopUpManager.centerPopUp(popup);
		}
		
		private function handlePluginsChange(event:AlertTextBoxEvent):void
		{
			if (event.confirm)
			{
				var plugins:Array = VectorUtils.flatten(WeaveAPI.CSVParser.parseCSV(event.textInput), []);
				Weave.setPluginList(plugins, null);
			}
		}
		
		public function printOrExportImage(component:UIComponent):void
		{
			if (!component)
				return;
			
			//initialize the print format
			var printPopUp:PrintPanel = new PrintPanel();
   			PopUpManager.addPopUp(printPopUp, WeaveAPI.topLevelApplication as UIComponent, true);
   			PopUpManager.centerPopUp(printPopUp);
   			//add current snapshot to Print Format
			printPopUp.componentToScreenshot = component;
		}

		/**
		 * Update the page title.
		 */
		private function updatePageTitle():void
		{
			try
			{
				ExternalInterface.call("setTitle", Weave.properties.pageTitle.value);
			}
			catch (e:Error)
			{
				reportError(e);
			}
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
   				printOrExportImage(visDesktop.internalCanvas);
   			}
   			
		}
	}
}
