package infomap.scheduler;

import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;

import org.quartz.DateBuilder.IntervalUnit;
import org.quartz.JobBuilder;
import org.quartz.JobDetail;
import org.quartz.JobExecutionContext;
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
	
	
	private static String jobNameForIndexing = "INDEXING_JOB";
	
	private static String jobNameForThumbnaiil = "THUMBNAIL_JOB";
	
	private static String jobNameForSummarization = "SUMMARIZATION_JOB";
	
	private static String jobGroupName = "SOLR";
	
//	//the interval in minutes after which Solr will index the documents
//	private static int interval = 60;
//	public static void setInterval(int value)
//	{
//		interval = value;
//		try{
//			stop();
//			start();
//		}catch (SchedulerException e)
//		{
//			e.printStackTrace();
//		}
//	}
//	public int getInterval()
//	{
//		return interval;
//	}
//	
//	public void init() 
//	{
//			setInterval(60);
//	}
	
	private Future<Boolean> schedFuture;
	
	@Override
	public void init() throws ServletException {
		// TODO Auto-generated method stub
		super.init();

		schedThread = new SchedulerThread();
		
		ExecutorService executor = Executors.newFixedThreadPool(2);
		
		schedFuture =  executor.submit(schedThread);
	}
	
	
	
	@Override
	public void destroy() {
		System.out.println("CALLING DESTROY");
		schedThread.stopJobs();
		if(schedFuture != null)
			{
				Boolean haltScheduler = schedFuture.cancel(true);
				System.out.println("SHUTTING DOWN SCHEDULING SERVICE: " + haltScheduler);
			}
		executor.shutdownNow();
		super.destroy();
	}
	private static SchedulerThread schedThread;
	private static ExecutorService executor;
	
	public class SchedulerThread implements Callable<Boolean>
	{
		private SchedulerFactory _schedFactory = new StdSchedulerFactory();
		private Scheduler sched; 
		
		private int interval = 60;
		
		Boolean keepRunning = true;
		
		

		public Boolean call() 
		{
			System.out.println("RUNNING SOLRSCHEDULER THREAD WITH NAME " + Thread.currentThread().getName());
			// TODO Auto-generated method stub
			System.out.println("Setting up Scheduler...");
			System.out.println("RUNNING WITH MEMORY SIZE" + Runtime.getRuntime().maxMemory());
			try{
			
				sched = _schedFactory.getScheduler();
				
				JobDetail indexingJob = JobBuilder.newJob(SolrIndexingJob.class).withIdentity(jobNameForIndexing,jobGroupName).build();
				
				Trigger triggerIndexingJob = TriggerBuilder.newTrigger()
								.withIdentity("triggerForIndexing","solr")
								.startAt(DateBuilder.futureDate(5, IntervalUnit.MINUTE))
								.withSchedule(repeatMinutelyForever(interval))
								.build();
				
				
				sched.scheduleJob(indexingJob, triggerIndexingJob);
				sched.start();
				
				JobKey thumbnailJobKey = JobKey.jobKey(jobNameForThumbnaiil,jobGroupName);
				JobDetail thumbnailJob = JobBuilder.newJob(GenerateThumbnailJob.class).withIdentity(thumbnailJobKey)
										.storeDurably()
										.build();
				sched.addJob(thumbnailJob,true);
				sched.triggerJob(thumbnailJobKey);
				
				JobKey summarizationJobKey = JobKey.jobKey(jobNameForSummarization,jobGroupName);
				JobDetail summarizationJob = JobBuilder.newJob(SummarizationJob.class).withIdentity(summarizationJobKey)
													.storeDurably()
													.build();
				sched.addJob(summarizationJob,true);
				sched.triggerJob(summarizationJobKey);
				//Sleep for a minute before going into while loop
				waitForMinutes(1, "first trigger of jobs");
				while(keepRunning)
				{
					
					List<JobExecutionContext> currentJobs = sched.getCurrentlyExecutingJobs();
					
					Boolean thumbnailJobfound = false;
					Boolean summarizationJobfound = false;
					for (JobExecutionContext jext: currentJobs)
					{
						String jName = jext.getJobDetail().getKey().getName();
						if(jName.equals(jobNameForThumbnaiil))
							thumbnailJobfound=true;
						if(jName.equals(jobNameForSummarization))
							summarizationJobfound = true;
					}
					
					if (thumbnailJobfound && summarizationJobfound)
					{
						waitForMinutes(3, "jobs running check");
	
					}else
					{
						try{
							if(!thumbnailJobfound)
							{
								sched.triggerJob(thumbnailJobKey);
								System.out.println("Triggering Thumbnail Job");
							}
	
							if(!summarizationJobfound)
							{
								sched.triggerJob(summarizationJobKey);
								System.out.println("Triggering Summarization Job");
							}
						}catch (Exception e) {
							// TODO: handle exception
							System.out.println("Jobs found but could not be triggered. Possibly shut down.");
						}
						
						waitForMinutes(1, "jobs re-triggered");
					}
					
				}
				
			}catch (SchedulerException e)
			{
				System.out.println("Error Scheduling jobs");
					e.printStackTrace();
			}
			
			return keepRunning;
		}
		
		public void stopJobs()
		{
			System.out.println("CALLING STOPJOBS");
			try{
				if(sched ==null)
					sched = _schedFactory.getScheduler();
				JobKey jKey = new JobKey(jobNameForIndexing,jobGroupName);
				JobKey tKey = new JobKey(jobNameForThumbnaiil,jobGroupName);
				JobKey sKey = new JobKey(jobNameForSummarization,jobGroupName);
				Boolean stopJobResult = sched.deleteJob(jKey);
				stopJobResult =	sched.deleteJob(tKey);
				stopJobResult = sched.deleteJob(sKey);
				System.out.println("RESULT OF STOPPING JOBS " + stopJobResult);
				sched.pauseAll();
				sched.clear();
				keepRunning = false;
//				sched.shutdown(false);
				waitForMinutes(1, "stopJobs");
				System.out.println("Shutting Down All jobs");
				}catch (SchedulerException e){
					e.printStackTrace();
				}
			return;
		}
		
		private void waitForMinutes(int i,String processName)
		{
			try {
				System.out.println("going to sleep for " + processName);
			    Thread.sleep(1000*60*i);
			} catch(InterruptedException ex) {
			    Thread.currentThread().interrupt();
			}
		}
	}
}
