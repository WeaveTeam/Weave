package
{
	import weave.api.core.ILinkableObject;
	import weave.api.registerLinkableChild;
	import weave.core.LinkableBoolean;
	import weave.core.LinkableNumber;
	
	public class Demo implements ILinkableObject
	{
		public static function get settings():Demo { return _demo || (_demo = new Demo()); }
		private static var _demo:Demo;
		
		public const alpha_border:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.3));
		public const alpha_pointBounds:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.2));
		public const alpha_queryBounds:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0.3));
		public const color_lockedBounds:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000080));
		public const color_pointBounds:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0x000000));
		public const color_queryBounds:LinkableNumber = registerLinkableChild(this, new LinkableNumber(0xFF0000));
		public const filterWithinImportanceRange:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const lock_geomFiltering:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const lock_tileFiltering:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const show_singleTileID:LinkableNumber = registerLinkableChild(this, new LinkableNumber());
		public const show_pointBounds:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
		public const show_queryBounds:LinkableBoolean = registerLinkableChild(this, new LinkableBoolean(false));
	}
}
