using System;
using System.Collections.Concurrent;

public sealed class CodeProfiler : IDisposable
{
    private static ConcurrentBag<CodeProfiler> s_Pool = new ConcurrentBag<CodeProfiler>();
    private string  StepName { get; set; }
    private decimal MaxExecutionSeconds { get; set; }
    private long StartTicks { get; set; }

    private CodeProfiler()
    {
    }

    public static CodeProfiler Step(decimal maxExecutionSeconds, string stepName)
    {
        CodeProfiler profiler;
        if (!s_Pool.TryTake(out profiler))
            profiler = new CodeProfiler();

        profiler.StartTicks = DateTime.Now.Ticks;
        profiler.MaxExecutionSeconds = maxExecutionSeconds;
        profiler.StepName = stepName;

        return profiler;
    }



    public void Dispose()
    {
        decimal totalElapsedSeconds = (DateTime.Now.Ticks - StartTicks) / 10000000.00M;
        if (totalElapsedSeconds > this.MaxExecutionSeconds)
            Logger.CodeProfiler("Diagnose", "{0} {1:f2}s;", this.StepName, totalElapsedSeconds);
        s_Pool.Add(this);
    }

}
