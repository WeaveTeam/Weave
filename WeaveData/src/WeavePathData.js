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

/* Methods and properties added to facilitate creation of external linked tools.
 * This assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

if (!weave.WeavePath)
	return;

weave.WeavePath.prototype.probe_keyset = weave.path("defaultProbeKeySet");
weave.WeavePath.prototype.selection_keyset = weave.path("defaultSelectionKeySet");
weave.WeavePath.prototype.subset_filter = weave.path("defaultSubsetKeyFilter");

/**
 * Defines static methods and lookup tables that manage conversion between Weave QualifiedKeys and DOM-friendly generated alphanumeric keys.
 * Also defines buffers so that we can ratelimit manipulation of keysets.
 * Alphanumeric keys should not be considered stable across sessions and should not be stored in the session state.
 * @namespace
 */
weave.WeavePath.Keys = {};

weave.WeavePath.Keys._qkeys_to_numeric = {};
weave.WeavePath.Keys._numeric_to_qkeys = {};
weave.WeavePath.Keys._numeric_key_idx = 0;
weave.WeavePath.Keys._keyIdPrefix = "WeaveQKey";

/** 
 * Retrieves or allocates the index for the given QualifiedKey object based on its localName and keyType properties
 * @private 
 * @param  {object} key A QualifiedKey object (containing keyType and localName properties) to be converted.
 * @return {number}     The existing or newly-allocated index for the qualified key.
 */
weave.WeavePath.Keys.qkeyToIndex = function(key)
{
    var local_map = this._qkeys_to_numeric[key.keyType] || (this._qkeys_to_numeric[key.keyType] = {});

    if (local_map[key.localName] === undefined)
    {
        var idx = this._numeric_key_idx++;

        local_map[key.localName] = idx;
        this._numeric_to_qkeys[idx] = key;
    }

    return local_map[key.localName];
};
/**
 * Retrieves the corresponding qualified key object from its numeric index.
 * @private
 * @param  {number} index The numeric index, as received from qkeyToIndex
 * @return {object}       The corresponding QualifiedKey object.
 */
weave.WeavePath.Keys.indexToQKey = function (index)
{
    return this._numeric_to_qkeys[index];
};

/**
 * Retrieves an alphanumeric string unique to a QualifiedKey
 * This is also available as an alias on the WeavePath object.
 * @param  {object} key The QualifiedKey object to convert.
 * @return {string}     The corresponding alphanumeric key.
 */
weave.WeavePath.Keys.qkeyToString = function(key)
{
    return this._keyIdPrefix + this.qkeyToIndex(key);
};

/**
 * Retrieves the QualifiedKey object corresponding to a given alphanumeric string.
 * This is also available as an alias on the WeavePath object.
 * @param  {string} s The keystring to convert.
 * @return {object}   The corresponding QualifiedKey
 */
weave.WeavePath.Keys.stringToQKey = function(s) 
{
    var idx = s.substr(this._keyIdPrefix.length);
    return this.indexToQKey(idx);
};

/**
 * Gets the key add/remove buffers for a specific session state path.
 * @private
 * @param  {Array} pathArray A raw session state path.
 * @return {object}           An object containing the key add/remove queues for the given path.
 */
weave.WeavePath.Keys._getKeyBuffers = function (pathArray)
{
    var path_key = typeof JSON != 'undefined' ? JSON.stringify(pathArray) : pathArray;

    var key_buffers_dict = this._key_buffers || (this._key_buffers = {});
    var key_buffers = key_buffers_dict[path_key] || (key_buffers_dict[path_key] = {});

    if (key_buffers.add === undefined) key_buffers.add = {};
    if (key_buffers.remove === undefined) key_buffers.remove = {};
    if (key_buffers.timeout_id === undefined) key_buffers.timeout_id = null;

    return key_buffers;
};
/**
 * Flushes the key add/remove buffers for a specific session state path. 
 * @private
 * @param  {Array} pathArray The session state path to flush.         
 */
