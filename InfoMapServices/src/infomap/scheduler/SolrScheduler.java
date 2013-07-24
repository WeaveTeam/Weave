package infomap.scheduler;

import java.io.InputStream;
import java.util.List;
import java.util.Properties;
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
import static org.quartz.TriggerBuilder.*;
import org.quartz.impl.StdSchedulerFactory;

public final class SolrScheduler extends HttpServlet{
	
	private static final long serialVersionUID = 1L;
		
	private static String jobNameForIndexing = "INDEXING_JOB";
	
	private static String jobNameForThumbnaiil = "THUMBNAIL_JOB";
	
	private static String jobNameForSummarization = "SUMMARIZATION_JOB";
	
	private static String jobNameForRssFeeds = "RSSFEEDS_JOB";
	
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
		super.init();
		
		schedThread = new SchedulerThread();
		
		executor = Executors.newFixedThreadPool(2); // ToDo why set to 2?
		
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
			System.out.println("Setting up Scheduler...");
			System.out.println("RUNNING WITH MEMORY SIZE " + Runtime.getRuntime().maxMemory());
			
			Properties prop = new Properties();
			try{
				InputStream config = getClass().getClassLoader().getResourceAsStream("infomap/resources/config.properties");
				prop.load(config);
			}catch (Exception e)
			{
				System.out.println("Error reading configuration file");
				return false;
			}
			
			try{
			
				sched = _schedFactory.getScheduler();
				
//				JobDetail indexingJob = JobBuilder.newJob(SolrIndexingJob.class).withIdentity(jobNameForIndexing,jobGroupName).build();
//				
//				Trigger triggerIndexingJob = TriggerBuilder.newTrigger()
//								.withIdentity("triggerForIndexing","solr")
//								.startAt(DateBuilder.futureDate(5, IntervalUnit.MINUTE))
//								.withSchedule(repeatMinutelyForever(interval))
//								.build();
//				
//				
//				sched.scheduleJob(indexingJob, triggerIndexingJob);
//				sched.start();
				
				String enableThumbnail = prop.getProperty("enableThumbnailing");
				
				JobKey thumbnailJobKey = JobKey.jobKey(jobNameForThumbnaiil,jobGroupName);
				if(enableThumbnail.equalsIgnoreCase("true"))
				{
					JobDetail thumbnailJob = JobBuilder.newJob(GenerateThumbnailJob.class).withIdentity(thumbnailJobKey)
					.storeDurably()
					.build();
					sched.addJob(thumbnailJob,true);
					sched.triggerJob(thumbnailJobKey);
				}
				
				
				String enableSummarization = prop.getProperty("enableSummarization");
				JobKey summarizationJobKey = JobKey.jobKey(jobNameForSummarization,jobGroupName);
				if(enableSummarization.equalsIgnoreCase("true"))
				{
					JobDetail summarizationJob = JobBuilder.newJob(SummarizationJob.class).withIdentity(summarizationJobKey)
														.storeDurably()
														.build();
					sched.addJob(summarizationJob,true);
					sched.triggerJob(summarizationJobKey);
				}
				
				if(enableThumbnail.equalsIgnoreCase("false") &&  enableSummarization.equalsIgnoreCase("false"))
				{
					keepRunning = false;
				}
				
				// Index RSS Feeds Job
				String enableRssFeeds = prop.getProperty("enableRssFeeds");
				int feedSourcesUpdateIntervalMins = Integer.parseInt(prop.getProperty("feedSourcesUpdateIntervalMins"));
				JobKey rssFeedsJobKey = JobKey.jobKey(jobNameForRssFeeds, jobGroupName);
				if(enableRssFeeds.equalsIgnoreCase("true"))
				{
					JobDetail rssFeedsJob = JobBuilder.newJob(RssFeedsJob.class).withIdentity(rssFeedsJobKey)
														.storeDurably()
														.build();
					
					// Trigger the job to run now, and then repeat every 60 mins
					Trigger trigger = newTrigger()
					.withIdentity("rssFeedsTrigger", jobGroupName)
					.startNow()
					.withSchedule(simpleSchedule()
							.withIntervalInMinutes(feedSourcesUpdateIntervalMins)
							.repeatForever())            
							.build();
					
					sched.start();
					sched.scheduleJob(rssFeedsJob, trigger);
				}
				
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
							if(!thumbnailJobfound && enableThumbnail.equalsIgnoreCase("true"))
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
							System.out.println("Jobs found but could not be triggered. Possibly shut down.");
						}
						
						waitForMinutes(1, "jobs re-triggered");
					}
					
				}
				
			} catch (InterruptedException ex) {
				return false;
			}
			catch (SchedulerException e) {
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
				try {
					// Wait 1 min for stopping and finish jobs and one 1 for shutting down scheduler
					waitForMinutes(1, "Stop Jobs");
					sched.shutdown(false);
					waitForMinutes(1, "Shut Down Scheduler");
				} catch (InterruptedException e) {
					e.printStackTrace();
					return;
				}
				System.out.println("Shutting Down All jobs");
				}catch (SchedulerException e){
					e.printStackTrace();
				}
			return;
		}
		
		private void waitForMinutes(int i,String processName) throws InterruptedException
		{
				System.out.println("going to sleep for " + processName);
			    Thread.sleep(1000*60*i);
		}
	}
}
