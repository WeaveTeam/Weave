/*
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL
	was not distributed with this file, You can obtain
	one at https://mozilla.org/MPL/2.0/.
*/
package weavejs.path
{
	import weavejs.WeaveAPI;
	import weavejs.api.core.ILinkableObject;
	import weavejs.api.data.IAttributeColumn;
	import weavejs.api.data.IDataSource;
	import weavejs.api.data.IKeySet;
	import weavejs.api.data.IKeySetCallbackInterface;
	import weavejs.data.ColumnUtils;
	import weavejs.data.column.DynamicColumn;
	import weavejs.data.column.ExtendedDynamicColumn;
	import weavejs.data.column.ReferencedColumn;
	import weavejs.util.JS;

	public class WeavePathData extends WeavePath
	{
		public function WeavePathData(weave:Weave, basePath:Array)
		{
			super(weave, basePath);
			
			var shared:WeavePathDataShared = map_weave.get(weave);// as WeavePathDataShared;
			if (!shared)
			{
				map_weave.set(weave, shared = new WeavePathDataShared());
				// init() must be called AFTER caching in map_weave to avoid infinite recursion
				shared.init(weave);
			}
			
			this.shared = shared;
			
			this.probe_keyset = shared.probe_keyset;
			this.selection_keyset = shared.selection_keyset;
			this.subset_filter = shared.subset_filter;
			
			this.qkeyToString = shared.qkeyToString;
			this.stringToQKey = shared.stringToQKey;
			this.indexToQKey = shared.indexToQKey;
			this.qkeyToIndex = shared.qkeyToIndex;
		}
		
		private static var map_weave:Object = new JS.WeakMap();
		
		private var shared:WeavePathDataShared;
		
		public var probe_keyset:WeavePath;
		public var selection_keyset:WeavePath;
		public var subset_filter:WeavePath;
		
		public var qkeyToString:Function;
		public var stringToQKey:Function;
		public var indexToQKey:Function;
		public var qkeyToIndex:Function;
		
		/**
		 * Creates a new property based on configuration stored in a property descriptor object. 
		 * See initProperties for documentation of the property_descriptor object.
		 * @param callback_pass If false, create object, verify type, and set default value; if true, add callback;
		 * @param property_descriptor An object containing, minimally, a 'name' property defining the name of the session state element to be created.
		 * @private
		 * @return The current WeavePath object.
		 */
		private function _initProperty(manifest, callback_pass, property_descriptor):WeavePath
		{
		    var name:String = property_descriptor["name"]
		    	|| _failMessage('initProperty', 'A "name" is required');
		    var label:String = property_descriptor["label"];
		    var children:Array = property_descriptor["children"];
		    var type:String = property_descriptor["type"];
			if (!type)
				type = children ? "LinkableHashMap" : "LinkableVariable";
		    
		    var new_prop:WeavePathData = this.push(name) as WeavePathData;
		
		    if (callback_pass)
		    {
		        var callback:Function = property_descriptor["callback"];
		        var triggerNow:* = property_descriptor["triggerNow"];
		        var immediate:* = property_descriptor["immediate"];
		        if (callback)
		            new_prop.addCallback(
						new_prop,
		                callback,
		                triggerNow !== undefined ? triggerNow : true,
		                immediate !== undefined ? immediate : false
		            );
		    }
		    else
		    {
		        var oldType:String = new_prop.getType();
		        
		        type = new_prop.request(type).getType();
		
		        if (label)
		        {
		            new_prop.label(label);
		        }
		
		        if (oldType != type && property_descriptor.hasOwnProperty("default"))
		        {
		            new_prop.state(property_descriptor["default"]);
		        }
		
		        manifest[name] = new_prop;
		    }
		
		    if (children)
		    {
		        if (!callback_pass)
		            manifest[name] = {};
		        children.forEach(this._initProperty.bind(new_prop, manifest[name], callback_pass));
		    }
		
		    return this;
		}
		
		/**
		 * Creates a set of properties for a tool from an array of property descriptor objects.
		 * Each property descriptor can contain the follow properties:
		 * 'name': Required, specifies the name for the session state item.
		 * 'children': Optionally, another array of property descriptors to create as children of this property.
		 * 'label': A human-readable display name for the session state item.
		 * 'type': A Weave session variable type; defaults to "LinkableVariable," or "LinkableHashMap" if children is defined.
		 * 'callback': A function to be called when this session state item (or a child of it) changes.
		 * 'triggerNow': Specify whether to trigger the callback after it is added; defaults to 'true.'
		 * 'immediate': Specify whether to execute the callback in immediate (once per change) or grouped (once per frame) mode.
		 * @param {Array} property_descriptor_array An array of property descriptor objects, each minimally containing a 'name' property.
		 * @param {object} manifest An object to populate with name->path relationships for convenience.
		 * @return {object} The manifest.
		 */
		private function initProperties(property_descriptor_array:Array, manifest:Object = null):Object
		{
		    if (this.getType() == null) 
		        this.request("ExternalTool");
		
		    if (!manifest)
		        manifest = {};
		
		    /* Creation and default-setting pass */
		    property_descriptor_array.forEach(this._initProperty.bind(this, manifest, false));
		    /* Attaching callback pass */
		    property_descriptor_array.forEach(this._initProperty.bind(this, manifest, true));
		
		    return manifest;
		}
		
		/**
		 * Constructs and returns an object containing keys corresponding to the children of the session state object referenced by this path, the values of which are new WeavePath objects.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return {object} An object containing keys corresponding to the children of the session state object.
		 */
		public function getProperties(...relativePath):Object
		{
		    var result:Object = {};
		    this.getNames.apply(this, relativePath).forEach(function(name:String):void { result[name] = this.push(name); }, this);
		    return result;
		}
		
		/**
		 * Returns an array of alphanumeric strings uniquely corresponding to the KeySet referenced by this path.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return {Array} An array of alphanumeric strings corresponding to the keys contained by the KeySet.
		 */
		public function getKeys(...relativePath):Array
		{
		    var args:Array = _A(relativePath, 1);
			var keySet:IKeySet = this.getObject(args) as IKeySet;
		    var raw_keys:Array = keySet.keys;
		    return raw_keys.map(this.qkeyToString);
		}
		
		/**
		 * Forces a flush of the add/remove key buffers for the KeySet specified by this path.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function flushKeys(...relativePath):WeavePath
		{
		    var args:Array = _A(relativePath, 1);
		    if (_assertParams('flushKeys', args))
		    {
		        var path:Array = this._path.concat(args);
		
		        this.shared._flushKeys(path);
		    }
		    return this;
		}
		
		/**
		 * Adds the specified keys to the KeySet at this path. These will not be added immediately, but are queued with flush timeout of approx. 25 ms.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param {Array} [keyStringArray] An array of alphanumeric keystrings that correspond to QualifiedKeys.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function addKeys(...relativePath_keyStringArray):WeavePath
		{
		    var args:Array = _A(relativePath_keyStringArray, 2);
		
		    if (_assertParams('addKeys', args))
		    {
		        var keyStringArray:Array = args.pop();
		        var path:Array = this._path.concat(args);
		
		        this.shared._addKeys(path, keyStringArray);
		    }
		    return this;
		}
		
		/**
		 * Removes the specified keys to the KeySet at this path. These will not be removed immediately, but are queued with a flush timeout of approx. 25 ms.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param {Array} [keyStringArray] An array of alphanumeric keystrings that correspond to QualifiedKeys.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function removeKeys(...relativePath_keyStringArray):WeavePath
		{
		    var args:Array = _A(relativePath_keyStringArray, 2);
		
		    if (_assertParams('removeKeys', args))
		    {
		        var keyStringArray:Array = args.pop();
		        var path:Array = this._path.concat(args);
		
		        this.shared._removeKeys(path, keyStringArray);
		    }
		    return this;
		}
		
		/**
		 * Adds a callback to the KeySet specified by this path which will return information about which keys were added or removed to/from the set.
		 * @param {Function} callback           A callback function which will receive an object containing two fields,
		 *                                       'added' and 'removed' which contain a list of the keys which changed in the referenced KeySet
		 * @param {boolean}  [triggerCallbackNow] Whether to trigger the callback immediately after it is added.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function addKeySetCallback(callback:Function, triggerCallbackNow:Boolean = false):WeavePath
		{
			var self:WeavePath = this;
			var keyCallbacks:IKeySetCallbackInterface = this.getObject('keyCallbacks') as IKeySetCallbackInterface;
			keyCallbacks.addImmediateCallback(keyCallbacks, function():void {
				callback.call(self, {
					added: keyCallbacks.keysAdded.map(qkeyToString),
					removed: keyCallbacks.keysRemoved.map(qkeyToString)
				});
			});
		
		    if (triggerCallbackNow)
		        callback.call(this, {
					added: this.getKeys(),
					removed: []
				});
		
		    return this;
		}
		
		/**
		 * Replaces the contents of the KeySet at this path with the specified keys.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param {Array} keyStringArray An array of alphanumeric keystrings that correspond to QualifiedKeys.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function setKeys(...relativePath_keyStringArray):WeavePath
		{
		    var args:Array = _A(relativePath_keyStringArray, 2);
		    if (_assertParams('setKeys', args))
		    {
		        var keyStringArray:Array = args.pop();
		        var keyObjectArray:Array = keyStringArray.map(this.stringToQKey);
				this.getObject(args)['replaceKeys'](keyObjectArray);
		
		        return this;
		    };
		    return this;
		}
		/**
		 * Intersects the specified keys with the KeySet at this path.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param {Array} keyStringArray An array of alphanumeric keystrings that correspond to QualifiedKeys.
		 * @return {Array} The keys which exist in both the keyStringArray and in the KeySet at this path.
		 */
		
		public function filterKeys(...relativePath_keyStringArray):Array
		{
		    var args:Array = _A(relativePath_keyStringArray, 2);
		    if (_assertParams('filterKeys', args))
		    {
		        var keyStringArray:Array = args.pop();
		        var keyObjects:Array = keyStringArray.map(this.stringToQKey);
				var obj:Object = this.getObject(args);
				return WeaveAPI.QKeyManager.convertToQKeys(keyObjects)
					.filter(function(key:*):Boolean { return obj.containsKey(key); })
		        	.map(this.qkeyToString, this);
		    }
			return null;
		}
		
		/**
		 * Retrieves a list of records defined by a mapping of property names to column paths or by an array of column names.
		 * @param {object} pathMapping An object containing a mapping of desired property names to column paths or an array of child names.
		 * pathMapping can be one of three different forms:
		 * 
		 * 1. An array of column names corresponding to children of the WeavePath this method is called from, e.g., path.retrieveRecords(["x", "y"]);
		 * the column names will also be used as the corresponding property names in the resultant records.
		 * 
		 * 2. An object, for which each property=>value is the target record property => source column WeavePath. This can be defined to include recursive structures, e.g.,
		 * path.retrieveRecords({point: {x: x_column, y: y_column}, color: color_column}), which would result in records with the same form.
		 * 
		 * 3. If it is null, all children of the WeavePath will be retrieved. This is equivalent to: path.retrieveRecords(path.getNames());
		 * 
		 * The alphanumeric QualifiedKey for each record will be stored in the 'id' field, which means it is to be considered a reserved name.
		 * @param {weave.WeavePath} [options] An object containing optional parameters:
		 *                                    "keySet": A WeavePath object pointing to an IKeySet (columns are also IKeySets.)
		 *                                    "dataType": A String specifying dataType: string/number/date/geometry
		 * @return {Array} An array of record objects.
		 */
		public function retrieveRecords(pathMapping:Object, options:Object):Array
		{
			var dataType:String = options ? options['dataType'] : null;
			var keySetPath:WeavePath = options ? options['keySet'] : null;
			
			if (!keySetPath && options is WeavePath)
				keySetPath = options as WeavePath;
			
			// if only one argument given and it's a WeavePath object, assume it's supposed to be keySetPath.
			if (arguments.length == 1 && pathMapping is WeavePath)
			{
				keySetPath = pathMapping as WeavePath;
				pathMapping = null;
			}
			
			if (!pathMapping)
				pathMapping = this.getNames();
		
		    if (pathMapping is Array) // array of child names
		    {
				var names:Array = pathMapping as Array;
				pathMapping = {};
				for each (var name:String in names)
					pathMapping[name] = this.push(name);
		    }
		    
		    // pathMapping is a nested object mapping property chains to WeavePath objects
		    var obj:Object = listChainsAndColumns(pathMapping);
		    
		    /* Perform the actual retrieval of records */
		    var results:Array = ColumnUtils.joinColumns(obj.columns, dataType, true, keySetPath ? keySetPath.getObject() : null);
		    return results[0]
		        .map(this.qkeyToString)
		        .map(function(key:String, iRow:int, a:Array):Object {
		            var record:Object = {id: key};
		            obj.chains.forEach(function(chain:Array, iChain:int, a:Array):void {
		                setChain(record, chain, results[iChain + 1][iRow])
		            });
		            return record;
		        });
		}
		
		/**
		 * @private
		 * Walk down a property chain of a given object and set the value of the final node.
		 * @param root The object to navigate through.
		 * @param property_chain An array of property names defining a path.
		 * @param value The value to which to set the final node.
		 * @return The value that was set, or the current value if no value was given.
		 */
		protected static function setChain(root:Object, property_chain:Array, value:* = undefined):*
		{
		    property_chain = [].concat(property_chain); // makes a copy and converts a single string into an array
		    var last_property:String = property_chain.pop();
		    property_chain.forEach(function(prop:String, i:int, a:Array):void {
		    	root = root[prop] || (root[prop] = {});
		    });
		    // if value not given, return current value
		    if (value === undefined)
		    	return root[last_property];
		    // set the value and return it
		    return root[last_property] = value;
		}
		
		/**
		 * @private
		 * Walk down a property chain of a given object and return the final node.
		 * @param root The object to navigate through.
		 * @param property_chain An array of property names defining a path.
		 * @return The value of the final property in the chain.
		 */
		protected static function getChain(root:Object, property_chain:Array):*
		{
			return setChain(root, property_chain);
		}
		
		/**
		 * @private
		 * Recursively builds a mapping of property chains to WeavePath objects from a path specification as used in retrieveRecords
		 * @param obj A path spec object
		 * @param prefix A property chain prefix (optional)
		 * @param output Output object with "chains" and "columns" properties (optional)
		 * @return An object like {"chains": [], "columns": []}, where "chains" contains property name chains and "columns" contains IAttributeColumn objects
		 */
		protected function listChainsAndColumns(obj:Object, prefix:Array = null, output:Object = null):Object
		{
		    if (!prefix)
		        prefix = [];
		    if (!output)
		        output = {chains: [], columns: []};
		    
		    for (var key:String in obj)
		    {
		        var item:Object = obj[key];
		        if (item is WeavePath)
		        {
					var column:ILinkableObject = item.getObject();
		            if (column is IAttributeColumn)
		            {
		                output.chains.push(prefix.concat(key));
		                output.columns.push(column);
		            }
		        }
		        else
		        {
		            listChainsAndColumns(item, prefix.concat(key), output);
		        }
		    }
		    return output;
		}
		
		/**
		 * Sets a human-readable label for an ILinkableObject to be used in editors.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying child names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @param {string} label The human-readable label for an ILinkableObject.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function label(...relativePath_label):WeavePath
		{
		    var args:Array = _A(relativePath_label, 2);
		    if (_assertParams('setLabel', args))
		    {
		        var label:String = args.pop();
		        WeaveAPI.EditorManager.setLabel(this.getObject(args), label);
		    }
		    return this;
		}
		
		/**
		 * Gets the previously-stored human-readable label for an ILinkableObject.
		 * @param [relativePath] An optional Array (or multiple parameters) specifying child names relative to the current path.
		 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
		 * @return {string} The human-readable label for an ILinkableObject.
		 */
		public function getLabel(...relativePath):String
		{
		    var args:Array = _A(relativePath, 1);
		    return WeaveAPI.EditorManager.getLabel(this.getObject(args));
		}
		
		/**
		 * Sets the metadata for a column at the current path.
		 * @param {object} metadata The metadata identifying the column. The format depends on the data source.
		 * @param {string} dataSourceName (Optional) The name of the data source in the session state.
		 *                       If ommitted, the first data source in the session state will be used.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function setColumn(metadata:Object, dataSourceName:String):WeavePath
		{
			var object:ILinkableObject = this.getObject();
			if (!object)
				object = this.request(ReferencedColumn).getObject();
			
			if (object is ExtendedDynamicColumn)
				object = (object as ExtendedDynamicColumn).internalDynamicColumn.requestLocalObject(ReferencedColumn, false);
			else if (object is DynamicColumn)
				object = (object as DynamicColumn).requestLocalObject(ReferencedColumn, false);
			
			if (object is ReferencedColumn)
			{
				if (arguments.length < 2)
					dataSourceName = weave.root.getNames(IDataSource)[0];
				var dataSource:IDataSource = weave.root.getObject(dataSourceName) as IDataSource;
				(object as ReferencedColumn).setColumnReference(dataSource, metadata);
			}
			else
				_failMessage('setColumn', 'Not a compatible column object', this._path);
			
			return this;
		}
		
		/**
		 * Sets the metadata for multiple columns that are children of the current path.
		 * @param metadataMapping An object mapping child names (or indices) to column metadata.
		 *                        An Array of column metadata objects may be given for a LinkableHashMap.
		 * @param {string} [dataSourceName] The name of the data source in the session state.
		 *                       If ommitted, the first data source in the session state will be used.
		 * @return {weave.WeavePath} The current WeavePath object.
		 */
		public function setColumns(metadataMapping, dataSourceName):WeavePathData
		{
			var useDataSource:Boolean = arguments.length > 1;
			this.forEach(metadataMapping, function(value:Object, key:String, a:Array):void {
				var path:WeavePathData = this.push(key) as WeavePathData;
				var func:Function = value is Array ? path.setColumns : path.setColumn;
				var args:Array = useDataSource ? [value, dataSourceName] : [value];
				func.apply(path, args);
			});
			if (metadataMapping is Array)
				while (this.getType(metadataMapping.length))
					this.remove(metadataMapping.length);
			return this;
		}
	}
}
