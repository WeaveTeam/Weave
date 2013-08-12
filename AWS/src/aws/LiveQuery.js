goog.require('aws');

goog.provide('aws.LiveQuery');

/**
 * Automatically makes JSON RPC calls.  Requires jQuery for ajax.
 * @constructor
 * @param {string} url The URL of the JSON-RPC service
 * @param {string} method The name of the RPC call
 * @param {?Object.<string,*>|Array.<?>} params Initial parameters for the RPC call
 */
aws.LiveQuery = function(url, method, params) {
	/**
	 * busy status
	 * @type {boolean}
	 * @private
	 */
	this.busy = false;

	/**
	 * "result" listeners
	 * @type {Array.<function(*)>}
	 * @private
	 */
	this.listeners = [];

	/**
	 * "busy" listeners
	 * @type {Array.<function(boolean)>}
	 * @private
	 */
	this.waiters = [];

	/**
	 * The result of the last RPC call
	 * @type {*}
	 * @private
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
	 * @type {number}
	 * @private
	 */
	this.last_id = 0;

	// make the initial RPC call
	this.setParams(params);
};

/**
 * Updates the parameters and makes a new RPC call if necessary
 * @param {?Object.<string,*>|Array.<?>} newParams New parameter values, which may be partially specified
 */
aws.LiveQuery.prototype.setParams = function(newParams) {
	if (aws.LiveQuery.detectParamChange(this.params, newParams))
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
		};
		aws.queryService(this.url, this.method, this.params, handleResult, ++this.last_id);

		for (var w in this.waiters)
			this.waiters[w].call(this, this.busy);
	}
};

/**
 * Adds a "result" listener
 * @param {!function(*)} listener Gets passed the result of the RPC call
 * @param {!boolean=} callNow If true, calls the listener now if the current RPC call already finished (default true)
 */
aws.LiveQuery.prototype.listen = function(listener, callNow) {
	this.listeners.push(listener);
	if (callNow === false)
		return;
	if (!this.busy)
		listener.call(this, this.result);
};

/**
 * Adds a "busy" listener
 * @param {!function(boolean)} waiter Function that takes a boolean specifying if the RPC call is busy
 * @param {!boolean=} callNow If true, calls the waiter now (default true)
 */
aws.LiveQuery.prototype.wait = function(waiter, callNow) {
	this.waiters.push(waiter);
	if (callNow === false)
		return;

	waiter.call(this, this.busy);
};

/**
 * Removes a "result" listener
 * @param {function(*)} listener Function that was previously passed to listen()
 */
aws.LiveQuery.prototype.unlisten = function(listener) {
	delete this.listeners[this.listeners.indexOf(listener)];
};

/**
 * Removes a "busy" listener
 * @param {function(boolean)} waiter Function that was previously passed to wait()
 */
aws.LiveQuery.prototype.unwait = function(waiter) {
	delete this.waiters[this.waiters.indexOf(waiter)];
};

/**
 * Recursively detects change in params
 * @param {*} oldParams Complete set of current parameters.
 * @param {*} newParams Newly specified parameters.  Not required to 
 * @return {boolean}
 * @private
 */
aws.LiveQuery.detectParamChange = function(oldParams, newParams) {
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
		if (aws.LiveQuery.detectParamChange(oldParams[k], newParams[k]))
			return true;
	return false;
};

/**
 * @private
 */
aws.LiveQuery.test = function() {
	

	/**
	 * @param {string} method
	 * @param {Object.<string,*>|Array} params
	 */
	function newDataQuery(method, params)
	{
		return new aws.LiveQuery("/WeaveServices/DataService", method, params);
	}

	/** @this {aws.LiveQuery} */
	var waiter1 = function(busy) {
		console.log("RPC busy: ", busy, "; params: ", JSON.stringify(this.params));
	};
	var printResult = function(result) {
		console.log("result: ", JSON.stringify(result));
	};
	/** @this {aws.LiveQuery} */
	var listener1 = function(result) {
		this.setParams({publicMetadata: {keyType: "test1"}});
		this.unlisten(listener1);
	};


	var query1 = newDataQuery('getEntityIdsByMetadata', {entityType: 1, publicMetadata: {keyType: 'test'}});
	query1.wait(waiter1);
	query1.listen(printResult);
	query1.listen(listener1);


	/*
	Sample output:
	
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test"}}
	result: [167685,167686,167687]
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	RPC busy: true; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	result: [128749,128748,128751,128750,128747,131641,131640]
	RPC busy: false; params: {"entityType":1,"publicMetadata":{"keyType":"test1"}}
	*/


};
