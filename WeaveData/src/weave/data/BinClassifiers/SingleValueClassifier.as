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

package weave.data.BinClassifiers
{
	import weave.api.data.IBinClassifier;
	import weave.api.data.IPrimitiveColumn;
	import weave.api.newLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.UntypedLinkableVariable;
	import weave.data.AttributeColumns.StringColumn;
	
	/**
	 * This classifies a single value.
	 * 
	 * @author adufilie
	 */
	public class SingleValueClassifier extends UntypedLinkableVariable implements IBinClassifier
	{
		/**
		 * @param value A value to test.
		 * @return true If this IBinClassifier contains the given value.
		 */
		public function contains(value:*):Boolean
		{
			return sessionStateEquals(value);
		}
	}
}
