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

package weave.data.DataSources
{
	import weave.api.newLinkableChild;
	import weave.api.setSessionState;
	import weave.api.data.IDataSource;
	import weave.core.ClassUtils;
	import weave.core.LinkableString;
	import weave.core.LinkableVariable;

	public class CachedDataSource extends AbstractDataSource
	{
		public const type:LinkableString = newLinkableChild(this, LinkableString);
		public const state:LinkableVariable = newLinkableChild(this, LinkableVariable);
		
		override protected function refreshHierarchy():void
		{
			var name:String = WeaveAPI.globalHashMap.getName(this);
			var classDef:Class = ClassUtils.getClassDefinition(type.value);
			var state:Object = this.state.state;
			var dataSource:IDataSource = WeaveAPI.globalHashMap.requestObject(name, classDef, false);
			setSessionState(dataSource, state);
		}
	}
}