weave.WeavePath.Keys._flushKeys = function (pathArray)
{
    var key_buffers = this._getKeyBuffers(pathArray);
    var add_keys = Object.keys(key_buffers.add);
    var remove_keys = Object.keys(key_buffers.remove);

    add_keys = add_keys.map(this.stringToQKey, this);
    remove_keys = remove_keys.map(this.stringToQKey, this);

    key_buffers.add = {};
    key_buffers.remove = {};

    weave.evaluateExpression(pathArray, 'this.addKeys(keys)', {keys: add_keys}, null, "");
    weave.evaluateExpression(pathArray, 'this.removeKeys(keys)', {keys: remove_keys}, null, "");

    key_buffers.timeout_id = null;
}.bind(weave.WeavePath.Keys);
/**
 * Set a timeout to flush the add/remove key buffers for a given session state path if one isn't already in progress.
 * @private
 * @param  {Array} pathArray The session state path referencing a KeySet to flush.
 */
weave.WeavePath.Keys._flushKeysLater = function(pathArray)
{
    var key_buffers = this._getKeyBuffers(pathArray);
    if (key_buffers.timeout_id === null)
        key_buffers.timeout_id = window.setTimeout(weave.WeavePath.Keys._flushKeys, 25, pathArray);
};

/**
 * Queue keys to be added to a specified path.
 * @private
 * @param {Array} pathArray      The session state path referencing a KeySet
 * @param {Array} keyStringArray The set of keys to add.
 */
weave.WeavePath.Keys._addKeys = function(pathArray, keyStringArray)
{
    var key_buffers = this._getKeyBuffers(pathArray);
    
    keyStringArray.forEach(function(key)
    {
        key_buffers.add[key] = true;
        delete key_buffers.remove[key];
    });

    this._flushKeysLater(pathArray);
};

/**
 * Queue keys to be removed from a specified path.
 * @private
 * @param {Array} pathArray      The session state path referencing a KeySet
 * @param {Array} keyStringArray The set of keys to remove.
 */
weave.WeavePath.Keys._removeKeys = function(pathArray, keyStringArray)
{
    var key_buffers = this._getKeyBuffers(pathArray);
    
    keyStringArray.forEach(function(key)
    {
        key_buffers.remove[key] = true;
        delete key_buffers.add[key];
    });

    this._flushKeysLater(pathArray);
};

weave.WeavePath.prototype.qkeyToString = weave.WeavePath.Keys.qkeyToString.bind(weave.WeavePath.Keys);
weave.WeavePath.prototype.stringToQKey = weave.WeavePath.Keys.stringToQKey.bind(weave.WeavePath.Keys);
weave.WeavePath.prototype.indexToQKey = weave.WeavePath.Keys.indexToQKey.bind(weave.WeavePath.Keys);
weave.WeavePath.prototype.qkeyToIndex = weave.WeavePath.Keys.qkeyToIndex.bind(weave.WeavePath.Keys);


/**
 * Creates a new property based on configuration stored in a property descriptor object. 
 * See initProperties for documentation of the property_descriptor object.
 * @param callback_pass If false, create object, verify type, and set default value; if true, add callback;
 * @param property_descriptor An object containing, minimally, a 'name' property defining the name of the session state element to be created.
 * @private
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype._initProperty = function(manifest, callback_pass, property_descriptor)
{
    var name = property_descriptor["name"]
    	|| this._failMessage('initProperty', 'A "name" is required');
    var label = property_descriptor["label"];
    var children = Array.isArray(property_descriptor["children"])
    	? Array.prototype.slice.call(property_descriptor["children"])
    	: undefined;
    var type = property_descriptor["type"] || (children ? "LinkableHashMap" : "LinkableVariable");
    
    var new_prop = this.push(name);

    if (callback_pass)
    {
        var callback = property_descriptor["callback"];
        var triggerNow = property_descriptor["triggerNow"];
        var immediate = property_descriptor["immediate"];
        if (callback)
            new_prop.addCallback(
                callback,
                triggerNow !== undefined ? triggerNow : true,
                immediate !== undefined ? immediate : false
            );
    }
    else
    {
        var oldType = new_prop.getType();
        
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
};

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
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.initProperties = function(property_descriptor_array, manifest)
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
};

/**
 * Constructs and returns an object containing keys corresponding to the children of the session state object referenced by this path, the values of which are new WeavePath objects.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return {object} An object containing keys corresponding to the children of the session state object.
 */
