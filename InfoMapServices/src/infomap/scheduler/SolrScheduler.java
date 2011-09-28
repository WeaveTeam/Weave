package infomap.scheduler;

import javax.servlet.http.HttpServlet;

import org.quartz.DateBuilder.IntervalUnit;
import org.quartz.JobBuilder;
import org.quartz.JobDetail;
import org.quartz.JobKey;
import org.quartz.Scheduler;
import org.quartz.SchedulerException;
import org.quartz.SchedulerFactory;
import org.quartz.Trigger;
import org.quartz.TriggerBuilder;
import org.quartz.DateBuilder;

import static org.quartz.SimpleScheduleBuilder.*;
import org.quartz.impl.StdSchedulerFactory;

public final class SolrScheduler extends HttpServlet{
	
	private static final long serialVersionUID = 1L;
	
	private static SchedulerFactory _schedFactory = new StdSchedulerFactory();
	
	//the interval in minutes after which Solr will index the documents
	private static int interval = 60;
	public static void setInterval(int value)
	{
		interval = value;
		try{
			stop();
			start();
		}catch (SchedulerException e)
		{
			e.printStackTrace();
		}
	}
	public int getInterval()
	{
		return interval;
	}
	
	public void init() 
	{
			setInterval(60);
	}
	
	//TODO: test start function
	public static void start() throws SchedulerException{
		try{
			
			System.out.println("Setting up Scheduler...");
			
			
			Scheduler sched = _schedFactory.getScheduler();
			
			JobDetail job = JobBuilder.newJob(SolrIndexingJob.class).withIdentity("jobForIndexing","solr").build();
			
			Trigger trigger = TriggerBuilder.newTrigger()
							.withIdentity("triggerForIndexing","solr")
							.startAt(DateBuilder.futureDate(5, IntervalUnit.MINUTE))
							.withSchedule(repeatMinutelyForever(interval))
							.build();
			
			sched.scheduleJob(job, trigger);
			sched.start();
			System.out.println("Scheduler is now running...");
			
		}catch (SchedulerException e){
				e.printStackTrace();
			}
	}
	
	//TODO: test stop function
	public static void stop() throws SchedulerException{
		try{
		Scheduler sched = _schedFactory.getScheduler();
		JobKey jKey = new JobKey("jobForIndexing","solr");
		sched.deleteJob(jKey);
		sched.shutdown(true);
		}catch (SchedulerException e){
			e.printStackTrace();
		}
	}
	
	
}
