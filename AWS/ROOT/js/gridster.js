require.config({
	paths : {
		'jquery' : 'jquery-1.9.1',
		'jquery-ui' : 'jquery-ui-1.10.3.custom'
	},
	shim : {
		'jquery.gridster' : [ 'jquery' ],
		'jquery-ui' : [ 'jquery' ]
	}
});

require(
		[ 'jquery', 'jquery.gridster', 'jquery-ui' ],
		function($) {
			$(document)
					.ready(
							$(function() { // DOM Ready

								$(".gridster ul").gridster({
									widget_margins : [ 10, 10 ],
									widget_base_dimensions : [ 140, 140 ],
									max_size_x: 3
								});

								$('#projectButton').button({
									icons : {
										secondary : "ui-icon-triangle-1-s"
									}
								});

								$('#dataDialog').dialog({
									autoOpen : false,
									height : 500,
									width : 750,
									modal : true,
									buttons : {
										Select : function() {
											// handleSelectOption();
											$(this).dialog("close");
										},
										Cancel : function() {
											// handleCancelOption();
											$(this).dialog("close");
										},
									}
								});
								
								$('#dataButton').button().click(function() {
									$('#dataDialog').dialog("open");
								});

								$('.portlet')
										.addClass(
												"ui-widget ui-widget-content ui-helper-clearfix ui-corner-all")
										.find(".portlet-header")
										.addClass(
												"ui-widget-header ui-corner-all")
										.prepend(
												"<span class='ui-icon ui-icon-minusthick'></span>")
										.end().find(".portlet-content");

								$(".portlet-header .ui-icon")
										.click(
												function() {
													$(this)
															.toggleClass(
																	"ui-icon-minusthick")
															.toggleClass(
																	"ui-icon-plusthick");
													$(this)
															.parents(
																	".portlet:first")
															.find(
																	".portlet-content")
															.toggle();
												});

							}));
			

		});