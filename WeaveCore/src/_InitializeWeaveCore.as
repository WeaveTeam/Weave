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
