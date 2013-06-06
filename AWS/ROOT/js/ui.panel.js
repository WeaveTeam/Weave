/**
 * Panel / Content Grouping Draft for jQuery UI
 * ist-ui-panel
 * version 0.6
 *
 * Copyright (c) 2009-2010 Igor 'idle sign' Starikov
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 * http://github.com/idlesign/ist-ui-panel
 *
 * Depends:
 *	jquery.ui.core.js
 *	jquery.ui.widget.js
 */
(function($) {

    $.widget('ui.panel', {

        options: {
            event: 'click',
            collapsible: true,
            collapseType: 'default',
            collapsed: false,
            accordion: false,
            collapseSpeed: 'fast',
            draggable: false,

            // ----------
            // options for 'slide-left' & 'slide-right' collapseType panels only
                // true vertical text with svg or filter rendering
                trueVerticalText: true,
                // collapsed panel height, neccessary for true vertical text
                vHeight: '220px',
                // automatically create special stack area (navigation window emulation)
                stackable: true,
            // ----------
            // panel width
            width: 'auto',
            
            // panel height
            height: 'auto',
            
            // suppose that we need ui.toolbar with controls here
            controls: false,
            // store panel state in cookie (jQuery cookie Plugin needed - http://plugins.jquery.com/project/cookie)
            cookie: null, // accepts cookie plugin options, e.g. { name: 'myPanel', expires: 7, path: '/', domain: 'jquery.com', secure: true }

            // styling
            widgetClass: 'ui-helper-reset ui-widget ui-panel',
            headerClass: 'ui-helper-reset ui-widget-header ui-panel-header ui-corner-top',
            contentClass: 'ui-helper-reset ui-widget-content ui-panel-content ui-corner-bottom',
            contentTextClass: 'ui-panel-content-text',
            rightboxClass: 'ui-panel-rightbox',
            controlsClass: 'ui-panel-controls',
            titleClass: 'ui-panel-title',
            titleTextClass: 'ui-panel-title-text',
            iconClass: 'ui-icon',
            hoverClass: 'ui-state-hover',
            collapsePnlClass: 'ui-panel-clps-pnl',
            //icons
            headerIconClpsd: 'ui-icon-triangle-1-e',
            headerIcon: 'ui-icon-triangle-1-s',
            slideRIconClpsd: 'ui-icon-arrowthickstop-1-w',
            slideRIcon: 'ui-icon-arrowthickstop-1-e',
            slideLIconClpsd: 'ui-icon-arrowthickstop-1-e',
            slideLIcon: 'ui-icon-arrowthickstop-1-w'
        },

        _init: function() {
            this._panelize();
        },

        // create panel
        _panelize: function() {
            if (this.element.is('div')) {
                var self = this,
                    o = this.options;

                this.panelBox = this.element;
                // if width option is omitted, get width from css
                if (o.width=='auto')
                    o.width = this.panelBox.css('width');
                else
                    this.panelBox.css('width', o.width);
             
                if (o.height=='auto')
                    o.height = this.panelBox.css('height');
                else
                    this.panelBox.css('height', o.height);
             
                this.panelBox.attr('role', 'panel');
                o.id = this.panelBox.attr('id');
                this.headerBox = this.element.children(':first');
                this.contentBox = this.element.children().eq(1);
                o.content = this.contentBox.html();
                // wrap content to prevent padding issue
                this.contentBox.wrapInner('<div/>');
                this.contentTextBox = this.contentBox.children(':first').addClass(o.contentTextClass);
                this.headerBox.wrapInner('<div><span/></div>');
                // need separate titleBox and titleTextBox to avoid possible collapse/draggable issues
                this.titleBox = this.headerBox.children(':first');
                this.titleTextBox = this.titleBox.children(':first');
                this.titleText = this.titleTextBox.html();
                this.headerBox.prepend('<span/>');
                this.rightBox = this.headerBox.children(':first').addClass(o.rightboxClass);
                // setting up controls
                if (o.controls!=false){
                    // suppose 'o.controls' should be a ui.toolbar control
                    this.rightBox.append('<span/>');
                    this.controlsBox = this.rightBox.children(':first').addClass(o.controlsClass).html(o.controls);
                } else {
                    this.controlsBox = null;
                }

                // styling
                this.panelBox.addClass(o.widgetClass);
                this.headerBox.addClass(o.headerClass);
                this.titleBox.addClass(o.titleClass);
                this.titleTextBox.addClass(o.titleTextClass);
                this.contentBox.addClass(o.contentClass);

                // collapsibility
                if (o.collapsible){
                    switch (o.collapseType) {
                        case 'slide-right':
                            var childIndex = 0;
                            // there is a shift of child element index if controls are enabled
                            if (o.controls)
                                childIndex = 1;
                            
                            this.rightBox.append('<span><span/></span>');
                            this.collapsePanel = this.rightBox.children().eq(childIndex).addClass(o.collapsePnlClass);
                            this.collapseButton =  this.collapsePanel.children(':first').addClass(o.slideRIcon);
                            this.iconBtnClpsd = o.slideRIconClpsd;
                            this.iconBtn = o.slideRIcon;
                            this.ctrlBox = this.controlsBox;
                            break;
                        case 'slide-left':
                            this.headerBox.prepend('<span><span/></span>');
                            this.collapsePanel = this.headerBox.children(':first').addClass(o.collapsePnlClass);
                            this.collapseButton =  this.collapsePanel.children(':first').addClass(o.slideLIcon);
                            this.iconBtnClpsd = o.slideLIconClpsd;
                            this.iconBtn = o.slideLIcon;
                            this.ctrlBox = this.rightBox;
                            break;
                        default:
                            this.headerBox.prepend('<span><span/></span>');
                            this.collapseButton = this.headerBox.children(':first').addClass(o.headerIcon);
                            this.iconBtnClpsd = o.headerIconClpsd;
                            this.iconBtn = o.headerIcon;
                            this.ctrlBox = this.controlsBox;
                            break;
                    }

                    this._buttonHover(this.collapseButton);
                    this.collapseButton.addClass(o.iconClass);
                    if (o.event) {
                        this.collapseButton.bind((o.event) + ".panel", function(event) {return self._clickHandler.call(self, event, this);});
                        this.titleTextBox.bind((o.event) + ".panel", function(event) {return self._clickHandler.call(self, event, this);});
                    }
                    // collapse panel if 'accordion' option is set, switch off vertical text
                    if (o.accordion){
                        o.collapsed = true;
                        o.trueVerticalText = false;
                    }
                    
                    // restore state from cookie
                    if (o.cookie){
                        if (self._cookie()==0)
                            o.collapsed = false;
                        else
                            o.collapsed = true;
                    }
                    
                    // store state as data
                    this.panelBox.data('collapsed', o.collapsed);

                    // stackability (navigation panel emulation) for sliding panels
                    if (o.stackable && $.inArray(o.collapseType, ['slide-right', 'slide-left'])>-1){

                        this.panelDock = this.panelBox.siblings('div[role=panelDock]:first');
                        this.panelFrame = this.panelBox.siblings('div[role=panelFrame]:first');

                        if (this.panelDock.length==0){
                            this.panelDock = this.panelBox.parent(0).prepend('<div>').children(':first');
                            this.panelFrame = this.panelDock.after('<div>').next(':first');
                            this.panelDock.attr('role', 'panelDock').css('float', o.collapseType=='slide-left'?'left':'right');
                            this.panelFrame.attr('role', 'panelFrame').css({'float':o.collapseType=='slide-left'?'left':'right', 'overflow':'hidden'});
                        }

                        if (o.collapsed)
                            this.panelDock.append(this.panelBox);
                        else
                            this.panelFrame.append(this.panelBox);

                    }

                    // panel collapsed - trigger action
                    if (o.collapsed)
                        self.toggle(0, true);

                } else {
                    this.titleTextBox.css('cursor','default');
                }
                // making panel draggable if not accordion-like
                if (!o.accordion && o.draggable && $.fn.draggable)
                    this._makeDraggable();

                this.panelBox.show();


            }
        },

        _cookie: function() {
            var cookie = this.cookie || (this.cookie = this.options.cookie.name || 'ui-panel-'+this.options.id);
            return $.cookie.apply(null, [cookie].concat($.makeArray(arguments)));
        },

        // ui.draggable config
        _makeDraggable: function() {
            this.panelBox.draggable({
                containment: 'document',
                handle: '.ui-panel-header',
                cancel: '.ui-panel-content',
                cursor: 'move'
            });
            this.contentBox.css('position','absolute');
        },

        _clickHandler: function(event, target){
            var o = this.options;

            if (o.disabled)
                return false;
            
            this.toggle(o.collapseSpeed);
            return false;
        },

        // toggle panel state (fold/unfold)
        toggle: function (collapseSpeed, innerCall){
            var self = this,
                o = this.options,
                panelBox = this.panelBox,
                contentBox = this.contentBox,
                headerBox = this.headerBox,
                titleTextBox = this.titleTextBox,
                titleText = this.titleText,
                ctrlBox = this.ctrlBox,
                panelDock = this.panelDock,
                ie = '';

            // that's IE 6-8 for sure, use appropriate style for vertical text
            if (!jQuery.support.leadingWhitespace)
                ie="-ie";

            // split toggle into 'fold' and 'unfold' actions and handle callbacks
            if (contentBox.css('display')=='none')
                this._trigger("unfold");
            else
                this._trigger("fold");

            if (ctrlBox)
                ctrlBox.toggle(0);

            // various content sliding animations
            if (o.collapseType=='default'){
                if (collapseSpeed==0) {

                    if (ctrlBox)
                        ctrlBox.hide();

                    contentBox.hide();
                } else {
                    contentBox.slideToggle(collapseSpeed);
                }
            } else {
                if (collapseSpeed==0){
                    // reverse collapsed option for immediate folding
                    o.collapsed=false;

                    if (ctrlBox)
                        ctrlBox.hide();

                    contentBox.hide();
                } else {
                    contentBox.toggle();
                }

                if (o.collapsed==false){

                    if (o.trueVerticalText){
                        // true vertical text - svg or filter
                        headerBox.toggleClass('ui-panel-vtitle').css('height', o.vHeight);
                        if (ie==''){
                            // fix title text positioning
                            var boxStyle = 'height:'+(parseInt(o.vHeight)-50)+'px;width:100%;position:absolute;bottom:0;left:0;';
                            titleTextBox
                                .empty()
                                // put transparent div over svg object for object onClick simulation
                                .append('<div style="'+boxStyle+'z-index:3;"></div><object style="'+boxStyle+'z-index:2;" type="image/svg+xml" data="data:image/svg+xml;charset=utf-8,<svg xmlns=\'http://www.w3.org/2000/svg\'><text x=\'-'+(parseInt(o.vHeight)-60)+'px\' y=\'16px\' style=\'font-weight:'+titleTextBox.css('font-weight')+';font-family:'+titleTextBox.css('font-family').replace(/"/g, '')+';font-size:'+titleTextBox.css('font-size')+';fill:'+titleTextBox.css('color')+';\' transform=\'rotate(-90)\' text-rendering=\'optimizeSpeed\'>'+titleText+'</text></svg>"></object>')
                                .css('height', o.vHeight);
                        }

                        titleTextBox.toggleClass('ui-panel-vtext'+ie);
                    } else {
                        // vertical text workaround
                        headerBox.attr('align','center');
                        titleTextBox.html(titleTextBox.text().replace(/(.)/g, '$1<BR>'));
                    }
                    panelBox.animate( {width: '2.4em'}, collapseSpeed );

                    if (o.stackable){
                        if (innerCall)
                            // preserve html defined panel order
                            panelDock.append(panelBox);
                        else
                            // last folded on the top of stack
                            panelDock.prepend(panelBox);
                    }

                } else {

                    if (o.stackable)
                        this.panelFrame.append(panelBox);

                    if (o.trueVerticalText){
                        headerBox.toggleClass('ui-panel-vtitle').css('height', 'auto');
                        titleTextBox.empty().append(titleText);
                        titleTextBox.toggleClass('ui-panel-vtext'+ie);
                    } else {
                        headerBox.attr('align','left');
                        titleTextBox.html(titleTextBox.text().replace(/<BR>/g, ' '));
                    }
                    panelBox.animate( {width: o.width}, collapseSpeed );
                }
            }

            // only if not initially folded
            if ( ((collapseSpeed!=0 || o.trueVerticalText) && o.cookie==null) || (!innerCall && o.cookie!=null) )
                o.collapsed = !o.collapsed;

            this.panelBox.data('collapsed', o.collapsed);

            if (!innerCall){
                // save state in cookie if allowed
                if (o.cookie)
                    self._cookie(Number(o.collapsed), o.cookie);

                // inner toggle call to show only one unfolded panel if 'accordion' option is set
                if (o.accordion)
                    $("."+o.accordion+"[role='panel'][id!='"+(o.id)+"']:not(:data(collapsed))").panel('toggle', collapseSpeed, true);
            }

            // css animation for header and button
            this.collapseButton.toggleClass(this.iconBtnClpsd).toggleClass(this.iconBtn);
            headerBox.toggleClass('ui-corner-all');
        },

        // sets panel's content
        content: function(content){
            this.contentTextBox.html(content);
        },

        // destroys panel
        destroy: function(){
            var o = this.options;

            this.headerBox
                .html(this.titleText)
                .removeAttr('align')
                .removeAttr('style')
                .removeClass('ui-panel-vtitle ui-corner-all '+o.headerClass);
            this.contentBox
                .removeClass(o.contentClass)
                .removeAttr('style')
                .html(o.content);
            this.panelBox
                .removeAttr('role')
                .removeAttr('style')
                .removeData('collapsed')
                .unbind('.panel')
                .removeClass(o.widgetClass);

            // handle stacked panels
            if (o.stackable && $.inArray(o.collapseType, ['slide-right', 'slide-left'])>-1){
                this.panelDock.before(this.panelBox);
                // with last stacked panel we destroy Dock and Frame stack components
                if (this.panelDock.children('div[role=panel]').length==0
                    && this.panelFrame.children('div[role=panel]').length==0){
                    this.panelDock.remove();
                    this.panelFrame.remove();
                }
            }

            if (o.cookie)
                this._cookie(null, o.cookie);

            return this;
        },

        _buttonHover: function(el){
            var o = this.options;

            el.bind({
                'mouseover': function(){$(this).addClass(o.hoverClass);},
                'mouseout': function(){$(this).removeClass(o.hoverClass);}
                });
        }

    });

    $.extend($.ui.panel, {
        version: '0.6'
    });

})(jQuery);
