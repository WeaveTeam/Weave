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
package weave.resources.fonts
{
	import flash.text.Font;

	public class EmbeddedFonts
	{
		public static const SophiaNubian:String = "Sophia Nubian"; 
		
		[Embed(source="/weave/resources/fonts/SophiaNubian/SNR.ttf", fontWeight="normal", fontName="Sophia Nubian", fontFamily="Sophia Nubian", mimeType="application/x-font-truetype")]
		private static const SophiaNubianRegularTTF:Class;
		
		[Embed(source="/weave/resources/fonts/SophiaNubian/SNB.ttf", fontWeight="bold", fontName="Sophia Nubian", fontFamily="Sophia Nubian", mimeType="application/x-font-truetype")]
		private static const SophiaNubianBoldTTF:Class;
		
		{
			Font.registerFont(SophiaNubianRegularTTF);
			Font.registerFont(SophiaNubianBoldTTF);
		}
	}
}
