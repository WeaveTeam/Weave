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
    var key_str = JSON.stringify([key.keyType && key.keyType.toString(), key.localName && key.localName.toString()]);

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

    var existed = !!new_prop.getType();

    new_prop.request(type);

    if (label)
    {
        new_prop.label(label);
    }

    if (!existed && property_descriptor.hasOwnProperty("default"))
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
    var raw_keys = this.weave.evaluateExpression(this._path.concat(this._A(arguments, 1)), "this.keys", this._vars);
    return raw_keys.map(this.qkeyToString);
};

weave.WeavePath.prototype.addKeys = function (/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('addKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);

        this.push(args).vars({addKeysArgs: keyObjectArray}).exec('addKeys(addKeysArgs)');
    }
};

weave.WeavePath.prototype.removeKeys = function (/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('removeKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjectArray = keyStringArray.map(this.stringToQKey);

        this.push(args).vars({removeKeysArgs: keyObjectArray}).exec('removeKeys(removeKeysArgs)');
    }
};

weave.WeavePath.prototype.addKeySetCallback = function (func, triggerCallbackNow)
{
    function wrapper()
    {
        var key_event = this.getValue('{added: addedKeys, removed: removedKeys}');
        

        key_event.added = key_event.added.map(this.qkeyToString);
        key_event.removed = key_event.removed.map(this.qkeyToString);

        func(key_event);
    }


    this.push('keyCallbacks').addCallback(wrapper, false, true);

    if (triggerCallbackNow)
    {
        var key_event = {};
        var added_keys = this.getKeys();
        key_event.removed = [];

        func.call(this, key_event);
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

        this.push(args).vars({setKeysArgs: keyObjectArray}).exec('replaceKeys(setKeysArgs)');

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
        var resultArray = this.push(args).vars({containsKeysArgs: keyObjects}).getValue(
            'WeaveAPI.QKeyManager.convertToQKeys(containsKeysArgs).filter(function(d) { return containsKey(d); })'
        );
        return resultArray.map(this.qkeyToString, this);
    }
};

weave.WeavePath.prototype.retrieveColumns = function(/* [relpath], columnNameArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('retrieveColumns', args))
    {
        var columnNameArray = args.pop();

        var results = this.push(args).libs("weave.utils.ColumnUtils").vars({retrieveColumnsArgs: columnNameArray}).getValue(
            'ColumnUtils.joinColumns(retrieveColumnsArgs.map(function(name){ return getObject(name); }, this),  null, true)'
        );
        /* Convert the keys to strings */
        results[0] = results[0].map(this.qkeyToString, this);
        return results;
    }
};

/** 
 * Retrieve a table of columns defined by a mapping of property names to column paths. 
 * @param path Mapping An object containing a mapping of desired property names to column paths. "id" is a reserved name.
 * @param keys A path object pointing to a valid keyset (columns are also keysets.)
 * @return An array of record objects.
 */
weave.WeavePath.prototype.retrieveRecords = function(/* pathMapping, keySetPath */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('joinColumns', 1))
    {
        var keys = Object.keys(args[0]);

        var values = keys.map(function (d,i,a) {return args[0][d].getPath();});

        var keySetPath = args[1] ? args[1].getPath() : null;
        
        var results = this.push(args).libs("weave.utils.ColumnUtils").vars({paths: values, keySetPath: keySetPath}).getValue(
            'var keySet = keySetPath ? WeaveAPI.SessionManager.getObject(WeaveAPI.globalHashMap, keySetPath) : null;'+
            'var columns = paths.map(function(path){return WeaveAPI.SessionManager.getObject(WeaveAPI.globalHashMap, path);});'+
            'return ColumnUtils.joinColumns(columns, null, true, keySet);');
        
        results[0] = results[0].map(this.qkeyToString, this);

        var records = Array(results[0].length);
        for (var record_idx = 0; record_idx < results[0].length; record_idx++)
        {
            var new_record = {};

            new_record.id = results[0][record_idx];

            for (var column_idx = 0; column_idx < keys.length; column_idx++)
            {
                new_record[keys[column_idx]] = results[column_idx+1][record_idx];
            }

            records[record_idx] = new_record;
        }
        return records;
    }
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
		var pathcopy = this._path.concat(args);
		this.weave.evaluateExpression(pathcopy, "WeaveAPI.EditorManager.setLabel(this, label)", {"label": label});
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
	return this.weave.evaluateExpression(this._path.concat(this._A(arguments, 1)), "WeaveAPI.EditorManager.getLabel(this)")
};
