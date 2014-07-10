/* Methods and properties added to facilitate creation of external linked tools.
 * This assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

weave.WeavePath.prototype.probe_keyset = weave.path("defaultProbeKeySet");
weave.WeavePath.prototype.selection_keyset = weave.path("defaultSelectionKeySet");
weave.WeavePath.prototype.subset_filter = weave.path("defaultSubsetKeyFilter");

weave.WeavePath._qkeys_to_numeric = {};
weave.WeavePath._numeric_to_qkeys = {};
weave.WeavePath._numeric_key_idx = 0;
weave.WeavePath._keyIdPrefix = "WeaveQKey";

weave.WeavePath.qkeyToIndex = function(key)
{   
    var key_str = JSON.stringify([key.keyType, key.localName]);

    if (this._qkeys_to_numeric[key_str] == undefined)
    {
        var idx = this._numeric_key_idx;

        this._numeric_to_qkeys[idx] = key;
        this._qkeys_to_numeric[key_str] = idx;
        
        this._numeric_key_idx = idx + 1;
    }
    return this._qkeys_to_numeric[key_str];
};

weave.WeavePath.prototype.qkeyToIndex = weave.WeavePath.qkeyToIndex.bind(weave.WeavePath);

weave.WeavePath.indexToQKey = function (index)
{
    return this._numeric_to_qkeys[index];
};

weave.WeavePath.prototype.indexToQKey = weave.WeavePath.indexToQKey.bind(weave.WeavePath);

weave.WeavePath.qkeyToString = function(key)
{
    return this._keyIdPrefix + this.qkeyToIndex(key);
};

weave.WeavePath.prototype.qkeyToString = weave.WeavePath.qkeyToString.bind(weave.WeavePath);

weave.WeavePath.stringToQKey = function(s) 
{
    idx = s.substr(this._keyIdPrefix.length);
    return this.indexToQKey(idx);
};

weave.WeavePath.prototype.stringToQKey = weave.WeavePath.stringToQKey.bind(weave.WeavePath);

/**
 * Creates a new property of the specified type, and binds the appropriate callback.
 * @param name The name of the new property or previously existing property to access.
 * @param type The session state object type of the new property.
 * @param callback A callback taking no arguments to be called when the newly created property changes.
 * @return The current WeavePath object.
 */
weave.WeavePath.prototype.initProperty = function(property_descriptor)
{
    var name = property_descriptor["name"] || this._failMessage('initProperty', 'A "name" is required');
    var type = property_descriptor["type"] || "LinkableVariable";
    var callback = property_descriptor["callback"];
    var triggerCallbackNow = property_descriptor["triggerNow"] !== undefined ? property_descriptor["triggerNow"] : true;
    var immediate = property_descriptor["immediate"] !== undefined ? property_descriptor["immediate"] : false;

    var label = property_descriptor["label"];
    
    var new_prop = this.push(name);

    var oldType = new_prop.getType();

    new_prop.request(type);

    if (label)
    {
        new_prop.label(label);
    }

    if (oldType != type && property_descriptor.hasOwnProperty("default"))
    {
        new_prop.state(property_descriptor["default"]);
    }

    if (callback)
    {
        new_prop.addCallback(callback, triggerCallbackNow, immediate);
    }

    return this;
}

weave.WeavePath.prototype.initProperties = function(property_descriptor_array)
{
    if (this.getType() == null) 
        this.request("ExternalTool");

    var results = {};

    for (var idx = 0; idx < property_descriptor_array.length; idx++)
    {
        var property_descriptor = property_descriptor_array[idx];
        var name = property_descriptor["name"];
        
        this.initProperty(property_descriptor);
        results[name] = this.push(name);
    }

    return results;
};

weave.WeavePath.prototype.getKeys = function(/* [relpath] */)
{
	var args = this._A(arguments, 1);
	var path = this._path.concat(args);
    var raw_keys = this.weave.evaluateExpression(path, "this.keys");
    return raw_keys.map(this.qkeyToString);
};

weave.WeavePath.prototype.addKeys = function (/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('addKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        this.weave.evaluateExpression(path, 'this.addKeys(keys)', {keys: keyObjectArray});
    }
    return this;
};

