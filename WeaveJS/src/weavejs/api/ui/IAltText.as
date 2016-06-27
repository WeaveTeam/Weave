package weavejs.api.ui
{
import weavejs.core.LinkableBoolean;
import weavejs.core.LinkableString;

	public interface IAltText
	{
		function get altText():LinkableString;
		function get altTextMode():LinkableString;
		function get showCaption():LinkableBoolean;
		function updateAltText():void;
	}
}