weave.WeavePath.prototype.getProperties = function(/*...relativePath*/)
{
    var result = {};
    this.getNames.apply(this, arguments).forEach(function(name) { result[name] = this.push(name); }, this);
    return result;
};

/**
 * Returns an array of alphanumeric strings uniquely corresponding to the KeySet referenced by this path.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return {Array} An array of alphanumeric strings corresponding to the keys contained by the KeySet.
 */
weave.WeavePath.prototype.getKeys = function(/*...relativePath*/)
{
    var args = this._A(arguments, 1);
    var path = this._path.concat(args);
    var raw_keys = this.weave.evaluateExpression(path, "this.keys");
    return raw_keys.map(this.qkeyToString);
};

/**
 * Forces a flush of the add/remove key buffers for the KeySet specified by this path.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.flushKeys = function (/*...relativePath*/)
{
    var args = this._A(arguments, 1);
    if (this._assertParams('flushKeys', args))
    {
        var path = this._path.concat(args);

        this.weave.WeavePath.Keys._flushKeys(path);
    }
    return this;
};
/**
 * Adds the specified keys to the KeySet at this path. These will not be added immediately, but are queued with flush timeout of approx. 25 ms.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param {Array} [keyStringArray] An array of alphanumeric keystrings that correspond to QualifiedKeys.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.addKeys = function (/*...relativePath, keyStringArray*/)
{
    var args = this._A(arguments, 2);

    if (this._assertParams('addKeys', args))
    {
        var keyStringArray = args.pop();
        var path = this._path.concat(args);

        this.weave.WeavePath.Keys._addKeys(path, keyStringArray);
    }
    return this;
};
/**
 * Removes the specified keys to the KeySet at this path. These will not be removed immediately, but are queued with a flush timeout of approx. 25 ms.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param {Array} [keyStringArray] An array of alphanumeric keystrings that correspond to QualifiedKeys.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.removeKeys = function (/*...relativePath, keyStringArray*/)
{
    var args = this._A(arguments, 2);

    if (this._assertParams('removeKeys', args))
    {
        var keyStringArray = args.pop();
        var path = this._path.concat(args);

        this.weave.WeavePath.Keys._removeKeys(path, keyStringArray);
    }
    return this;
};

/**
 * Adds a callback to the KeySet specified by this path which will return information about which keys were added or removed to/from the set.
 * @param {Function} callback           A callback function which will receive an object containing two fields,
 *                                       'added' and 'removed' which contain a list of the keys which changed in the referenced KeySet
 * @param {boolean}  [triggerCallbackNow] Whether to trigger the callback immediately after it is added.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.addKeySetCallback = function (callback, triggerCallbackNow)
{
    function wrapper()
    {
        var key_event = this.weave.evaluateExpression(this._path, '{added: this.keysAdded, removed: this.keysRemoved}');
        
        key_event.added = key_event.added.map(this.qkeyToString);
        key_event.removed = key_event.removed.map(this.qkeyToString);

        callback.call(this, key_event);
    }

    this.push('keyCallbacks').addCallback(wrapper, false, true);

    if (triggerCallbackNow)
    {
        var key_event = {
            added: this.getKeys(),
            removed: []
        };

        callback.call(this, key_event);
    }

    return this;
};
/**
 * Replaces the contents of the KeySet at this path with the specified keys.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param {Array} keyStringArray An array of alphanumeric keystrings that correspond to QualifiedKeys.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.setKeys = function(/*...relativePath, keyStringArray*/)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('setKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        this.weave.evaluateExpression(path, 'this.replaceKeys(keys)', {keys: keyObjectArray}, null, "");

        return this;
    };
    return this;
};
/**
 * Intersects the specified keys with the KeySet at this path.
 * @param [relativePath] An optional Array (or multiple parameters) specifying descendant names relative to the current path
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param {Array} keyStringArray An array of alphanumeric keystrings that correspond to QualifiedKeys.
 * @return {Array} The keys which exist in both the keyStringArray and in the KeySet at this path.
 */

