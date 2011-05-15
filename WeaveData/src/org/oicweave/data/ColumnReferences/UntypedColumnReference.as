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

package org.oicweave.data.ColumnReferences
{
	import org.oicweave.core.LinkableDynamicObject;
	import org.oicweave.core.UntypedLinkableVariable;
	import org.oicweave.api.core.ILinkableObject;
	import org.oicweave.api.newLinkableChild;

	/**
	 * This is a column reference that has no particular structure.
	 * This class can be used as a temporary solution when developing an
	 * IDataSource until the structure of the column reference is decided upon.
	 * 
	 * @author adufilie
	 */
	[Deprecated] public class UntypedColumnReference extends AbstractColumnReference
	{
		public function UntypedColumnReference()
		{
		}
		
		/**
		 * This is the unstructured information used to request a column.
		 */
		public const metadata:UntypedLinkableVariable = newLinkableChild(this, UntypedLinkableVariable);
	}
}
