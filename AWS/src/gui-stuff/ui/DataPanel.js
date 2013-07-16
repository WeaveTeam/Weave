// requires jquery
// requires jquery UI

function dataDialog () {
	
	var _dialog;
	
	_dialog = '<div id="dataDialog" title="Data"> \
					<div id="dbauthentication">  \
						<br><br>	\
						Connection Name: <input type="text" name="ConnectionName" value=""><br> \
						Password: <input type="password" name="Password2" value=""><br> \
						<button id="dbConnectButton">Connect</button> <br>	\
					</div> \
					<div id="dbhierarchy"> \
						Data Tables <br> <select id="dataTables"></select><br> \
						Columns	<br><select id="columns"></select>	\
					</div> \
				</div>';
	
	return _dialog;

}

function dataButton () {
	var _dataButton = '<button id="dataButton">Data...</button>';
	return _dataButton;
}


// jquery for the button UI and the button event handling
function initializeDataButton() {
	$('#dataButton')
		.button
		.click(function () {
			$('#dataDialog').dialog("open");
		});
}

// jquery for the dialog UI and its buttons event handlings
function initializeDataDialog() {
	$('#dataDialog').dialog({
        autoOpen : false,
        height : 150,
        width : 200,
        modal : true,
        buttons : {
          Close : function() {
            $(this).dialog("close");
          }
       }
	});
	
	// TODO jquery and event handling for the data panel content. 
	$('#dbConnectButton').button()
		.click( function() { console.log("connect button clicked"); } );
}
