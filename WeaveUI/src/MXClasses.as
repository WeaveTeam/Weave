/*
	Weave (Web-based Analysis and Visualization Environment)
	Copyright (C) 2008-2011 University of Massachusetts Lowell
	
	This file is a part of Weave.
	
	Weave is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License, Version 3,
	as published by the Free Software Foundation.
	
	Weave is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with Weave.  If not, see <http://www.gnu.org/licenses/>.
*/

package
{
	/**
	 * This class references all classes under packages starting with mx.* in the Flex framework manifest.xml.
	 * Referencing this class in an MXML Application forces the compiler to generate actionscript code that
	 * includes all the 'mixins' required to be able to dynamically create these classes at runtime.
	 * 
	 * @author adufilie
	 */
	public class MXClasses
	{
		import mx.containers.Accordion; Accordion;
		import mx.states.AddChild; AddChild;
		import mx.effects.AddChildAction; AddChildAction;
		import mx.effects.AddItemAction; AddItemAction;
		import mx.effects.AnimateProperty; AnimateProperty;
		import mx.core.Application; Application;
		import mx.containers.ApplicationControlBar; ApplicationControlBar;
		import mx.collections.ArrayCollection; ArrayCollection;
		import mx.graphics.BitmapFill; BitmapFill;
		import mx.effects.Blur; Blur;
		import mx.containers.Box; Box;
		import mx.controls.Button; Button;
		import mx.controls.ButtonBar; ButtonBar;
		import mx.containers.Canvas; Canvas;
		import mx.controls.CheckBox; CheckBox;
		import mx.controls.ColorPicker; ColorPicker;
		import mx.controls.ComboBox; ComboBox;
		import mx.containers.utilityClasses.ConstraintColumn; ConstraintColumn;
		import mx.containers.utilityClasses.ConstraintRow; ConstraintRow;
		import mx.core.Container; Container;
		import mx.containers.ControlBar; ControlBar;
		import mx.validators.CreditCardValidator; CreditCardValidator;
		import mx.formatters.CurrencyFormatter; CurrencyFormatter;
		import mx.validators.CurrencyValidator; CurrencyValidator;
		import mx.controls.DataGrid; DataGrid;
		import mx.controls.dataGridClasses.DataGridColumn; DataGridColumn;
		import mx.controls.dataGridClasses.DataGridItemRenderer; DataGridItemRenderer;
		import mx.controls.DateChooser; DateChooser;
		import mx.controls.DateField; DateField;
		import mx.formatters.DateFormatter; DateFormatter;
		import mx.validators.DateValidator; DateValidator;
		import mx.effects.DefaultListEffect; DefaultListEffect;
		import mx.effects.DefaultTileListEffect; DefaultTileListEffect;
		import mx.effects.Dissolve; Dissolve;
		import mx.containers.DividedBox; DividedBox;
		import mx.effects.EffectTargetFilter; EffectTargetFilter;
		import mx.validators.EmailValidator; EmailValidator;
		import mx.effects.Fade; Fade;
		import mx.containers.Form; Form;
		import mx.containers.FormHeading; FormHeading;
		import mx.containers.FormItem; FormItem;
		import mx.effects.Glow; Glow;
		import mx.graphics.GradientEntry; GradientEntry;
		import mx.containers.Grid; Grid;
		import mx.containers.GridItem; GridItem;
		import mx.containers.GridRow ; GridRow;
		import mx.containers.HBox; HBox;
		import mx.containers.HDividedBox; HDividedBox;
		import mx.controls.HorizontalList; HorizontalList;
		import mx.controls.HRule; HRule;
		import mx.controls.HScrollBar; HScrollBar;
		import mx.controls.HSlider; HSlider;
		import mx.controls.Image; Image;
		import mx.effects.Iris; Iris;
		import mx.controls.Label; Label;
		import mx.graphics.LinearGradient; LinearGradient;
		import mx.graphics.LinearGradientStroke; LinearGradientStroke;
		import mx.controls.LinkBar; LinkBar;
		import mx.controls.LinkButton; LinkButton;
		import mx.controls.List; List;
		import mx.collections.ListCollectionView; ListCollectionView;
		import mx.effects.MaskEffect; MaskEffect;
		import mx.controls.MenuBar; MenuBar;
		import mx.logging.targets.MiniDebugTarget; MiniDebugTarget;
		import mx.modules.Module; Module;
		import mx.modules.ModuleLoader; ModuleLoader;
		import mx.effects.Move; Move;
		import mx.formatters.NumberFormatter; NumberFormatter;
		import mx.validators.NumberValidator; NumberValidator;
		import mx.controls.NumericStepper; NumericStepper;
		import mx.containers.Panel; Panel;
		import mx.effects.Parallel; Parallel;
		import mx.effects.Pause; Pause;
		import mx.formatters.PhoneFormatter; PhoneFormatter;
		import mx.validators.PhoneNumberValidator; PhoneNumberValidator;
		import mx.controls.PopUpButton; PopUpButton;
		import mx.controls.PopUpMenuButton; PopUpMenuButton;
		import mx.printing.PrintDataGrid; PrintDataGrid;
		import mx.controls.ProgressBar; ProgressBar;
		import mx.graphics.RadialGradient; RadialGradient;
		import mx.controls.RadioButton; RadioButton;
		import mx.controls.RadioButtonGroup; RadioButtonGroup;
		import mx.validators.RegExpValidator; RegExpValidator;
		import mx.states.RemoveChild; RemoveChild;
		import mx.effects.RemoveChildAction; RemoveChildAction;
		import mx.effects.RemoveItemAction; RemoveItemAction;
		import mx.core.Repeater; Repeater;
		import mx.effects.Resize; Resize;
		import mx.controls.RichTextEditor; RichTextEditor;
		import mx.effects.Rotate; Rotate;
		import mx.effects.Sequence; Sequence;
		import mx.states.SetEventHandler; SetEventHandler;
		import mx.states.SetProperty; SetProperty;
		import mx.effects.SetPropertyAction; SetPropertyAction;
		import mx.states.SetStyle; SetStyle;
		import mx.effects.SetStyleAction; SetStyleAction;
		import mx.validators.SocialSecurityValidator; SocialSecurityValidator;
		import mx.graphics.SolidColor; SolidColor;
		import mx.collections.Sort; Sort;
		import mx.collections.SortField; SortField;
		import mx.effects.SoundEffect; SoundEffect;
		import mx.controls.Spacer; Spacer;
		import mx.states.State; State;
		import mx.validators.StringValidator; StringValidator;
		import mx.graphics.Stroke; Stroke;
		import mx.controls.SWFLoader; SWFLoader;
		import mx.controls.TabBar; TabBar;
		import mx.containers.TabNavigator; TabNavigator;
		import mx.controls.Text; Text;
		import mx.controls.TextArea; TextArea;
		import mx.controls.TextInput; TextInput;
		import mx.containers.Tile; Tile;
		import mx.controls.TileList; TileList;
		import mx.containers.TitleWindow; TitleWindow;
		import mx.controls.ToggleButtonBar; ToggleButtonBar;
		import mx.controls.richTextEditorClasses.ToolBar; ToolBar;
		import mx.logging.targets.TraceTarget; TraceTarget;
		import mx.states.Transition; Transition;
		import mx.controls.Tree; Tree;
		import mx.core.UIComponent; UIComponent;
		import mx.effects.UnconstrainItemAction; UnconstrainItemAction;
		import mx.containers.VBox; VBox;
		import mx.containers.VDividedBox; VDividedBox;
		import mx.controls.VideoDisplay; VideoDisplay;
		import mx.containers.ViewStack; ViewStack;
		import mx.controls.VRule; VRule;
		import mx.controls.VScrollBar; VScrollBar;
		import mx.controls.VSlider; VSlider;
		import mx.validators.Validator; Validator;
		import mx.effects.WipeDown; WipeDown;
		import mx.effects.WipeLeft; WipeLeft;
		import mx.effects.WipeRight; WipeRight;
		import mx.effects.WipeUp; WipeUp;
		import mx.collections.XMLListCollection; XMLListCollection;
		import mx.formatters.ZipCodeFormatter; ZipCodeFormatter;
		import mx.validators.ZipCodeValidator; ZipCodeValidator;
		import mx.effects.Zoom; Zoom;
	}
}
