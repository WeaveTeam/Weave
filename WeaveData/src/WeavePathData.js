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
    var key_str = JSON.stringify([key.keyType.toString(), key.localName.toString()]);

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
weave.WeavePath.prototype.newProperty = function(name, type, callback)
{
    this.push(name).request(type).addCallback(callback, true);
    return this;
};

weave.WeavePath.prototype.getKeys = function(/* [relpath] */)
{
    var raw_keys = this.weave.evaluateExpression(this._path.concat(this._A(arguments, 1)), "this.keys", this._vars);
    var length = raw_keys.length;
    var result = new Array(length);
    for (var idx = 0; idx < length; idx++)
    {
        result[idx] = this.qkeyToString(raw_keys[idx]);
    }
    return result;
};

weave.WeavePath.prototype.setKeys = function(/* [relpath], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('setKeys', args))
    {
        var keyStringArray = args.pop();
        var length = keyStringArray.length;
        var keyObjectArray = new Array(length);

        for (var idx = 0; idx < length; idx++)
        {
            keyObjectArray[idx] = this.stringToQKey(keyStringArray[idx]);
        }
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
        var keyObjects = keyStringArray.map(this.stringToQKey, this);
        var resultArray = this.push(args).libs("weave.api.WeaveAPI").vars({containsKeysArgs: keyObjects}).getValue(
            'WeaveAPI.QKeyManager.convertToQKeys(containsKeysArgs).filter(function(d) { return containsKey(d); })'
        );
        return resultArray.map(this.qkeyToString, this);
    }
}
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
}