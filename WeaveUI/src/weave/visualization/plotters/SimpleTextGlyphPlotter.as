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

package weave.visualization.plotters
{
	import weave.WeaveProperties;
	import weave.api.linkSessionState;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	import weave.core.LinkableString;
	import weave.data.AttributeColumns.DynamicColumn;
	
	/**
	 * SimpleTextGlyphPlotter
	 * 
	 * @author adufilie
	 */
	public class SimpleTextGlyphPlotter extends AbstractSimplifiedPlotter
	{
		public function SimpleTextGlyphPlotter()
		{
			super(TextGlyphPlotter);
			init();
		}
		
		private function init():void
		{
			// get the internal plotter being simplified
			var tgp:TextGlyphPlotter = internalPlotter as TextGlyphPlotter;
			// link public sessioned properties with the private ones
			var vars:Array = [
					font,      tgp.font.defaultValue,
					size,      tgp.size.defaultValue,
					color,     tgp.color.defaultValue,
					bold,      tgp.bold.defaultValue,
					italic,    tgp.italic.defaultValue,
					underline, tgp.underline.defaultValue,
					hAlign,    tgp.hAlign.defaultValue,
					vAlign,    tgp.vAlign.defaultValue,
					angle,     tgp.angle.defaultValue
				];
			for (var i:int = 0; i < vars.length; i += 2)
			{
				// register public properties that affect the appearance of the tick marks
				registerLinkableChild(this, vars[i]);
				// link private and public variables
				linkSessionState(vars[i + 1], vars[i]);
			}
			
			xPixelOffset.value = 0;
			yPixelOffset.value = 0;

			registerLinkableChild(this, text);
			registerLinkableChild(this, xPixelOffset);
			registerLinkableChild(this, yPixelOffset);
			registerSpatialProperty(xData);
			registerSpatialProperty(yData);
			
			setKeySource(text);
		}

		public function get text():DynamicColumn { return (internalPlotter as TextGlyphPlotter).text; }
		public function get xData():DynamicColumn { return (internalPlotter as TextGlyphPlotter).dataX; }
		public function get yData():DynamicColumn { return (internalPlotter as TextGlyphPlotter).dataY; }

		public const font:LinkableString = new LinkableString(WeaveProperties.DEFAULT_FONT_FAMILY, WeaveProperties.verifyFontFamily);
		public const size:LinkableNumber = new LinkableNumber();
		public const color:LinkableNumber = new LinkableNumber();

		public const bold:LinkableBoolean = new LinkableBoolean();
		public const italic:LinkableBoolean = new LinkableBoolean();
		public const underline:LinkableBoolean = new LinkableBoolean();
		
		public const hAlign:LinkableString = new LinkableString();
		public const vAlign:LinkableString = new LinkableString();
		public const angle:LinkableNumber = new LinkableNumber();

		public const xPixelOffset:LinkableNumber = new LinkableNumber();
		public const yPixelOffset:LinkableNumber = new LinkableNumber();
	}
}