weave.WeavePath.prototype.filterKeys = function (/*...relativePath, keyStringArray*/)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('filterKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjects = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        var resultArray = this.weave.evaluateExpression(
            path,
            'WeaveAPI.QKeyManager.convertToQKeys(keys).filter(key => this.containsKey(key))',
            {keys: keyObjects}
        );
        return resultArray.map(this.qkeyToString, this);
    }
};

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
 * The alphanumeric key for each record will be stored in the 'id' field, which means it is to be considered a reserved name.
 * 
 * @param {weave.WeavePath} [options] An object containing optional parameters:
 *                                    "keySet": A WeavePath object pointing to an IKeySet (columns are also IKeySets.)
 *                                    "dataType": A String specifying dataType: string/number/date/geometry
 * @return {Array} An array of record objects.
 */
weave.WeavePath.prototype.retrieveRecords = function(pathMapping, options)
{
	var dataType = options && options['dataType'];
	var keySet = options && options['keySet'];
	
	if (!keySet && options instanceof weave.WeavePath)
		keySet = options;
	
	// if only one argument given and it's a WeavePath object, assume it's supposed to be keySetPath.
	if (arguments.length == 1 && pathMapping instanceof weave.WeavePath)
	{
		keySet = pathMapping;
		pathMapping = null;
	}
	
	if (!pathMapping)
		pathMapping = this.getNames();

    if (Array.isArray(pathMapping)) // array of child names
    {
        var names = Array.prototype.slice.call(pathMapping);
        pathMapping = {};
        names.forEach(function(name){ pathMapping[name] = this.push(name); }, this);
    }
    
    // pathMapping is a nested object mapping property chains to WeavePath objects
    var obj = listChainsAndPaths(pathMapping);
    
    /* Perform the actual retrieval of records */
    var results = joinColumns(obj.paths, dataType, true, keySet);
    return results[0]
        .map(this.qkeyToString)
        .map(function(key, iRow) {
            var record = {id: key};
            obj.chains.forEach(function(chain, iChain){
                setChain(record, chain, results[iChain + 1][iRow])
            });
            return record;
        });
};

/**
 * @private
 * A function that tests if a WeavePath references an IAttributeColumn
 */
var isColumn = weave.evaluateExpression(null, "o => o is IAttributeColumn");

/**
 * @private
 * A pointer to ColumnUtils.joinColumns.
 */
var joinColumns = weave.evaluateExpression(null, "ColumnUtils.joinColumns");

/**
 * @private
 * Walk down a property chain of a given object and set the value of the final node.
 * @param root The object to navigate through.
 * @param property_chain An array of property names defining a path.
 * @param value The value to which to set the final node.
 * @return The value that was set, or the current value if no value was given.
 */
var setChain = function(root, property_chain, value)
{
    property_chain = [].concat(property_chain); // makes a copy and converts a single string into an array
    var last_property = property_chain.pop();
    property_chain.forEach(function(prop) {
    	root = root[prop] || (root[prop] = {});
    });
    // if value not given, return current value
    if (arguments.length == 2)
    	return root[last_property];
    // set the value and return it
    return root[last_property] = value;
};

/**
 * @private
 * Walk down a property chain of a given object and return the final node.
 * @param root The object to navigate through.
 * @param property_chain An array of property names defining a path.
 * @return The value of the final property in the chain.
 */
var getChain = function(root, property_chain)
{
	return setChain(root, property_chain);
};

