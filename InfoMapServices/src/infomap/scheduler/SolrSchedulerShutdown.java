package infomap.scheduler;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

public class SolrSchedulerShutdown implements ServletContextListener{

	@Override
	public void contextDestroyed(ServletContextEvent arg0) {
		// TODO Auto-generated method stub
//		System.out.println("Shutting Down Scheduler");
		try{
//		SolrScheduler.stop();
		}catch(Exception e){
			e.printStackTrace();
		}
	}

	@Override
	public void contextInitialized(ServletContextEvent arg0) {
		// TODO Auto-generated method stub
		
		System.out.println("Scheduler Initialized!");
	}

}
