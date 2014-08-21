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

package weave.application
{
	import flash.display.LoaderInfo;
	import flash.events.ContextMenuEvent;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.SharedObject;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getQualifiedClassName;
	
	import mx.containers.VBox;
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.controls.Text;
	import mx.core.UIComponent;
	import mx.effects.Fade;
	import mx.events.EffectEvent;
	import mx.managers.PopUpManager;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.URLUtil;
	
	import spark.components.Group;
	
	import weave.Weave;
	import weave.WeaveProperties;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILinkableObject;
	import weave.api.data.IAttributeColumn;
	import weave.api.detectLinkableObjectChange;
	import weave.api.getCallbackCollection;
	import weave.api.registerDisposableChild;
	import weave.api.reportError;
	import weave.api.ui.IObjectWithSelectableAttributes;
	import weave.compiler.StandardLib;
	import weave.core.WeaveArchive;
	import weave.data.DataSources.WeaveDataSource;
	import weave.data.KeySets.KeySet;
	import weave.editors.SessionHistorySlider;
	import weave.editors.SingleImagePlotterEditor;
	import weave.services.LocalAsyncService;
	import weave.services.addAsyncResponder;
	import weave.ui.CirclePlotterSettings;
	import weave.ui.CustomContextMenuManager;
	import weave.ui.DraggablePanel;
	import weave.ui.ErrorLogPanel;
	import weave.ui.ExportSessionStateOptions;
	import weave.ui.NewUserWizard;
	import weave.ui.PenTool;
	import weave.ui.PrintPanel;
	import weave.ui.QuickMenuPanel;
	import weave.ui.WeaveProgressBar;
	import weave.ui.WizardPanel;
	import weave.ui.annotation.SessionedTextBox;
	import weave.ui.collaboration.CollaborationMenuBar;
	import weave.ui.controlBars.VisTaskbar;
	import weave.ui.controlBars.WeaveMenuBar;
	import weave.utils.ColumnUtils;
	import weave.utils.DebugTimer;
	import weave.utils.VectorUtils;
	import weave.utils.fixErrorMessage;

	internal class VisApplication extends VBox implements ILinkableObject
	{
		MXClasses; // Referencing this allows all Flex classes to be dynamically created at runtime.
		
		/**
		 * Constructor.
		 */
		public function VisApplication()
		{
			super();
			registerDisposableChild(Weave.properties, this);

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
			
			percentWidth = 100;
			percentHeight = 100;

			callLater(waitForApplicationComplete);
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
						var error:Error = event.error;
						// ignore IME error
						if (error.errorID == 2063)
							return;
						
						fixErrorMessage(error)
						reportError(error);
					}
				);
			} catch (e:Error) { }
			
			// resize to parent size each frame because percentWidth,percentHeight doesn't seem reliable when application is nested
			addEventListener(Event.ENTER_FRAME, updateWorkspaceSize);
			
			getCallbackCollection(WeaveAPI.ErrorManager).addGroupedCallback(this, handleError, WeaveAPI.ErrorManager.errors.length > 0);
			Weave.properties.enableCollaborationBar.addGroupedCallback(this, toggleCollaborationMenuBar);
			getCallbackCollection(Weave.properties).addGroupedCallback(this, refreshMenu);
			Weave.properties.backgroundColor.addImmediateCallback(this, invalidateDisplayList, true);

			getFlashVars();
			handleFlashVarPresentation();
			handleFlashVarAllowDomain();
			
			// disable application until it's ready
			enabled = false;
			
			if (getAdminConnectionName())
			{
				// disable interface while connecting to admin console
				var _this:VisApplication = this;
				_this.enabled = false;
				
				var pendingAdminService:LocalAsyncService = new LocalAsyncService(this, false, getAdminConnectionName());
				addAsyncResponder(
					pendingAdminService.invokeAsyncMethod("ping"),
					function(event:ResultEvent, token:Object = null):void
					{
						// when admin console responds, set adminService
						adminService = pendingAdminService;
						saveTimer.addEventListener(TimerEvent.TIMER, saveRecoverPoint);
						saveTimer.start();
						
						_this.enabled = true;
						refreshMenu(); // make sure 'save session state to server' is shown
						downloadConfigFile();
					},
					function(event:FaultEvent = null, token:Object = null):void
					{
						Alert.show(lang("Unable to connect to the Admin Console.\nYou will not be able to save your session state to the server."), lang("Connection error"));
						
						_this.enabled = true;
						refreshMenu();
						downloadConfigFile();
					}
				);
			}
			else
			{
				downloadConfigFile();
			}

			if (JavaScript.available)
			{
				JavaScript.registerMethod('loadFile', loadFile);
				WeaveAPI.initializeJavaScript(_InitializeWeaveData.WeavePathData);
			}
		}

		private function handleError():void
		{
			if (Weave.properties.showErrors.value)
				ErrorLogPanel.openErrorLog();
		}
		
		private var _requestedConfigFile:String;
		private function setRequestedConfigFile(value:String):void
		{
			if (_requestedConfigFile == value)
				return;
			_requestedConfigFile = value;
			_loadFileCallbacks.length = 0;
		}
		private var _loadFileCallbacks:Array = [];
		/**
		 * Loads a session state file from a URL.
		 * @param url The URL to the session state file (.weave or .xml) specified as a String, a URLRequest, or an Object containing properties "url", "requestHeaders", "method".
		 *            Example:  {"url": "myfile.ext", "requestHeaders": {"Content-type", "foo"}, method: "POST"}
		 * @param callback This function will be invoked when the file loading completes.
		 * @param noCacheHack If set to true, appends "?" followed by a series of numbers to prevent Flash from using a cached version of the file.  Only works when url is given as a String.
		 */
		public function loadFile(url:Object, callback:Function = null, noCacheHack:Boolean = false):void
		{
			var request:URLRequest;
			if (url is URLRequest)
			{
				request = url as URLRequest;
				setRequestedConfigFile(request.url);
			}
			else if (url is String)
			{
				setRequestedConfigFile(String(url));
				if (noCacheHack)
					url = String(url) + "?" + (new Date()).getTime(); // prevent flex from using cache
				request = new URLRequest(String(url));
			}
			else
			{
				request = new URLRequest(String(url['url']));
				request.method = url['method'] || URLRequestMethod.GET;
				var headers:Object = url['requestHeaders'];
				for (var k:String in headers)
					request.requestHeaders.push(new URLRequestHeader(k, headers[k]));
				setRequestedConfigFile(request.url);
			}
			
			if (callback != null)
				_loadFileCallbacks.push(callback);
			
			WeaveAPI.URLRequestUtils.getURL(null, request, handleConfigFileDownloaded, handleConfigFileFault, _requestedConfigFile);
		}
		
		private function downloadConfigFile():void
		{
			if (getFlashVarRecover() || Weave.handleWeaveReload())
			{
				handleConfigFileDownloaded();
			}
			else
			{
				var fileName:String = getFlashVarFile() || DEFAULT_CONFIG_FILE_NAME;
				loadFile(fileName, null, true);
			}
		}
		private function handleConfigFileDownloaded(event:ResultEvent = null, fileName:String = null):void
		{
			if (!event)
			{
				loadSessionState(null, null);
			}
			else
			{
				// ignore old requests
				if (fileName != _requestedConfigFile)
					return;
				if (Capabilities.playerType == "Desktop")
					WeaveAPI.URLRequestUtils.setBaseURL(fileName);
				loadSessionState(event.result, fileName);
			}
			
			// if "editable" was explicitly set to false, disable menu bar and enable dashboard mode.
			if (getFlashVarEditable() === false) // explicit compare because it may also be undefined
			{
				Weave.properties.enableMenuBar.value = false;
				Weave.properties.dashboardMode.value = true;
			}
			WeaveAPI.callExternalWeaveReady();
			while (_loadFileCallbacks.length)
				(_loadFileCallbacks.shift() as Function)();
		}
		private function handleConfigFileFault(event:FaultEvent, fileName:String):void
		{
			// don't report an error if no filename was specified
			var noFileName:Boolean = !getFlashVarFile();
			if (noFileName)
			{
				// for default fallback configuration, create a WeaveDataSource
				WeaveAPI.globalHashMap.requestObject(null, WeaveDataSource, false);
				
				// if not opened from admin console, enable interface now
				if (!getAdminConnectionName())
					this.enabled = true;
				WeaveAPI.callExternalWeaveReady();
			}
			else
			{
				reportError(event);
				if (event.fault.faultCode == SecurityErrorEvent.SECURITY_ERROR)
					Alert.show(lang("The server hosting the configuration file does not have a permissive crossdomain policy."), lang("Security sandbox violation"));
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			var color:Number = Weave.properties.backgroundColor.value;
			this.graphics.clear();
			this.graphics.beginFill(color);
			this.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
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
		
		private function handleFlashVarPresentation():void
		{
			var presentationMode:Boolean = StandardLib.asBoolean(_flashVars['presentation']);
			Weave.history.enableLogging.value = !presentationMode;
		}
		
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
		
		private static const ADMIN_SESSION_WINDOW_NAME_PREFIX:String = "WeaveAdminSession";
		private function getAdminConnectionName():String
		{
			if (JavaScript.available)
			{
				var windowName:String = JavaScript.exec("return window.name;");
				if (windowName && windowName.indexOf(ADMIN_SESSION_WINDOW_NAME_PREFIX) == 0)
					return windowName.substr(ADMIN_SESSION_WINDOW_NAME_PREFIX.length);
			}
			return null;
		}
		private function getFlashVarRecover():Boolean
		{
			return StandardLib.asBoolean(_flashVars['recover']);
		}
		
		/**
		 * Gets the name of the config file.
		 */
		private function getFlashVarFile():String
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
				return StandardLib.asBoolean(_flashVars[name]);
			return undefined;
		}
		
		public function setFlashVars(vars:Object):void
		{
			_flashVars = vars;
		}
		
		/**
		 * Gets the flash vars.
		 */
		private function getFlashVars():void
		{
			if (_flashVars)
				return;
			
			// We want FlashVars to take priority over the address bar parameters.
			_flashVars = LoaderInfo(this.root.loaderInfo).parameters;
			
			// check address bar for any variables not found in FlashVars
			try
			{
				var paramsStr:String = JavaScript.exec("return window.location.search.substring(1);") || ''; // text after '?'
				var paramsObj:Object = URLUtil.stringToObject(paramsStr, '&');
				for (var key:String in paramsObj)
					if (!_flashVars.hasOwnProperty(key)) // flashvars take precedence over url params
						_flashVars[key] = paramsObj[key];
				
				// backwards compatibility with old param name
				const DEPRECATED_FILE_PARAM_NAME:String = 'defaults';
				if (!_flashVars.hasOwnProperty(CONFIG_FILE_FLASH_VAR_NAME) && paramsObj.hasOwnProperty(DEPRECATED_FILE_PARAM_NAME))
				{
					_flashVars[CONFIG_FILE_FLASH_VAR_NAME] = paramsObj[DEPRECATED_FILE_PARAM_NAME];
					_usingDeprecatedFlashVar = true;
				}
			}
			catch(e:Error)
			{
				reportError(e);
			}
		}
		private static const CONFIG_FILE_FLASH_VAR_NAME:String = 'file';
		private static const DEFAULT_CONFIG_FILE_NAME:String = 'defaults.xml';
		private var _usingDeprecatedFlashVar:Boolean = false;
		private const DEPRECATED_FLASH_VAR_MESSAGE:String = lang("The 'defaults=' URL parameter is deprecated.  Use 'file=' instead.");

		private var _selectionIndicatorText:Text = new Text();
		private var selectionKeySet:KeySet = Weave.defaultSelectionKeySet;
		private function handleSelectionChange():void
		{
			_selectionIndicatorText.text = lang("{0} Records Selected", selectionKeySet.keys.length.toString());
			try
			{
				var show:Boolean = Weave.properties.showSelectedRecordsText.value && selectionKeySet.keys.length > 0;
				if (show)
				{
					if (visDesktop != _selectionIndicatorText.parent)
						visDesktop.addChild(_selectionIndicatorText);
						
					if( Weave.properties.recordsTooltipLocation.value == WeaveProperties.RECORDS_TOOLTIP_LOWER_LEFT ){
						_selectionIndicatorText.setStyle( "left", 0 ) ;
						_selectionIndicatorText.setStyle( "right", null ) ;
					}
					else if( Weave.properties.recordsTooltipLocation.value == WeaveProperties.RECORDS_TOOLTIP_LOWER_RIGHT ){
						_selectionIndicatorText.setStyle( "right", 0 ) ;
						_selectionIndicatorText.setStyle( "left", null ) ;
					}	
				}
				else
				{
					if (visDesktop == _selectionIndicatorText.parent)
						visDesktop.removeChild(_selectionIndicatorText);
				}
			}
			catch (e:Error)
			{
				reportError(e);
			}
		}
		
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
			Weave.properties.recordsTooltipLocation.addGroupedCallback(this, handleSelectionChange, true);
			
			_selectionIndicatorText.setStyle("color", 0xFFFFFF);
			_selectionIndicatorText.opaqueBackground = 0x000000;
			_selectionIndicatorText.setStyle("bottom", 0);
			_selectionIndicatorText.setStyle("left", 0);
			
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
			if (!this.parent || !Weave.properties)
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
			
			var workspace:Group = visDesktop.workspace;
			var multiplier:Number = Weave.properties.workspaceMultiplier.value;
			var scale:Number = 1 / multiplier;
			workspace.scaleX = scale;
			workspace.scaleY = scale;
			workspace.width = workspace.parent.width * multiplier;
			workspace.height = workspace.parent.height * multiplier;
			handleScreenshotImageSize();
		}
	
		private function handleScreenshotImageSize():void
		{
			if (_screenshot)
			{
				if (WeaveAPI.ErrorManager.errors.length)
				{
					handleRemoveScreenshot();
					return;
				}
				_screenshot.width = this.width;
				_screenshot.height = this.height;
			}
		}
		
		public function get adminMode():Boolean { return getFlashVarEditable() || adminService; }
		public var adminService:LocalAsyncService = null;

		private const saveTimer:Timer = new Timer( 10000 );
		private static const RECOVER_SHARED_OBJECT:String = "WeaveAdminConsoleRecover";
		private function saveRecoverPoint(event:Event = null):void
		{
			if (detectLinkableObjectChange(saveRecoverPoint, WeaveAPI.globalHashMap))
			{
				var cookie:SharedObject = SharedObject.getLocal(RECOVER_SHARED_OBJECT);
				cookie.data[RECOVER_SHARED_OBJECT] = Weave.createWeaveFileContent();
				cookie.flush();
			}
		}
		private function getRecoverPoint():ByteArray
		{
			var cookie:SharedObject = SharedObject.getLocal(RECOVER_SHARED_OBJECT);
			return cookie.data[RECOVER_SHARED_OBJECT] as ByteArray;
		}
		
		public function saveSessionStateToServer():void
		{
			if (adminService == null)
			{
				Alert.show(lang("Not connected to Admin Console."), lang("Error"));
				return;
			}
			
			if (!Weave.fileName)
				Weave.fileName = getFlashVarFile().split("/").pop();
			
			ExportSessionStateOptions.openExportPanel(
				"Save session state to server",
				function(content:Object):void
				{
					addAsyncResponder(
						adminService.invokeAsyncMethod('saveWeaveFile', [content, Weave.fileName, true]),
						function(event:ResultEvent, fileName:String):void
						{
							Alert.show(String(event.result), lang("Admin Console Response"));
						},
						function(event:FaultEvent, fileName:String):void
						{
							reportError(event.fault, lang("Unable to connect to Admin Console"));
						},
						Weave.fileName
					);
				}
			);
		}
		
		// this function may be called by the Admin Console to close this window, needs to be public
		public function closeWeavePopup():void
		{
			JavaScript.exec("window.close();");
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

		private var menuBar:WeaveMenuBar = null;
		private var historySlider:UIComponent = null;
		
		private function refreshMenu():void
		{
			if (!enabled)
			{
				callLater(refreshMenu);
				return;
			}
			
			setupContextMenu();
			
			DraggablePanel.adminMode = adminMode;
			
			// create components if not already created
			if (!menuBar)
			{
				menuBar = new WeaveMenuBar();
				this.addChildAt(menuBar, 0);
			}
			if (!historySlider)
			{
				historySlider = WeaveAPI.EditorManager.getNewEditor(Weave.history) as UIComponent;
				var shs:SessionHistorySlider = historySlider as SessionHistorySlider;
				if (shs)
					shs.squashActive.addImmediateCallback(this, function():void{
						visDesktop.mouseChildren = !shs.squashActive.value;
					});
				
				if (historySlider)
					this.addChildAt(historySlider, this.getChildIndex(visDesktop));
				else
					reportError("Unable to get editor for SessionStateLog");
			}
			
			const alpha_full:Number = 1.0;
			const alpha_partial:Number = 0.3;
			
			// show/hide menuBar
			var showMenu:Boolean = Weave.properties.enableMenuBar.value || adminMode;
			menuBar.visible = menuBar.includeInLayout = showMenu;
			menuBar.alpha = Weave.properties.enableMenuBar.value ? alpha_full : alpha_partial;
			if (showMenu)
				menuBar.refresh();
			
			// show/hide historySlider
			if (historySlider)
			{
				var showHistory:Boolean = Weave.properties.enableSessionHistoryControls.value || adminMode;
				historySlider.visible = historySlider.includeInLayout = showHistory;
				historySlider.alpha = Weave.properties.enableSessionHistoryControls.value ? alpha_full : alpha_partial;
			}
		}

		public function CSVWizardWithData(content:Object):void
		{
			var newUserWiz:NewUserWizard = new NewUserWizard();
			WizardPanel.createWizard(this, newUserWiz);
			newUserWiz.CSVFileDrop(content as ByteArray);
		}
		
		private var _screenshot:Image = null;
		private var _screenshotTimer:Timer = new Timer(1000);
		public function loadSessionState(fileContent:Object, fileName:String):void
		{
			DebugTimer.begin();
			try
			{
				if (getFlashVarRecover())
					fileContent = getRecoverPoint();
				// attempt to parse as a Weave archive
				if (fileContent)
				{
					Weave.loadWeaveFileContent(ByteArray(fileContent));
					if (_usingDeprecatedFlashVar)
						reportError(DEPRECATED_FLASH_VAR_MESSAGE);
				}
				if (fileName)
					Weave.fileName = fileName.split('/').pop();
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
					Weave.loadWeaveFileContent(xml);
					Weave.fileName = fileName;
				}
			}
			DebugTimer.end('loadSessionState', fileName);
			var ssba:ByteArray = WeaveAPI.URLRequestUtils.getLocalFile(WeaveArchive.ARCHIVE_SCREENSHOT_PNG);
			if (ssba)
			{
				_screenshot = new Image();
				_screenshot.source = ssba;
				_screenshot.maintainAspectRatio = false;
				_screenshot.smoothBitmapContent = true;
				handleScreenshotImageSize();
				if (_screenshot)
				{
					PopUpManager.addPopUp(_screenshot,this,false);
					PopUpManager.bringToFront(_screenshot);
					_screenshotTimer.addEventListener(TimerEvent.TIMER,handleScreenshotTimer);
					_screenshotTimer.start();
				}
			}
			callLater(refreshMenu);
			
			if (!getAdminConnectionName())
				enabled = true;
			

			// generate the context menu items
			setupContextMenu();

			// Set the name of the CSS style we will be using for this application.  If weaveStyle.css is present, the style for
			// this application can be defined outside the code in a CSS file.
			this.styleName = "application";	
		}
		
		private var fadeEffect:Fade = new Fade();
		private function handleScreenshotTimer(event:Event):void
		{
			if(WeaveAPI.ProgressIndicator.getNormalizedProgress() ==1)
			{
				fadeEffect.alphaFrom = _screenshot.alpha;
				fadeEffect.alphaTo = 0;
				fadeEffect.duration = 500;
				fadeEffect.target = _screenshot;
				fadeEffect.addEventListener(EffectEvent.EFFECT_END,handleRemoveScreenshot);
				fadeEffect.play();
			}
		}
		
		private function handleRemoveScreenshot(event:Event=null):void
		{
			if (_screenshot)
			{
				_screenshotTimer.stop();
				_screenshotTimer.removeEventListener(TimerEvent.TIMER,handleScreenshotTimer);
				PopUpManager.removePopUp(_screenshot);
				_screenshot = null;
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
		public function setupContextMenu():void
		{ 
			contextMenu = new ContextMenu();
			contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
			
			// Hide the default Flash menu
			try
			{
				contextMenu['hideBuiltInItems']();
			}
			catch (e:Error)
			{
			}
			
			CustomContextMenuManager.removeAllContextMenuItems();
			
			if (Weave.properties.enableRightClick.value)
			{
				// Add context menu item for selection related items (subset creation, etc)	
				if (Weave.properties.enableSubsetControls.value)
				{
					KeySetContextMenuItems.createContextMenuItems(this);
				}
				if (Weave.properties.enableMarker.value)
					SingleImagePlotterEditor.createContextMenuItems(this);
				
				if (Weave.properties.enableDrawCircle.value)
					CirclePlotterSettings.createContextMenuItems(this);
				
				if (Weave.properties.enableAnnotation.value)
					SessionedTextBox.createContextMenuItems(this);
				
				if (Weave.properties.enablePenTool.value)
					PenTool.createContextMenuItems(this);
				
				if (Weave.properties.enableExportToolImage.value)
				{
					// Add a listener to this destination context menu for when it is opened
					//contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
					
					// Create a context menu item for printing of a single tool with title and logo
					_panelPrintContextMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(
						lang("Print/Export Image of {0}", '...'),
						this,
						function(event:ContextMenuEvent):void { printOrExportImage(_panelToExport); },
						"4 exportMenuItems"
					);
					// By default this menu item is disabled so that it does not show up unless we right click on a tool
					_panelPrintContextMenuItem.enabled = false;
				}
				
				if (Weave.properties.enableExportApplicationScreenshot.value)
					_printToolMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(lang("Print/Export Application Image"), this, handleContextMenuItemSelect, "4 exportMenuItems");
				
				if (Weave.properties.enableExportCSV.value)
				{
					// Add a listener to this destination context menu for when it is opened
					//contextMenu.addEventListener(ContextMenuEvent.MENU_SELECT, handleContextMenuOpened);
					
					// Create a context menu item for printing of a single tool with title and logo
					_exportCSVContextMenuItem = CustomContextMenuManager.createAndAddMenuItemToDestination(
						lang("Export CSV"), 
						this,
						function(event:ContextMenuEvent):void { exportCSV(_panelToExport as IObjectWithSelectableAttributes); },
						"4 exportMenuItems"
					);
				}
				
				// Add context menu items for handling search queries
				if (Weave.properties.enableSearchForRecord.value)
					SearchEngineUtils.createContextMenuItems(this);
				
				if (Weave.properties.dataInfoURL.value)
					addLinkContextMenuItem(lang("Show Information About This Dataset..."), Weave.properties.dataInfoURL.value);
				
			}
		}

		// Create the context menu items for exporting panel images.  
		private var _panelPrintContextMenuItem:ContextMenuItem = null;
		private  var _exportCSVContextMenuItem:ContextMenuItem = null;
		private var exportCSVfileRef:FileReference = new FileReference();	// CSV download file references
		public function getSelectableAttributes(tool:IObjectWithSelectableAttributes = null):Array
		{
			var attrs:Array = [];
			if (tool)
			{
				VectorUtils.flatten(tool.getSelectableAttributes(), attrs);
			}
			else
			{
				// get equation columns and color column
				VectorUtils.flatten(WeaveAPI.globalHashMap.getObjects(IAttributeColumn), attrs);
				// get probe columns
				VectorUtils.flatten(WeaveAPI.globalHashMap.getObjects(ILinkableHashMap), attrs);
				for each (var tool:IObjectWithSelectableAttributes in WeaveAPI.globalHashMap.getObjects(IObjectWithSelectableAttributes))
					VectorUtils.flatten(tool.getSelectableAttributes(), attrs);
			}
			return attrs;
		}
			
		public function exportCSV(tool:IObjectWithSelectableAttributes = null):void
		{
			try
			{
				var fileName:String = tool
					? getQualifiedClassName(tool).split(':').pop()
					: "data-export";
				fileName = "Weave-" + fileName + ".csv";
				
				var attrs:Array = getSelectableAttributes(tool);
				var csvString:String = ColumnUtils.generateTableCSV(attrs, Weave.defaultSubsetKeyFilter);
				if (!csvString)
				{
					reportError("No data to export");
					return;
				}
				
				exportCSVfileRef.save(csvString, fileName);
			}
			catch (e:Error)
			{
				reportError(e);
			}			
		}
		
		// Handler for when the context menu is opened.  In here we will keep track of what tool we were over when we right clicked so 
		// that we can export an image of just this tool.  We also change the text in the context menu item for exporting an image of 
		// this tool so it  says the name of the tool to export.
		private var _panelToExport:DraggablePanel = null;
		private function handleContextMenuOpened(event:ContextMenuEvent):void
		{
			// When the context menu is opened, save a pointer to the active tool, this is the tool we want to export an image of
			_panelToExport = DraggablePanel.activePanel;
			CustomContextMenuManager.activePanel = DraggablePanel.activePanel;
			
			if (_panelPrintContextMenuItem)
			{
				// If this tool is valid (we are over a tool), then we want this menu item enabled, otherwise don't allow users to choose it
				_panelPrintContextMenuItem.caption = lang("Print/Export Image of {0}", _panelToExport ? _panelToExport.title : "...");
				_panelPrintContextMenuItem.enabled = (_panelToExport != null);
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
   			//add current screenshot to Print Format
			printPopUp.componentToScreenshot = component;
		}

		/** 
		 * Add a context menu item that goes to an associated url in a new browser window/tab
		 */
		private function addLinkContextMenuItem(text:String, url:String, separatorBefore:Boolean=false):void
		{
			CustomContextMenuManager.createAndAddMenuItemToDestination(text, 
															  this, 
                                                              function(e:Event):void { navigateToURL(new URLRequest(url), "_blank"); },
                                                              "4 linkMenuItems");	
		}

		/**
		 * @TODO This should be removed -- ideally VisApplication has no context menu items itself, only other classes do
		 */
		protected function handleContextMenuItemSelect(event:ContextMenuEvent):void
		{
			if (event.currentTarget == _printToolMenuItem)
   			{
   				printOrExportImage(visDesktop.workspace);
   			}
   			
		}
	}
}
