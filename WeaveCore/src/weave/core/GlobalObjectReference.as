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

package weave.core
{
	import flash.utils.getQualifiedClassName;
	
	import weave.api.core.ILinkableObject;
	
	/**
	 * This is a dummy class that serves as no more than a qualified class name.
	 * 
	 * @author adufilie
	 */
	[ExcludeClass]
	public final class GlobalObjectReference implements ILinkableObject
	{
		public static const qualifiedClassName:String = getQualifiedClassName(GlobalObjectReference);
		
		public function GlobalObjectReference(Please:_do_not_call_this_constructor) { }
	}
}
internal class _do_not_call_this_constructor { }
