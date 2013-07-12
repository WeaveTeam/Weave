//goog.provide('weave');
goog.provide('weave.MyComponent');

//goog.require('goog.dom');

/**
 * @param {string} aStr some value
 * @param {number} bNum some other value
 * @constructor
 */
weave.MyComponent = function(aStr, bNum) {
  this.a = aStr;
  this.b = bNum;
};

/**
 * @param {string} text some text to display in the console
 * @return {string} some result
 */
weave.MyComponent.prototype.doSomething = function(text) {
	var str = ['text=', text, ' a=', this.a, ' b=', this.b].join('');
	
	//console.log(str);
	
	return str;
};
