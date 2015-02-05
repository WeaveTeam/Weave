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
	import weave.api.core.IErrorManager;
	import weave.api.core.IExternalSessionStateInterface;
	import weave.api.core.ILinkableHashMap;
	import weave.api.core.ILocaleManager;
	import weave.api.core.IProgressIndicator;
	import weave.api.core.ISessionManager;
	import weave.api.core.IStageUtils;
	import weave.api.ui.IEditorManager;
	import weave.compiler.Compiler;
	import weave.core.ClassUtils;
	import weave.core.EditorManager;
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
		ClassUtils.registerDeprecatedClass('weave.api.WeaveAPI', WeaveAPI);
		
		/**
		 * Register singleton implementations for WeaveAPI framework classes
		 */
		WeaveAPI.ClassRegistry.registerSingletonImplementation(ISessionManager, SessionManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IStageUtils, StageUtils);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IErrorManager, ErrorManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IExternalSessionStateInterface, ExternalSessionStateInterface);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IProgressIndicator, ProgressIndicator);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(ILocaleManager, LocaleManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(IEditorManager, EditorManager);
		WeaveAPI.ClassRegistry.registerSingletonImplementation(ILinkableHashMap, LinkableHashMap);
		
		/**
		 * Include these packages in WeaveXMLDecoder so they will not need to be specified in the XML session state.
		 */
		WeaveXMLDecoder.includePackages(
			"weave",
			"weave.api",
			"weave.api.core",
			"weave.api.data",
			"weave.api.primitives",
			"weave.api.services",
			"weave.api.services.beans",
			"weave.api.ui",
			"weave.compiler",
			"weave.core",
			"weave.utils"
		);
	}
}
