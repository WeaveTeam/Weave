package infomap.beans;

public class EntityDistributionObject {
	
	public String[] entities;
	public Object[][] urls;
	
	public EntityDistributionObject(){}
	
	public EntityDistributionObject(String[] entities, Object[][] urls)
	{
		this.entities = entities;
		this.urls = urls;
	}

}
