package
{
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	
	public class Demo implements ILinkableObject
	{
		public const alpha_border:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.75));
		public const alpha_content:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.2));
		public const alpha_overlap:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.3));
		
		public const color_border:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const color_content:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const color_overlap:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xFF0000));
		public const color_locked:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xFFFF00));
		
		public const filterWithinImportanceRange:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const lock_geomFiltering:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const lock_tileFiltering:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public const show_singleTileID:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const show_border:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const show_content:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const show_overlap:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const show_rectangles:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		
		public static function get settings():Demo { return _demo || (_demo = new Demo()); }
		private static var _demo:Demo;
	}
}