weave.WeavePath.prototype.removeKeys = function (/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('removeKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        this.weave.evaluateExpression(path, "this.removeKeys(keys)", {keys: keyObjectArray});
    }
    return this;
};

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

weave.WeavePath.prototype.setKeys = function(/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('setKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        this.weave.evaluateExpression(path, 'this.replaceKeys(keys)', {keys: keyObjectArray});

        return this;
    };
    return this;
};

weave.WeavePath.prototype.filterKeys = function (/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('filterKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjects = keyStringArray.map(this.stringToQKey);
        var path = this._path.concat(args);
        var resultArray = this.weave.evaluateExpression(
        	path,
            'WeaveAPI.QKeyManager.convertToQKeys(keys).filter(key => this.containsKey(key), this)',
            {keys: keyObjects}
        );
        return resultArray.map(this.qkeyToString, this);
    }
};

/**
 * This only works on an ILinkableHashMap.
 */
weave.WeavePath.prototype.retrieveColumns = function(/* [relpath], columnNameArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('retrieveColumns', args))
    {
        var columnNameArray = args.pop();
        var path = this._path.concat(args);
        var results = this.weave.evaluateExpression(
        	path,
        	'ColumnUtils.joinColumns(names.map(name => this.getObject(name), this), null, true)',
        	{names: columnNameArray},
        	['weave.utils.ColumnUtils']
        );
        /* Convert the keys to strings */
        results[0] = results[0].map(this.qkeyToString, this);
        return results;
    }
};

/** 
 * Retrieve a table of columns defined by a mapping of property names to column paths. 
 * @param pathMapping An object containing a mapping of desired property names to column paths. "id" is a reserved name.
 * @param keySetPath A path object pointing to an IKeySet (columns are also IKeySets.)
 * @return An array of record objects.
 */
weave.WeavePath.prototype.retrieveRecords = function(pathMapping, keySetPath)
{
    var columnNames = Object.keys(pathMapping);
    var columnPaths = columnNames.map(function (name) { return pathMapping[name].getPath(); });

    var keySetPath = keySetPath ? keySetPath.getPath() : null;
    var results = this.weave.evaluateExpression(
    	this._path,
        '\
    		var getObject = WeaveAPI.SessionManager.getObject;\
        	var root = WeaveAPI.globalHashMap;\
        	var keySet = keySetPath ? getObject(root, keySetPath) : null;\
        	var columns = paths.map(path => getObject(root, path));\
        	return ColumnUtils.joinColumns(columns, null, true, keySet);\
    	',
    	{
    		paths: columnPaths,
    		keySetPath: keySetPath
    	},
    	['weave.utils.ColumnUtils']
    );
    
    results[0] = results[0].map(this.qkeyToString);

    var records = new Array(results[0].length);
    for (var record_idx = 0; record_idx < results[0].length; record_idx++)
    {
        var new_record = {};

        new_record.id = results[0][record_idx];

        for (var column_idx = 0; column_idx < columnNames.length; column_idx++)
        {
            new_record[columnNames[column_idx]] = results[column_idx+1][record_idx];
        }

        records[record_idx] = new_record;
    }
    return records;
}

/**
 * Sets a human-readable label for an ILinkableObject to be used in editors.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @param The human-readable label for an ILinkableObject.
 */
weave.WeavePath.prototype.label = function(/*...relativePath, label*/)
{
	var args = this._A(arguments, 2);
	if (this._assertParams('setLabel', args))
	{
		var label = args.pop();
		var path = this._path.concat(args);
		this.weave.evaluateExpression(path, "WeaveAPI.EditorManager.setLabel(this, label)", {"label": label});
	}
	return this;
}

/**
 * Gets the previously-stored human-readable label for an ILinkableObject.
 * @param relativePath An optional Array (or multiple parameters) specifying child names relative to the current path.
 *                     A child index number may be used in place of a name in the path when its parent object is a LinkableHashMap.
 * @return The human-readable label for an ILinkableObject.
 */
weave.WeavePath.prototype.getLabel = function(/*...relativePath*/)
{
	var args = this._A(arguments, 1);
	var path = this._path.concat(args);
	return this.weave.evaluateExpression(path, "WeaveAPI.EditorManager.getLabel(this)")
};
