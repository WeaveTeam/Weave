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
	public class EmbeddedFonts
	{
		public static const SophiaNubian:String = "Sophia Nubian"; 
		
		[Embed(source="/weave/resources/fonts/SophiaNubian/SNR.ttf", fontName="Sophia Nubian", mimeType="application/x-font-truetype", fontWeight="normal")]
		private static const SophiaNubianFont:Class;
		
		[Embed(source="/weave/resources/fonts/SophiaNubian/SNB.ttf", fontName="Sophia Nubian", mimeType="application/x-font-truetype", fontWeight="bold")]
		private static const SophiaNubianBoldFont:Class;
		
//		public var ARIAL:String = "Arial"; 
//		[Embed(source="Arial.ttf", fontName="Arial", mimeType="application/x-font-truetype")]
//		private const ArialFont:Class;
//		
//		public var CETUS:String = "Cetus"; 
//		[Embed(source="Cetus.ttf", fontName="Cetus", mimeType="application/x-font-truetype")]
//		private const CetusFont:Class;       
//		
//		public var MYRIADWEBPRO:String = "Myriad Web Pro"; 
//		[Embed(source="MyriadWebPro.ttf", fontName="Myriad Web Pro", mimeType="application/x-font-truetype")]
//		private const MyriadWebProFont:Class;    
	}
}
