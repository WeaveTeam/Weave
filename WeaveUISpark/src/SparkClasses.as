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
	 * This class references all classes under packages starting with spark.* in the Flex framework manifest.xml.
	 * Referencing this class in an MXML Application forces the compiler to generate actionscript code that
	 * includes all the 'mixins' required to be able to dynamically create these classes at runtime.
	 * 
	 * @author adufilie
	 */
	public class SparkClasses
	{
		AddAction; import spark.effects.AddAction;
		Animate; import spark.effects.Animate;
		AnimateColor; import spark.effects.AnimateColor;
		AnimateFilter; import spark.effects.AnimateFilter;
		AnimateTransitionShader; import spark.effects.AnimateTransitionShader;
		AnimateTransform; import spark.effects.AnimateTransform;
		AnimateTransform3D; import spark.effects.AnimateTransform3D;
		Animation; import spark.effects.animation.Animation;
		Application; import spark.components.Application;
		ArrayCollection; import mx.collections.ArrayCollection;
		ArrayList; import mx.collections.ArrayList;
		AsyncListView; import mx.collections.AsyncListView;
		BasicLayout; import spark.layouts.BasicLayout;
		BevelFilter; import spark.filters.BevelFilter;
		BitmapImage; import spark.primitives.BitmapImage;
		Block; import spark.layouts.supportClasses.Block;
		BlurFilter; import spark.filters.BlurFilter;
		BorderContainer; import spark.components.BorderContainer;
		Bounce; import spark.effects.easing.Bounce;
		Button; import spark.components.Button;
		ButtonBar; import spark.components.ButtonBar;
		ButtonBarButton; import spark.components.ButtonBarButton;
		ButtonBarHorizontalLayout; import spark.components.supportClasses.ButtonBarHorizontalLayout;
		ButtonBase; import spark.components.supportClasses.ButtonBase;
		CallAction; import spark.effects.CallAction;
		CellPosition; import spark.components.gridClasses.CellPosition;
		CellRegion; import spark.components.gridClasses.CellRegion;
		CheckBox; import spark.components.CheckBox;
		ColorMatrixFilter; import spark.filters.ColorMatrixFilter;
		ColorTransform; import flash.geom.ColorTransform;
		ColumnAlign; import spark.layouts.ColumnAlign;
		GridColumnHeaderGroup; import spark.components.GridColumnHeaderGroup;
		ComboBox; import spark.components.ComboBox;
		ComboBoxGridItemEditor; import spark.components.gridClasses.ComboBoxGridItemEditor;
		ConstraintColumn; import mx.containers.utilityClasses.ConstraintColumn;
		ConstraintLayout; import spark.layouts.ConstraintLayout;
		ConstraintRow; import mx.containers.utilityClasses.ConstraintRow;
		ContentCache; import spark.core.ContentCache; 
		ConvolutionFilter; import spark.filters.ConvolutionFilter;
		CrossFade; import spark.effects.CrossFade;
		CurrencyFormatter; import spark.formatters.CurrencyFormatter;
		CurrencyValidator; import spark.validators.CurrencyValidator;
		DataGrid; import spark.components.DataGrid;    
		DataGroup; import spark.components.DataGroup;
		DataRenderer; import spark.components.DataRenderer;
		DateTimeFormatter; import spark.formatters.DateTimeFormatter;
		DefaultGridHeaderRenderer; import spark.skins.spark.DefaultGridHeaderRenderer;
		DefaultGridItemRenderer; import spark.skins.spark.DefaultGridItemRenderer;
		DisplacementMapFilter; import spark.filters.DisplacementMapFilter;
		DropDownList; import spark.components.DropDownList;
		DropLocation; import spark.layouts.supportClasses.DropLocation;
		DropShadowFilter; import spark.filters.DropShadowFilter;
		DynamicStreamingVideoSource; import spark.components.mediaClasses.DynamicStreamingVideoSource;
		DynamicStreamingVideoItem; import spark.components.mediaClasses.DynamicStreamingVideoItem;
		Elastic; import spark.effects.easing.Elastic;
		Ellipse; import spark.primitives.Ellipse;
		Fade; import spark.effects.Fade;
		Form; import spark.components.Form;
		FormHeading; import spark.components.FormHeading;
		FormItem; import spark.components.FormItem;
		FormItemLayout; import spark.layouts.FormItemLayout;
		FormLayout; import spark.layouts.FormLayout;
		FilledElement; import spark.primitives.supportClasses.FilledElement;
		GlowFilter; import spark.filters.GlowFilter;
		GradientBevelFilter; import spark.filters.GradientBevelFilter;
		GradientFilter; import spark.filters.GradientFilter;
		GradientGlowFilter; import spark.filters.GradientGlowFilter;
		Graphic; import spark.primitives.Graphic;
		GraphicElement; import spark.primitives.supportClasses.GraphicElement;
		Grid; import spark.components.Grid;
		GridColumn; import spark.components.gridClasses.GridColumn;
		GridItemEditor; import spark.components.gridClasses.GridItemEditor;
		GridItemRenderer; import spark.components.gridClasses.GridItemRenderer;
		GridLayer; import spark.components.gridClasses.GridLayer;
		Group; import spark.components.Group;
		GroupBase; import spark.components.supportClasses.GroupBase;
		HGroup; import spark.components.HGroup;
		HorizontalLayout; import spark.layouts.HorizontalLayout;
		HSBInterpolator; import spark.effects.interpolation.HSBInterpolator;
		HScrollBar; import spark.components.HScrollBar;
		HSlider; import spark.components.HSlider;
		Image; import spark.components.Image; 
		ItemRenderer; import spark.components.supportClasses.ItemRenderer;
		Keyframe; import spark.effects.animation.Keyframe;
		Label; import spark.components.Label;
		LastOperationStatus; import spark.globalization.LastOperationStatus;
		LayoutBase; import spark.layouts.supportClasses.LayoutBase;
		Line; import spark.primitives.Line;
		Linear; import spark.effects.easing.Linear;
		List; import spark.components.List;
		ListBase; import spark.components.supportClasses.ListBase;
		MaskType; import spark.core.MaskType;
		MatchingCollator; import spark.globalization.MatchingCollator;
		Matrix; import flash.geom.Matrix;
		Matrix3D; import flash.geom.Matrix3D;
		Module; import spark.modules.Module;
		ModuleLoader; import spark.modules.ModuleLoader;
		MotionPath; import spark.effects.animation.MotionPath;
		Move; import spark.effects.Move;
		MovieClipSWFLoader; import mx.controls.MovieClipSWFLoader;
		Move3D; import spark.effects.Move3D;
		MultiDPIBitmapSource; import spark.utils.MultiDPIBitmapSource;
		MultiValueInterpolator; import spark.effects.interpolation.MultiValueInterpolator;
		MuteButton; import spark.components.mediaClasses.MuteButton;
		NavigatorContent; import spark.components.NavigatorContent;
		NumberFormatter; import spark.formatters.NumberFormatter;
		NumberInterpolator; import spark.effects.interpolation.NumberInterpolator;
		NumberValidator; import spark.validators.NumberValidator;
		NumericStepper; import spark.components.NumericStepper;
		Panel; import spark.components.Panel;
		Path; import spark.primitives.Path;
		PopUpAnchor; import spark.components.PopUpAnchor;
		PopUpPosition; import spark.components.PopUpPosition;
		Power; import spark.effects.easing.Power;
		RadioButton; import spark.components.RadioButton;
		RadioButtonGroup; import spark.components.RadioButtonGroup;
		Range; import spark.components.supportClasses.Range;
		Rect; import spark.primitives.Rect;
		RectangularDropShadow; import spark.primitives.RectangularDropShadow;
		RemoveAction; import spark.effects.RemoveAction;
		Resize; import spark.effects.Resize;
		RGBInterpolator; import spark.effects.interpolation.RGBInterpolator;
		RichEditableText; import spark.components.RichEditableText;
		RichText; import spark.components.RichText;
		Rotate; import spark.effects.Rotate;
		Rotate3D; import spark.effects.Rotate3D;
		RowAlign; import spark.layouts.RowAlign;
		Scale; import spark.effects.Scale;
		Scale3D; import spark.effects.Scale3D;
		ScrollBarBase; import spark.components.supportClasses.ScrollBarBase;
		Scroller; import spark.components.Scroller;
		ScrollerLayout; import spark.components.supportClasses.ScrollerLayout;
		ScrubBar; import spark.components.mediaClasses.ScrubBar;
		SetAction; import spark.effects.SetAction;
		ShaderFilter; import spark.filters.ShaderFilter;
		SimpleMotionPath; import spark.effects.animation.SimpleMotionPath;
		Sine; import spark.effects.easing.Sine;
		Skin; import spark.components.supportClasses.Skin;
		SkinnableComponent; import spark.components.supportClasses.SkinnableComponent;
		SkinnableContainer; import spark.components.SkinnableContainer;
		SkinnableContainerBase; import spark.components.supportClasses.SkinnableContainerBase;
		SkinnableDataContainer; import spark.components.SkinnableDataContainer;
		SkinnablePopUpContainer; import spark.components.SkinnablePopUpContainer;
		SkinnableTextBase; import spark.components.supportClasses.SkinnableTextBase;
		SliderBase; import spark.components.supportClasses.SliderBase;
		Sort; import spark.collections.Sort;
		SortField; import spark.collections.SortField;
		SortingCollator; import spark.globalization.SortingCollator;
		Spacer; import mx.controls.Spacer;
		SparkButtonSkin; import spark.skins.SparkButtonSkin;
		SparkSkin; import spark.skins.SparkSkin;
		Spinner; import spark.components.Spinner;
		SpriteVisualElement; import spark.core.SpriteVisualElement;
		StringTools; import spark.globalization.StringTools;
		StrokedElement; import spark.primitives.supportClasses.StrokedElement;
		SWFLoader; import mx.controls.SWFLoader;
		//TabBar; import spark.components.TabBar;
		TextArea; import spark.components.TextArea;
		DefaultGridItemEditor; import spark.components.gridClasses.DefaultGridItemEditor;
		TextBase; import spark.components.supportClasses.TextBase;
		TextInput; import spark.components.TextInput;
		TextSelectionHighlighting; import spark.components.TextSelectionHighlighting;
		TextUtil; import spark.utils.TextUtil;
		TileGroup; import spark.components.TileGroup;
		TileLayout; import spark.layouts.TileLayout;
		TileOrientation; import spark.layouts.TileOrientation;
		TitleWindow; import spark.components.TitleWindow;
		ToggleButton; import spark.components.ToggleButton;
		ToggleButtonBase; import spark.components.supportClasses.ToggleButtonBase;
		TrackBase; import spark.components.supportClasses.TrackBase;
		Transform; import mx.geom.Transform;
		TransformOffsets; import mx.geom.TransformOffsets;
		UITextFieldGridItemRenderer; import spark.skins.spark.UITextFieldGridItemRenderer;
		VerticalAlign; import spark.layouts.VerticalAlign;
		VerticalLayout; import spark.layouts.VerticalLayout;
		VGroup; import spark.components.VGroup;
		VideoDisplay; import spark.components.VideoDisplay;
		VideoPlayer; import spark.components.VideoPlayer;
		VolumeBar; import spark.components.mediaClasses.VolumeBar;
		VScrollBar; import spark.components.VScrollBar;
		VSlider; import spark.components.VSlider;
		Wipe; import spark.effects.Wipe;
		XMLListCollection; import mx.collections.XMLListCollection;
	}
}
