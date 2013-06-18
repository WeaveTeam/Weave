// goog.provide('ivpr.LiveQuery');
window.ivpr = window.ivpr || {};


/**
 * Automatically makes JSON RPC calls.  Requires jQuery for ajax.
 * @constructor
 * @param {string} url The URL of the JSON-RPC service
 * @param {string} method The name of the RPC call
 * @param {?Object.<string,*>|Array.<?>} params Initial parameters for the RPC call
 */
ivpr.LiveQuery = function(url, method, params) {
	/**
	 * busy status
	 * @type {boolean}
	 */
	this.busy = false;

	/**
	 * "result" listeners
	 * @type {Array.<function(*)>}
	 */
	this.listeners = [];

	/**
	 * "busy" listeners
	 * @type {Array.<function(boolean)>}
	 */
	this.waiters = [];

	/**
	 * The result of the last RPC call
	 * @type {*}
	 */
	this.result = null;

	/**
	 * @private
	 */
	this.url = url;

	/**
	 * @private
	 */
	this.method = method;

	/**
	 * @private
	 */
	this.params = null;

	/**
	 * @private
	 * @type {integer}
	 */
	this.last_id = 0;

	// make the initial RPC call
	this.setParams(params);
};
ivpr.LiveQuery.prototype = {
	/**
	 * Updates the parameters and makes a new RPC call if necessary
	 * @param {?Object.<string,*>|Array.<?>} New parameter values, which may be partially specified
	 */
	setParams: function(newParams) {
		if (ivpr.LiveQuery.detectParamChange(this.params, newParams))
		{
			// params are different, so copy new values and make new rpc call
			if (this.params) {
				for (var k in newParams)
					this.params[k] = newParams[k];
			} else {
				this.params = newParams;
			}

			this.busy = true;

			var self = this;
			var handleResult = function(result, queryId) {
				// ignore old query results
				if (queryId != self.last_id)
					return;
		
				self.busy = false;
				self.result = result;
		
				for (var i in self.listeners)
					self.listeners[i].call(self, self.result);
		
				for (var w in self.waiters)
					self.waiters[w].call(self, self.busy);
			}
			ivpr.LiveQuery.jsonrpc(this.url, this.method, this.params, handleResult, ++this.last_id);

			for (var w in this.waiters)
				this.waiters[w].call(this, this.busy);
		}
	},

	/**
	 * Adds a "result" listener
	 * @param {!function(*)} listener Gets passed the result of the RPC call
	 * @param {!boolean=} callNow If true, calls the listener now if the current RPC call already finished (default true)
	 */
	listen: function(listener, callNow) {
		this.listeners.push(listener);
		if (callNow === false)
			return;
		if (!this.busy)
			listener.call(this, this.result);
	},

	/**
	 * Adds a "busy" listener
	 * @param {!function(boolean)} waiter Function that takes a boolean specifying if the RPC call is busy
	 * @param {!boolean=} callNow If true, calls the waiter now (default true)
	 */
	wait: function(waiter, callNow) {
		this.waiters.push(waiter);
		if (callNow === false)
			return;

		waiter.call(this, this.busy);
	},

	/**
	 * Removes a "result" listener
	 * @param {function(*)} listener Function that was previously passed to listen()
	 */
	unlisten: function(listener) {
		delete this.listeners[this.listeners.indexOf(listener)];
	},

	/**
	 * Removes a "busy" listener
	 * @param {function(boolean)} waiter Function that was previously passed to wait()
	 */
	unwait: function(waiter) {
		delete this.waiters[this.waiters.indexOf(waiter)];
	}
};

/**
 * Recursively detects change in params
 * @param {*} oldParams Complete set of current parameters.
 * @param {*} newParams Newly specified parameters.  Not required to 
 * @return {boolean}
 * @private
 */
ivpr.LiveQuery.detectParamChange = function(oldParams, newParams) {
	if (oldParams === undefined)
		oldParams = null;
	if (newParams === undefined)
		newParams = null;
	var type = typeof oldParams;
	if (type != typeof newParams)
		return true;
	if (type != 'object')
		return String(oldParams) != String(newParams);
	if (!oldParams != !newParams)
		return true;
	for (var k in newParams)
		if (ivpr.LiveQuery.detectParamChange(oldParams[k], newParams[k]))
			return true;
	return false;
};

/**
 * Queries a JSON RPC service.
 * This function requires jQuery for the $.post() functionality.
 * @param method (String) Name of the method to call on the server.
 * @param params (Array or Object) Parameters for the server method.
 * @param resultHandler Function to call when the RPC call returns.  This function will be passed the result of the method.
 * @param queryId Optional id to be associated with this RPC call.  This will be passed as the second parameter to the resultHandler function.
 * @private
 */
ivpr.LiveQuery.jsonrpc = function(url, method, params, resultHandler, queryId)
{
    var request = {
        jsonrpc: "2.0",
        id: queryId || "no_id",
        method: method,
        params: params
    };
    $.post(url, JSON.stringify(request), handleResponse, "json");

    function handleResponse(response)
    {
        if (response.error)
            console.log(JSON.stringify(response, null, 3));
        else if (resultHandler)
            resultHandler(response.result, queryId);
    }
};

/**
 * @private
 */
ivpr.LiveQuery.test = function() {
	

	/**
	 * @param {string} method
	 * @param {Object.<string,*>|Array} params
	 */
	function newDataQuery(method, params)
	{
		return new ivpr.LiveQuery("/WeaveServices/DataService", method, params);
	}

	var waiter1 = function(busy) {
		console.log("RPC busy: ", busy, "; params: ", JSON.stringify(this.params));
	};
	var printResult = function(result) {
		console.log("result: ", JSON.stringify(result));
	};
	var listener1 = function(result) {
		this.setParams({publicMetadata: {keyType: "US County FIPS Code"}});
		this.unlisten(listener1);
	};


	var query1 = newDataQuery('getEntityIdsByMetadata', {entityType: 1, publicMetadata: {keyType: 'test'}});
	query1.wait(waiter1);
	query1.listen(printResult);
	query1.listen(listener1);


	/*
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test"}}
	result: [167685,167686,167687]
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	result: [128749,128748,128751,128750,128747,131641,131640]
	RPC busy: false; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	*/


};
