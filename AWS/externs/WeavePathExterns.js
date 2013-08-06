/**
 * @fileoverview Externs for Weave Path API
 *
 * @see http://info.oicweave.org/projects/weave/wiki/JavaScript_API
 * @externs
 */

/**
 * @typedef {Array.<string>}
 */
var Path;

/**
 * @constructor
 * @param {Path} path The base path Array
 *
 * @return {!WeavePath}
 */
function WeavePath(path) {}

/**
 * This function returns a copy of the current path Array.
 * @param {Path=} relativePath optional list of names to be appended to the result.
 * @return {Path}
 */
function getPath(relativePath) {};

/**
 * Gets an Array of child names under the object at the current path or relative to the current path.
 * @param {Path=} relativePath an optional list of names to be appended to the result.
 * @return {Array.<string>}
 */
function getNames(relativePath) {};

/**
 * Gets the type (qualified class name) of the object at the current path or relative to the current path.
 * @param {Path=} relativePath an optional list of names relative to the current path.
 * @return {string}
 */
function getType(relativePath) {};