/**
 * @private
 * Recursively builds a mapping of property chains to WeavePath objects from a path specification as used in retrieveRecords
 * @param obj A path spec object
 * @param prefix A property chain prefix (optional)
 * @param output Output object with "chains" and "paths" properties (optional)
 * @return An object like {"chains": [], "paths": []}, where "chains" contains property name chains and "paths" contains WeavePath objects
 */
var listChainsAndPaths = function(obj, prefix, output)
{
    if (!prefix)
        prefix = [];
    if (!output)
        output = {chains: [], paths: []};
    
    for (var key in obj)
    {
        var item = obj[key];
        if (item instanceof weave.WeavePath)
        {
            if (isColumn(item))
            {
                output.chains.push(prefix.concat(key));
                output.paths.push(item);
            }
        }
        else
        {
            listChainsAndPaths(item, prefix.concat(key), output);
        }
    }
    return output;
};

var getLabel = weave.evaluateExpression(null, "WeaveAPI.EditorManager.getLabel");
var setLabel = weave.evaluateExpression(null, "WeaveAPI.EditorManager.setLabel");

/**
 * Sets a human-readable label for an ILinkableObject to be used in editors.
 * @param [relativePath] An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param {string} label The human-readable label for an ILinkableObject.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.label = function(/*...relativePath, label*/)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('setLabel', args))
    {
        var label = args.pop();
        setLabel(this.push(args), label);
    }
    return this;
};

/**
 * Gets the previously-stored human-readable label for an ILinkableObject.
 * @param [relativePath] An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return {string} The human-readable label for an ILinkableObject.
 */
weave.WeavePath.prototype.getLabel = function(/*...relativePath*/)
{
    var args = this._A(arguments, 1);
    return getLabel(this.push(args));
};

var EDC = 'weave.data.AttributeColumns::ExtendedDynamicColumn';
var DC = 'weave.data.AttributeColumns::DynamicColumn';
var RC = 'weave.data.AttributeColumns::ReferencedColumn';
var getColumnType = weave.evaluateExpression(null, 'o => { for each (var t in types) if (o is t) return t; }', {types: [EDC, DC, RC]});
var getFirstDataSourceName = weave.evaluateExpression([], '() => this.getNames(IDataSource)[0]');

/**
 * Sets the metadata for a column at the current path.
 * @param {object} metadata The metadata identifying the column. The format depends on the data source.
 * @param {string} [dataSourceName] (Optional) The name of the data source in the session state.
 *                       If ommitted, the first data source in the session state will be used.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.setColumn = function(metadata, dataSourceName)
{
	var type = this.getType();
	if (!type)
		this.request(type = RC);
	else
		type = getColumnType(this);
	
	if (!type)
		this._failMessage('setColumn', 'Not a compatible column object', this._path);
	
	var path = this;
	if (type == EDC)
		path = path.push('internalDynamicColumn', null).request(RC);
	else if (type == DC)
		path = path.push(null).request(RC);
	path.state({
		"metadata": metadata,
		"dataSourceName": arguments.length > 1 ? dataSourceName : getFirstDataSourceName()
	});
	
	return this;
};

/**
 * Sets the metadata for multiple columns that are children of the current path.
 * @param metadataMapping An object mapping child names (or indices) to column metadata.
 *                        An Array of column metadata objects may be given for a LinkableHashMap.
 * @param {string} [dataSourceName] The name of the data source in the session state.
 *                       If ommitted, the first data source in the session state will be used.
 * @return {weave.WeavePath} The current WeavePath object.
 */
weave.WeavePath.prototype.setColumns = function(metadataMapping, dataSourceName) {
	var useDataSource = arguments.length > 1;
	this.forEach(metadataMapping, function(value, key) {
		var path = this.push(key);
		var func = Array.isArray(value) ? path.setColumns : path.setColumn;
		var args = useDataSource ? [value, dataSourceName] : [value];
		func.apply(path, args);
	});
	if (Array.isArray(metadataMapping))
		while (this.getType(metadataMapping.length))
			this.remove(metadataMapping.length);
	return this;
};

