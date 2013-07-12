// requires jquery ui
// requires jquery
// requires css for ui.menu .ui-menu { width: 150px; }
/**
 * Project Menu creator. It will generate HTML content for the Project Menu. 
 * 
 * @param {String} id The id of the the Project Menu button, so that we can access it in the DOM using JQuery for example
 * 
 * @return {Object} HTML content of the project Menu
 */
	
 function projectMenu (id) {
	 var _projectMenu = '<div> \
			 				<button id="'+ id + '">Project</button> \
			 			</div> \
			 			<ul> \
			 				<li><a href="#" id="prjctnew">New...</a></li> \
			 				<li><a href="#" id="prjctopen">Open</a></li> \
			 				<li><a href="#" id="prjctsave">Save...</a></li> \
			 				<li><a href="#" id="prjctclose">Close</a></li> \
			 			</ul>';
	 					
	 return _projectMenu;
 
 }
 
// use jquery to add event handling and to customize the UI. May be this should be in a Controller file?
// http://jqueryui.com/button/#splitbutton
 function initializeProjectMenu (id) {
	 
	 $('#'+id)
	 	.button({
	 		text: true,
	 		icons: {
	 			secondary: "ui-icon-triangle-1-s"
	 		}
	 	})
	 	.click(function() {
	 		// sets the position of the menu relatively to the right button
	 		var menu = $(this).parent().next().show().position({
	 			my: "left top",
	 			at: "left bottom",
	 			of: this
	 		});
	 		// this hides the menu whenever we click anywhere on the screen
	 		$(document).one( "click", function() {
	            menu.hide(); 
	          });
	         return false;
	 	})
	 	.parent()
	 		.buttonset()
	 		// specifying the jQuery UI for the menu happens here
	 		.next()
	 			.hide()
	 			.menu();
	 		
	 	// TODO add event handling to all of the menu options.

 	$('#prjctnew').click(function() {console.log("project new clicked");});
 	$('#prjctopen').click(function() {console.log("project open clicked");});
 	$('#prjctsave').click(function() {console.log("project save clicked");});
 	$('#prjctclose').click(function() {console.log("project close clicked");});
}
 
