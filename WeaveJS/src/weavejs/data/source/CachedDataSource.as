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

package weavejs.data.source
{
	import weavejs.api.core.ILinkableHashMap;
	import weavejs.api.data.IDataSource;
	import weavejs.core.LinkableString;
	import weavejs.core.LinkableVariable;

	public class CachedDataSource extends AbstractDataSource
	{
		public const type:LinkableString = Weave.linkableChild(this, LinkableString);
		public const state:LinkableVariable = Weave.linkableChild(this, LinkableVariable);
		
		override protected function refreshHierarchy():void
		{
			var root:ILinkableHashMap = Weave.getRoot(this);
			var name:String = root.getName(this);
			var classDef:Class = Weave.getDefinition(type.value);
			var state:Object = this.state.state;
			var dataSource:IDataSource = root.requestObject(name, classDef, false);
			Weave.setState(dataSource, state);
		}
	}
}