////////////////////////////////////

var weaveTreeNodeSerial = 'WEAVE_TREE_NODE_SERIAL';
var weaveTreeNodeLookup = 'WEAVE_TREE_NODE_LOOKUP';
// initialize ActionScript variables
weave.evaluateExpression(null, '0', null, null, weaveTreeNodeSerial);
weave.evaluateExpression(null, 'new Dictionary()', null, null, weaveTreeNodeLookup);
var _createNodeFunction = function(script, vars) {
	var fn = weave.evaluateExpression(null, '(serial,arg1,arg2) => { var node = ' + weaveTreeNodeLookup + '[serial]; ' + script + ' }', vars);
	return function(arg1, arg2) { return fn(this.serial, arg1, arg2); };
};
var _mapNodesToSerials = weave.evaluateExpression(null, 'nodes => {\
	var lookup = ' + weaveTreeNodeLookup + ';\
	return nodes && nodes.map(child => {\
		if (lookup[child] === undefined)\
			lookup[ (lookup[child] = ++' + weaveTreeNodeSerial + ') ] = child;\
		return lookup[child];\
	});\
}');

/**
 * WeaveTreeNode implements the following interfaces: IWeaveTreeNode, IColumnReference
 */
weave.WeaveTreeNode = function(serial, parent) {
	this.serial = serial | 0; // default - root node
	this.parent = parent;
	weave.WeaveTreeNode.cache[this.serial] = this;
	if (this.serial == 0)
		weave.evaluateExpression(null, 'var lookup = ' + weaveTreeNodeLookup + '; if (lookup[0] === undefined) lookup[lookup[0] = new WeaveRootDataTreeNode()] = 0; return null;');
};
weave.WeaveTreeNode.cache = {}; // serial -> WeaveTreeNode
weave.WeaveTreeNode.prototype.getLabel = _createNodeFunction('node.getLabel()');
weave.WeaveTreeNode.prototype.isBranch = _createNodeFunction('node.isBranch()');
weave.WeaveTreeNode.prototype.hasChildBranches = _createNodeFunction('node.hasChildBranches()');
weave.WeaveTreeNode.prototype._getChildrenSerials = _createNodeFunction('getSerials(node.getChildren())', {getSerials: _mapNodesToSerials});
weave.WeaveTreeNode.prototype.getChildren = function() {
	var serials = this._getChildrenSerials();
	return serials && serials.map(function(serial) {
		return weave.WeaveTreeNode.cache[serial] || new weave.WeaveTreeNode(serial, this);
	}, this);
};
weave.WeaveTreeNode.prototype.getDataSource = _createNodeFunction('node is IColumnReference ? node.getDataSource() : null');
weave.WeaveTreeNode.prototype.getDataSourceName = _createNodeFunction('node is IColumnReference ? WeaveAPI.globalHashMap.getName(node.getDataSource()) : null');
weave.WeaveTreeNode.prototype.getColumnMetadata = _createNodeFunction('node is IColumnReference ? node.getColumnMetadata() : null');
weave.WeaveTreeNode.prototype._findPathSerials = _createNodeFunction('\
	var dataSourceName = arg1, columnMetadata = arg2;\
	var ds = WeaveAPI.globalHashMap.getObject(dataSourceName) as IDataSource;\
	var target = ds && ds.findHierarchyNode(columnMetadata);\
	var path = ds && target && HierarchyUtils.findPathToNode(node, target);\
	return getSerials(path);\
', {getSerials: _mapNodesToSerials});
weave.WeaveTreeNode.prototype.findPath = function(dataSourceName, columnMetadata) {
	var serials = this._findPathSerials(dataSourceName, columnMetadata);
	return serials && serials.map(function(serial, index, array) {
		var parent = weave.WeaveTreeNode.cache[array[index - 1]];
		return weave.WeaveTreeNode.cache[serial] || new weave.WeaveTreeNode(serial, parent);
	}, this);
};
