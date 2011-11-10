package weave.ui.filterComponents
{
	import mx.core.IUIComponent;
	
	import weave.api.core.ILinkableObject;
	import weave.ui.CustomDataGrid.WeaveCustomDataGridColumn;

	public interface IFilterComponent extends IUIComponent, ILinkableObject
	{
		function mapColumnToFilter(column:WeaveCustomDataGridColumn):void;
		function get isActive():Boolean;	
		function filterFunction(obj:Object):Boolean;
	}
}