// This code assumes the weave variable has already been set.

// init event handlers
weave.addEventListener("dragenter", dragEnter, false);
weave.addEventListener("dragexit", dragExit, false);
weave.addEventListener("dragover", dragOver, false);
weave.addEventListener("drop", drop, false);

function dragEnter(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragExit(evt) {
	evt.stopPropagation();
	evt.preventDefault();
}

function dragOver(evt) {
	evt.stopPropagation();
	evt.preventDefault();
	evt.dataTransfer.dropEffect = 'copy';
}
 
function drop(evt) {
	evt.stopPropagation();
	evt.preventDefault();

	var files = evt.dataTransfer.files;
	var count = files.length;

	// Only call the handler if 1 or more files was dropped.
	if (count > 0)
		handleFile(files[0]);
}

function handleFile(file) {
	//console.log(file.name);

	var reader = new FileReader();

	// init the reader event handlers
	reader.onprogress = function (evt) {
		if (evt.lengthComputable) {
			var loaded = (evt.loaded / evt.total);
			
			//console.log(loaded * 100);
		}
	};
	reader.onloadend = function(evt) {
		var data = evt.target.result.split('base64,')[1];
		var libs = ['weave.compiler.StandardLib', 'weave.Weave'];
		var script = "WeaveAPI.topLevelApplication['visApp'].handleDraggedFile(name, StandardLib.atob(data))";
		weave.evaluateExpression([], script, {"name": file.name, "data": data}, libs);
	};

	// begin the read operation
	reader.readAsDataURL(file);
}
