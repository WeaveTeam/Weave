/* Methods and properties added to facilitate creation of external linked tools.
 * This assumes that WeavePath.js has already been loaded. */
/* "use strict"; */

weave.WeavePath.prototype.probe_keyset = weave.path("defaultProbeKeySet");
weave.WeavePath.prototype.selection_keyset = weave.path("defaultSelectionKeySet");
weave.WeavePath.prototype.subset_filter = weave.path("defaultSubsetKeyFilter");

weave.WeavePath.prototype.qkeyToString = function(key)
{
    return JSON.stringify([key.keyType, key.localName]);
};
weave.WeavePath.prototype.stringToQKey = function(s) 
{
    var arr;
    var newQKey = {};

    try {
        arr = JSON.parse(s);
        newQKey.keyType = arr[0];
        newQKey.localName = arr[1];

    }
    catch (e)
    {
        console.log("Failed to parse string as a QKey array, assuming generic string key.", e);
        newQKey.keyType = "string";
        newQKey.localName = s;
    }
    return newQKey;
};

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

weave.WeavePath.prototype.getKeys = function(/* [name] */)
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

weave.WeavePath.prototype.setKeys = function(/* [name], keyStringArray */)
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
weave.WeavePath.prototype.filterKeys = function (/* [name], keyStringArray */)
{
    var args = this._A(arguments, 2);
    if (this._assertParams('containsKeys', args))
    {
        var keyStringArray = args.pop();
        var keyObjects = keyStringArray.map(this.stringToQKey, this);
        var resultArray = this.push(args).libs("weave.api.WeaveAPI").vars({containsKeysArgs: keyObjects}).getValue(
            'WeaveAPI.QKeyManager.convertToQKeys(containsKeysArgs).filter(function(d) { return containsKey(d); })'
        );
        return resultArray.map(this.qkeyToString, this);
    }
}