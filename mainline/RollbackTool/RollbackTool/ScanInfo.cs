using System.Collections.Generic;

namespace RollbackTool
{
    public class ScanInfo
    {
        public string[] DirectoriesToDelete { get; set; }
        public string[] DirectoriesToCopy { get; set; }
        public string[] FilesToDelete { get; set; }
        public double SizeFilesToDelete { get; set; }
        public string[] FilesToCopy { get; set; }
        public double SizeFilesToCopy { get; set; }
        public List<string> Errors { get; set; }
    }
}
