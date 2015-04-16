// this code requires weave-tools.js

function getColumnIds(weave)
{
	return weave.path().getValue("\
		import 'weave.data.AttributeColumns.ReferencedColumn';\
		import 'weave.data.DataSources.WeaveDataSource';\
		var cols = WeaveAPI.SessionManager.getLinkableDescendants(WeaveAPI.globalHashMap, ReferencedColumn);\
		return cols.filter(col => col.getDataSource() is WeaveDataSource).map(col => {\
				var meta = col.metadata.getSessionState();\
        if (!meta.weaveEntityId)\
            weaveTrace(Class('weave.compiler.Compiler').stringify(meta));\
				return meta.weaveEntityId || meta;\
		});\
	");
}

function arrayToSet(array)
{
	var lookup = {};
	array.forEach(function(id){ lookup[id] = id; });
	return Object.keys(lookup).map(function(key){ return lookup[key]; });
}

function identifySQLTables(weave, adminServiceUrl, user, pass)
{
	function getEntities(ids, handler)
	{
		queryService(
				adminServiceUrl,
				'getEntities',
				[user, pass, ids],
				handler
		);
	}
	
	var sqlInfo = [];
	var ids = getColumnIds(weave);
	// filter out sets of metadata as opposed to id numbers
	var missingIds = ids.filter(function(id){ return typeof id == 'object'; });
	ids = ids.filter(function(id){ return typeof id != 'object'; });
	// find ids corresponding to metadata
	bulkQueryService(
		adminServiceUrl,
		'findEntityIds',
		missingIds.map(function(meta){ return [srcuser, srcpass, meta, null]; }),
		function(results){
			// append found ids
			results.forEach(function(result){
				if (result.length)
					ids.push(result[0]);
			});
			
			// remove duplicate ids
			ids = arrayToSet(ids);
			
			// for each id, find its parent table
			getEntities(ids, function(columns){
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
				getEntities(tableIds, function(tables){
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
		}
	);
}
