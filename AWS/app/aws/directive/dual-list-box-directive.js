angular.module('aws.directives.dualListBox', [])
/*
 * Is aws.Main needed? isn't it just routing?
 */
.directive(
        'dualListBox',
        function($compile, $timeout) {
            return {
                restrict: "A",
                //templateURL: "tpls/dualList.tpls.html",
                //scope: {options: "="},
                compile: function(telem, attrs) {
                    // telem is the template elememt? if no template then no tElem?
                    // same as "container" below.... 
                    //var container = $compile(telem);
                    return function(scope, elem, attr) {
                        scope.$watch(function() {
                            return scope.options;
                        }, function(newval, oldval) {
                            $timeout(function() {
                                elem.trigger('bootstrapduallistbox.refresh');
                            });
                        });

                        var settings = {
                            bootstrap2compatible: false,
                            preserveselectiononmove: false, // 'all' / 'moved' / false
                            moveonselect: true, // true/false (forced true on androids, see the comment later)
                            initialfilterfrom: '', // string, filter selectables list on init
                            initialfilterto: '', // string, filter selected list on init
                            helperselectnamepostfix: '_helper', // 'string_of_postfix' / false
                            infotext: 'Showing all {0}', // text when all options are visible / false for no info text
                            infotextfiltered: '<span class="label label-warning">Filtered</span> {0} from {1}', // when not all of the options are visible due to the filter
                            infotextempty: 'Empty list', // when there are no options present in the list
                            selectorminimalheight: 100,
                            showfilterinputs: true,
                            filterplaceholder: 'Filter',
                            filtertextclear: 'show all',
                            nonselectedlistlabel: false, // 'string', false
                            selectedlistlabel: false // 'string', false
                        };
                        var container = $('<div class="row bootstrap-duallistbox-container"><div class="col-md-6 box1"><span class="info-container"><span class="info"></span><button type="button" class="btn btn-default btn-xs clear1 pull-right">' + settings.filtertextclear + '</button></span><input placeholder="' + settings.filterplaceholder + '" class="filter" type="text"><div class="btn-group buttons"><button type="button" class="btn btn-default moveall" title="Move all"><i class="glyphicon glyphicon-arrow-right"></i><i class="glyphicon glyphicon-arrow-right"></i></button><button type="button" class="btn btn-default move" title="Move selected"><i class="glyphicon glyphicon-arrow-right"></i></button></div><select multiple="multiple" data-duallistbox_generated="true"></select></div><div class="col-md-6 box2"><span class="info-container"><span class="info"></span><button type="button" class="btn btn-default btn-xs clear2 pull-right">' + settings.filtertextclear + '</button></span><input placeholder="' + settings.filterplaceholder + '" class="filter" type="text"><div class="btn-group buttons"><button type="button" class="btn btn-default remove" title="Remove selected"><i class="glyphicon glyphicon-arrow-left"></i></button><button type="button" class="btn btn-default removeall" title="Remove all"><i class="glyphicon glyphicon-arrow-left"></i><i class="glyphicon glyphicon-arrow-left"></i></button></div><select multiple="multiple" data-duallistbox_generated="true"></select></div></div>');
                        var elements = {
                            originalselect: elem, //$this,
                            box1: $('.box1', container),
                            box2: $('.box2', container),
                            //filterinput1: $('.box1 .filter', container),
                            //filterinput2: $('.box2 .filter', container),
                            //filter1clear: $('.box1 .clear1', container),
                            //filter2clear: $('.box2 .clear2', container),
                            info1: $('.box1 .info', container),
                            info2: $('.box2 .info', container),
                            select1: $('.box1 select', container),
                            select2: $('.box2 select', container),
                            movebutton: $('.box1 .move', container),
                            removebutton: $('.box2 .remove', container),
                            moveallbutton: $('.box1 .moveall', container),
                            removeallbutton: $('.box2 .removeall', container),
                            form: $($('.box1 .filter', container)[0].form)
                        };
                        var i = 0;
                        var selectedelements = 0;
                        var originalselectname = attr.name || "";
                        var c = attr.class;
                        var height;

                        function init() {
                            container.addClass('moveonselect');
                            if (typeof c !== 'undefined' && c) {
                                c = c.match(/\bspan[1-9][0-2]?/);
                                if (!c) {
                                    c = attr.class;
                                    c = c.match(/\bcol-md-[1-9][0-2]?/);
                                }
                            }
                            if ( !! c) {
                                container.addClass(c.toString());
                            }
                            if (elements.originalselect.height() < settings.selectorminimalheight) {
                                height = settings.selectorminimalheight
                            } else {
                                height = elements.originalselect.height();
                            }
                            elements.select1.height(height);
                            elements.select2.height(height);
                            elem.addClass('hide');
                            //update selection states();
                            //elements.filterinput1.hide();
                            //elements.filterinput2.hide();
                            var box = $(container.insertBefore(elem));
                            bindevents();
                            refreshselects();
                            updatesselectionstates();
                            //elem.html(box);
                            $compile(box)(scope);
                            //$compile(elem.contents())(scope);
                            //console.log(elem);

                        }
                        init();

                        function updatesselectionstates() {
                            $(elem).find('option').each(function(index, item) {
                                var $item = $(item);
                                if (typeof($item.data('original-index')) === 'undefined') {
                                    $item.data('original-index', i++);
                                }
                                if (typeof($item.data('_selected')) === 'undefined') {
                                    $item.data('_selected', false);
                                }
                            });
                        }
                        scope.updateselections = refreshselects;

                        function refreshselects() {
                            selectedelements = 0;
                            elements.select2.empty();
                            elements.select1.empty();
                            $(elem).find('option').each(function(index, item) {
                                var $item = $(item);
                                if ($item.prop('selected')) {
                                    selectedelements++;
                                    elements.select2.append($item.clone(true).prop('selected',
                                        $item.data('_selected')));
                                } else {
                                    elements.select1.append($item.clone(true).prop('selected',
                                        $item.data('_selected')));
                                }
                            });
                            // ommited filters here
                        }
                        // functions formatstring(s, args) and refreshinfo()... don't need?'

                        function bindevents() {
                            elements.form.submit(function(e) {
                                if (elements.filterinput1.is(":focus")) {
                                    e.preventDefault();
                                    elements.filterinput1.focusout();
                                } else if (elements.filterinput2.is(":focus")) {
                                    e.preventDefault();
                                    elements.filterinput2.focusout();
                                }
                            }); // probably  not needed

                            elements.originalselect.on('bootstrapduallistbox.refresh', function(e, clearselections) {
                                updatesselectionstates();

                                if (!clearselections) {
                                    saveselections1();
                                    saveselections2();
                                } else {
                                    clearselections12();
                                }

                                refreshselects();
                            });

                            //                        elements.filter1clear.on('click', function() {
                            //                            elements.filterinput1.val('');
                            //                            refreshselects();
                            //                        });
                            //
                            //                        elements.filter2clear.on('click', function() {
                            //                            elements.filterinput2.val('');
                            //                            refreshselects();
                            //                        });

                            elements.movebutton.on('click', function() {
                                move();
                            });

                            elements.moveallbutton.on('click', function() {
                                moveall();
                            });

                            elements.removebutton.on('click', function() {
                                remove();
                            });

                            elements.removeallbutton.on('click', function() {
                                removeall();
                            });

                            //                        elements.filterinput1.on('change keyup', function() {
                            //                            filter1();
                            //                        });
                            //
                            //                        elements.filterinput2.on('change keyup', function() {
                            //                            filter2();
                            //                        });

                            settings.preserveselectiononmove = false;

                            elements.select1.on('change', function() {
                                move();
                            });
                            elements.select2.on('change', function() {
                                remove();
                            });

                        }

                        function saveselections1() {
                            elements.select1.find('option').each(function(index, item) {
                                var $item = $(item);

                                elements.originalselect.find('option').eq($item.data('original-index'))
                                    .data('_selected', $item.prop('selected'));
                            });
                        }

                        function saveselections2() {
                            elements.select2.find('option').each(function(index, item) {
                                var $item = $(item);

                                elements.originalselect.find('option').eq($item.data('original-index'))
                                    .data('_selected', $item.prop('selected'));
                            });
                        }

                        function clearselections12() {
                            elements.select1.find('option').each(function() {
                                elements.originalselect.find('option').data('_selected', false);
                            });
                        }

                        function sortoptions(select) {
                            select.find('option').sort(function(a, b) {
                                return ($(a).data('original-index') > $(b).data('original-index')) ? 1 : -1;
                            }).appendTo(select);
                        }

                        function changeselectionstate(original_index, selected) {
                            elements.originalselect.find('option').each(function(index, item) {
                                var $item = $(item);

                                if ($item.data('original-index') === original_index) {
                                    $item.prop('selected', selected);
                                }
                            });
                        }

                        function move() {
                            if (settings.preserveselectiononmove === 'all') {
                                saveselections1();
                                saveselections2();
                            } else if (settings.preserveselectiononmove === 'moved') {
                                saveselections1();
                            }


                            elements.select1.find('option:selected').each(function(index, item) {
                                var $item = $(item);

                                if (!$item.data('filtered1')) {
                                    changeselectionstate($item.data('original-index'), true);
                                }
                            });

                            refreshselects();
                            triggerchangeevent();

                            sortoptions(elements.select2);
                        }

                        function remove() {
                            if (settings.preserveselectiononmove === 'all') {
                                saveselections1();
                                saveselections2();
                            } else if (settings.preserveselectiononmove === 'moved') {
                                saveselections2();
                            }

                            elements.select2.find('option:selected').each(function(index, item) {
                                var $item = $(item);

                                if (!$item.data('filtered2')) {
                                    changeselectionstate($item.data('original-index'), false);
                                }
                            });

                            refreshselects();
                            triggerchangeevent();

                            sortoptions(elements.select1);
                        }

                        function moveall() {
                            if (settings.preserveselectiononmove === 'all') {
                                saveselections1();
                                saveselections2();
                            } else if (settings.preserveselectiononmove === 'moved') {
                                saveselections1();
                            }

                            elements.originalselect.find('option').each(function(index, item) {
                                var $item = $(item);

                                if (!$item.data('filtered1')) {
                                    $item.prop('selected', true);
                                }
                            });

                            refreshselects();
                            triggerchangeevent();
                        }

                        function removeall() {
                            if (settings.preserveselectiononmove === 'all') {
                                saveselections1();
                                saveselections2();
                            } else if (settings.preserveselectiononmove === 'moved') {
                                saveselections2();
                            }

                            elements.originalselect.find('option').each(function(index, item) {
                                var $item = $(item);

                                if (!$item.data('filtered2')) {
                                    $item.prop('selected', false);
                                }
                            });

                            refreshselects();
                            triggerchangeevent();
                        }

                        function triggerchangeevent() {
                            elements.originalselect.trigger('change');
                        }
                    }
                }

            }
        });