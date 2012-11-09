package weave.utils;
import java.lang.System;
import java.io.PrintStream;
public class ProgressManager
{
    private int total_items;
    private int current_items;
    private PrintStream output;
    private long rate_est = 0;
    private long last_tick;
    private int cycle;
    public ProgressManager(int total_items, PrintStream output, int cycle)
    {
        this.total_items = total_items;
        this.output = output;
        this.cycle = cycle;
        last_tick = System.nanoTime();
    }
    public void advance(int items)
    {
        long new_tick, tick_diff, tick_rate;
        long time_rem;
        new_tick = System.nanoTime();
        tick_diff = (new_tick - last_tick);
        last_tick = new_tick;
        current_items += items;
        tick_rate = tick_diff / items;
        if (tick_rate > rate_est) rate_est = tick_rate;
        if (rate_est == 0) 
        {
            time_rem = 0;
        }
        else 
        {
            time_rem = (total_items - current_items) * rate_est;
        }
        time_rem /= 1000000000; 
        if (current_items % cycle == 0)
            output.printf("%d/%d %d\n", current_items, total_items, time_rem);
    }
}
