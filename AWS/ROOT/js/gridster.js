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
                  max_size_x : 3
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
                
                $('#scriptButton').button().click(function() {
                  // enter run script here
                });
                
                $('#callWeaveButton').button().click(function() {
                  // enter function here for calling weave
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
                    
                var scriptCombobox = $('#scriptCombobox');
                
                scriptCombobox.append($("<option/>").val('script1').text(
                          "Script 1"));
                scriptCombobox.append($("<option/>").val('script2')
                          .text("Script 2"));
                
                var dataCombobox = $('#dataCombobox');
                
                dataCombobox.append($("<option/>").val('script1').text(
                          "Obesity.csv"));
                dataCombobox.append($("<option/>").val('script2')
                          .text("Cars.csv"));
                
                $('#weaveDialog').dialog({
                  autoOpen : false,
                  height : 500,
                  width : 750,
                  modal : true,
                  buttons : {
                    Close : function() {
                      // handleCancelOption();
                      $(this).dialog("close");
                    },
                  }
                })
                $('#weaveButton').button().click(function() {
                  $('#weaveDialog').dialog("open");
                });
                
                $('#panel6ImportButton').button().click(function() {
                	
                });
                
                $('#panel6SaveButton').button().click(function() {
                  	
                });
                $('#panel6EditButton').button().click(function() {
                
                });
                
              }));
      // available methods are listed here:
      // http://ivpr.github.io/Weave-Binaries/javadoc/weave/servlets/DataService.html
      function queryDataService(method, params, resultHandler, queryId) {
        // console.log('queryDataService ',method,' ',params);
        var url = '/WeaveServices/DataService';
        var request = {
          jsonrpc : "2.0",
          id : queryId || "no_id",
          method : method,
          params : params
        };
        $.post(url, JSON.stringify(request), handleResponse, "json");

        function handleResponse(response) {
          if (response.error)
            console.log(JSON.stringify(response, null, 3));
          else
            resultHandler(response.result, queryId);
        }
      }
      function test1() {
        var tableId = 107945;
        var name = 'Percent Obese (BMI >= 30)';

        // get the IDs of all the fields in a table
        queryDataService(
            'getEntityChildIds',
            [ tableId ],
            function(ids) {

              console.log("test1 received child ids: ", ids);

              // get the metadata for each child
              queryDataService(
                  'getEntitiesById',
                  [ ids ],
                  function(entities) {

                    console.log("test1 received ",
                        entities.length, " entities");

                    // filter by name
                    entities = entities
                        .filter(function(e) {
                          return e.publicMetadata.name == name;
                        });
                    console.log("test1 filtered ",
                        entities.length, " entities");
                    entities.sort(sortBy('publicMetadata',
                        'year'));

                    console
                        .log(
                            "test1 filtered by name, sorted by year: ",
                            entities);
                    console
                        .log(
                            "test1 corresponding years: ",
                            entities
                                .map(function(e) {
                                  return e.publicMetadata.year;
                                }));
                    console.log(
                        "test1 corresponding ids: ",
                        entities.map(function(e) {
                          return e.id;
                        }));
                  });
            });
      }
      test1();

    });
