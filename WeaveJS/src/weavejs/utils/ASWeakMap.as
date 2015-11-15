package weavejs.utils
{
	import weavejs.Weave;

	public dynamic class ASWeakMap
	{
		public function ASWeakMap()
		{
			var Dictionary:Class = Weave.getDefinition('flash.utils.Dictionary');
			d = new Dictionary(true);
			
			this['delete'] = this.remove;
		}
		
		public var d:Object;
		
		public function get(key:*):* { return d[key]; }
		public function set(key:*, value:*):* { return d[key] = value; }
		public function has(key:*):Boolean { return d.hasOwnProperty(key); }
		public function remove(key:*):* { return delete d[key]; }
	}
}