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

package
{
	import mx.managers.CursorManager;
	import mx.managers.ICursorManager;
	
	import weave.api.WeaveAPI;
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILocaleManager;
	import weave.api.core.IProgressIndicator;
	import weave.api.core.ISessionManager;
	import weave.api.core.IStageUtils;
	import weave.api.ui.ICollabCursorManager;
	import weave.core.ErrorManager;
	import weave.core.ExternalSessionStateInterface;
	import weave.core.LinkableHashMap;
	import weave.core.LocaleManager;
	import weave.core.ProgressIndicator;
	import weave.core.SessionManager;
	import weave.core.StageUtils;
	import weave.core.WeaveXMLDecoder;

	public class _InitializeWeaveCore
	{
		/**
		 * Register singleton implementations for WeaveAPI framework classes
		 */
		WeaveAPI.registerSingleton(ISessionManager, SessionManager);
		WeaveAPI.registerSingleton(IStageUtils, StageUtils);
		WeaveAPI.registerSingleton(IErrorManager, ErrorManager);
		WeaveAPI.registerSingleton(IExternalSessionStateInterface, ExternalSessionStateInterface);
		WeaveAPI.registerSingleton(IProgressIndicator, ProgressIndicator);
		WeaveAPI.registerSingleton(ILocaleManager, LocaleManager);
		WeaveAPI.registerSingleton(ILinkableHashMap, LinkableHashMap);
		
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave",
			"weave.utils"
		);
	}
}
