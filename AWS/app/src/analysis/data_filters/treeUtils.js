AnalysisModule.directive('tree', function(queryService) {
	
	
	
});

var treeUtils = {};

treeUtils.toggleSelect = function(treeId){
	$(treeId).dynatree("getRoot").visit(function(node){
		node.toggleSelect();
	});
};
		
treeUtils.deSelectAll = function(treeId){
	$(treeId).dynatree("getRoot").visit(function(node){
		node.select(false);
	});
};
		
treeUtils.selectAll = function(treeId){
	$(treeId).dynatree("getRoot").visit(function(node){
		node.select(true);
	});
};
				
var cmp = function(a, b) {
		return a > b ? 1 : a < b ? -1 : 0;
};

cmpByKey = function(node1, node2) {
	return cmp(node1.data.key, node2.data.key);
};

cmpByTitle = function(node1, node2) {
	return cmp(node1.data.title, node2.data.title);
};

treeUtils.getSelectedNodes = function(treeId) {
	var treeSelection = {};
	
	var root = $(treeId).dynatree("getRoot");
	
	for (var i = 0; i < root.childList.length; i++) {
		var level1 = root.childList[i];
		for(var j = 0; j < level1.childList.length; j++) {
			var level2 = level1.childList[j];
			if(level1.childList[j].bSelected) {
				if(!treeSelection[level1.data.key]) {
					var level2Key = level2.data.key;
					treeSelection[level1.data.key] = {};
					treeSelection[level1.data.key].label = level1.data.title;
					var level2Obj = {};
					level2Obj[level2Key] = level2.data.title;
					treeSelection[level1.data.key].level2s = [level2Obj];
				} else {
					var level2Key = level2.data.key;
					var level2Obj = {};
					level2Obj[level2Key] = level2.data.title;
					treeSelection[level1.data.key].level2s.push( { level2Key : level2.data.title } );
				}
			}
		}
	}
	
	return selectedNodes;
};
