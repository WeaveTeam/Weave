// this code requires weave-tools.js

function AdminService(url, user, pass)
{
	this.url = url;
	this.user = user;
	this.pass = pass;
	this.promise = queryService(this.url, 'authenticate', [this.user, this.pass]);
}
AdminService.prototype.queue = function(method, params)
{
	return this
		.bulkQueue(method, [params])
		.then(function(results) {
			return results[0];
		});
};
AdminService.prototype.bulkQueue = function(method, queryIdToParams)
{
	var methodArray = [];
	var queryIdArray = [];
	var paramsArray = [];
	for (var queryId in queryIdToParams)
	{
		var m = typeof method === 'string' ? method : method[queryId];
		methodArray.push(m);
		queryIdArray.push(queryId);
		paramsArray.push(queryIdToParams[queryId]);
	}
	return this.promise = this.promise
		.then(function() {
			return bulkQueryService(this.url,
				['authenticate'].concat(methodArray),
				[[this.user, this.pass]].concat(paramsArray)
			);
		}.bind(this))
		.then(function(results) {
			results.shift();
			if (Array.isArray(queryIdToParams))
				return results;
			var obj = {};
			for (var i in results)
				obj[queryIdArray[i]] = results[i];
			return obj;
		});
};
AdminService.prototype.then = function(resolve, reject) {
	return this.promise = this.promise.then(resolve, reject);
};

function getColumnIds(weave)
{
	return weave.path().getValue("\
		var cols = getLinkableDescendants(WeaveAPI.globalHashMap, ReferencedColumn);\
		return cols.filter(col => col.getDataSource() is WeaveDataSource).map(col => {\
			var meta = col.metadata.getSessionState();\
			if (!meta.weaveEntityId)\
				weaveTrace(Compiler.stringify(meta));\
			return meta.weaveEntityId || meta;\
		});\
	");
}

function getTableIds(weave, adminService)
{
	return adminService
		.queue('getEntities', [getColumnIds(weave)])
		.then(function(columns){
			return arrayToSet(columns.map(function(column){
				return column.parentIds[0];
			}));
		});
}

/*
Example usage for migrateEntityTrees():

var fromAdmin = new AdminService('http://old.example.com/WeaveServices/AdminService', 'olduser', 'oldpass');
var toAdmin = new AdminService('http://new.example.com/WeaveServices/AdminService', 'newuser', 'newpass');
fromAdmin
.queue('findEntityIds', [{entityType: 'table', title: '*example search*'}, ['title']])
.then(ids => migrateEntityTrees(fromAdmin, toAdmin, ids, 'old.example.com'))

*/

/**
 * Migrates trees of entities from one AdminService to another.
 * @param fromAdmin Either an AdminService or a String to use as the metadata property name for storing old IDs
 * @param toAdmin An AdminService
 * @param trees Either an Array of Entity Trees from getEntityTree() or an Array of IDs to pass to getEntityTree() along with the fromAdmin AdminService.
 * @param idMapping A String to use as the metadata property name for storing old IDs.
 * 					Internally this param is used to pass an object mapping old IDs to new IDs.
 * @returns A Promise.
 */
function migrateEntityTrees(fromAdmin, toAdmin, trees, idMapping)
{
	var idProp;
	if (typeof idMapping === 'string')
	{
		idProp = idMapping;
		idMapping = {};
	}
	else if (typeof fromAdmin === 'string')
	{
		idProp = fromAdmin;
	}
	else
	{
		idProp = fromAdmin.url;
	}
	if (!idMapping)
		idMapping = {};
	
	return toAdmin
		.then(function() {
			if (trees.every(function(tree){ return typeof tree === 'number'; }))
				return getEntityTree(fromAdmin, trees);
			return trees;
		})
		.then(function(entityTrees) {
			trees = entityTrees;
			return toAdmin
				.bulkQueue('newEntity', trees.map(function(tree, index) {
					tree.publicMetadata[idProp] = "" + tree.id;
					var parentId = -1;
					if (tree.parentIds.length)
						parentId = tree.parentIds[0];
					if (idMapping.hasOwnProperty(parentId))
						parentId = idMapping[parentId];
					return [tree, parentId, index];
				}));
		})
		.then(function(newTreeIds) {
			trees.forEach(function(tree, index) {
				idMapping[tree.id] = newTreeIds[index];
			});
			var childTrees = [].concat.apply([], trees.map(function(tree) { return tree.children; }));
			if (childTrees.length)
				return migrateEntityTrees(idProp, toAdmin, childTrees, idMapping);
		});
}

function arrayToSet(array)
{
	var lookup = {};
	array.forEach(function(id){ lookup[id] = id; });
	return Object.keys(lookup).map(function(key){ return lookup[key]; });
}

function identifySQLTables(weave, adminServiceUrl)
{
	var getEntities = queryService.bind(null, adminServiceUrl, 'getEntities');
	
	var sqlInfo = [];
	var ids = getColumnIds(weave);
	// filter out sets of metadata as opposed to id numbers
	var missingIds = ids.filter(function(id){ return typeof id == 'object'; });
	ids = ids.filter(function(id){ return typeof id != 'object'; });
	// find ids corresponding to metadata
	bulkQueryService(
		adminServiceUrl,
		'findEntityIds',
		missingIds.map(function(meta){ return [meta, null]; })
	).then(function(results){
		// append found ids
		results.forEach(function(result){
			if (result.length)
				ids.push(result[0]);
		});
		
		// remove duplicate ids
		ids = arrayToSet(ids);
		
		// for each id, find its parent table
		getEntities(ids).then(function(columns){
			// strip out geometry columns, saving their sql info
			columns = columns.filter(function(column){
				var info = ['connection', 'sqlSchema', 'sqlTablePrefix'].map(function(prop){ return prop + ' ' + column.privateMetadata[prop]; });
				var i = 2;
				console.log(info);
				var prefix = info[i].split(' ').pop();
				if (prefix != 'undefined')
				{
					info[i] = 'sqlTable ' + prefix+'_dbfdata';
					sqlInfo.push(info.concat());
					info[i] = 'sqlTable ' + prefix+'_geometry';
					sqlInfo.push(info.concat());
					info[i] = 'sqlTable ' + prefix+'_metadata';
					sqlInfo.push(info.concat());
					return false;
				}
				return true;
			});
			
			var tableIds = columns.map(function(column){ return column.parentIds[0]; });
			tableIds = arrayToSet(tableIds);
			getEntities(tableIds).then(function(tables){
				tables.forEach(function(table){
					var info = ['connection', 'sqlSchema', 'sqlTable'].map(function(prop){ return prop + ' ' + table.privateMetadata[prop]; });
					if (info[0])
						sqlInfo.push(info);
				});
				var output = sqlInfo.map(function(a){ return a.join('; '); }).sort();
				output = arrayToSet(output);
				console.log(output.join('\n'));
			});
		});
	});
}
