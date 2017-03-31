using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.IO;
using System.Linq;
using System.Windows.Forms;

namespace RollbackTool
{
    public partial class MainWindow : Form
    {
        private DateTime _metricsStart = DateTime.Now;
        private ScanInfo _scanInfo = new ScanInfo();

        BackgroundWorker bw = new BackgroundWorker();
        BackgroundWorker bwIO = new BackgroundWorker();
        private const string SCAN = "Scan";
        private const string SYNC = "Sync";
        private const string CANCEL = "Cancel";

        private const string TOTAL_OPERATIONS = "Total Operations: ";
        private const string FILES_TO_DELETE_SIZE = "Files To Delete Size: ";
        private const string FILES_TO_COPY_SIZE = "Files To Copy Size: ";
        private const string TIME_DIRECTORY_SCAN = "Directory Scan Time: ";
        private const string TIME_SYNC = "Sync Time: ";

        public MainWindow()
        {
            InitializeComponent();

            btnScan.Text = SCAN;
            btnSync.Text = SYNC;
            btnSync.Enabled = false;

            bw.WorkerSupportsCancellation = true;
            bw.DoWork += DoTheScan;
            bw.RunWorkerCompleted += bw_RunWorkerCompleted;

            bwIO.WorkerSupportsCancellation = true;
            bwIO.WorkerReportsProgress = true;
            bwIO.DoWork += DoTheSync;
            bwIO.ProgressChanged += bw_ProgressChanged;
            bwIO.RunWorkerCompleted += bw_RunWorkerCompleted;
        }

        private void bw_ProgressChanged(object sender, ProgressChangedEventArgs e)
        {
            var filesProcessed = (int)e.UserState;
            pbProgress.Value = e.ProgressPercentage;
            lblOperations.Text = TOTAL_OPERATIONS + filesProcessed;
        }

        private void bw_RunWorkerCompleted(object sender, RunWorkerCompletedEventArgs e)
        {
            var metricsEnd = DateTime.Now.Subtract(_metricsStart);

            btnSync.Text = SYNC;
            btnScan.Text = SCAN;
            pnlPaths.Enabled = true;
            btnSync.Enabled = true;
            btnScan.Enabled = true;
            pbProgress.Value = 0;
            pbProgress.Style = ProgressBarStyle.Blocks;

            if ((e.Cancelled))
            {
                btnSync.Enabled = false;
            }
            else if (!(e.Error == null))
                {
                    btnSync.Enabled = false;
                }
                else
                {
                    ScanInfo result = e.Result as ScanInfo;
                    if (result != null)
                    {
                        _scanInfo = result;
                        lblTotalTime.Text = TIME_DIRECTORY_SCAN + metricsEnd.TotalSeconds;
                        lblOperations.Text = TOTAL_OPERATIONS + (_scanInfo.FilesToCopy.Length + _scanInfo.FilesToDelete.Length + _scanInfo.DirectoriesToDelete.Length);
                        lblFilesToCopySize.Text = string.Format(FILES_TO_COPY_SIZE + "{0:#,0.###} Mb", _scanInfo.SizeFilesToCopy / 1024 / 1024);
                        lblFilesToDeleteSize.Text = string.Format(FILES_TO_DELETE_SIZE + "{0:#,0.###} Mb", _scanInfo.SizeFilesToDelete / 1024 / 1024);

                        gvDifferences.DataSource = _scanInfo.FilesToCopy.Take(1000).Select((x, i) => new RollbackItem
                        {
                            Index = i + 1,
                            Name = x
                        }).ToArray();
                    }
                    else
                    {
                        lblTotalTime.Text = TIME_SYNC + metricsEnd.TotalSeconds;
                    }
                }
        }

        private void btnScan_Click(object sender, EventArgs e)
        {
            if (bw.IsBusy)
            {
                bw.CancelAsync();
            }
            else
            {
                pbProgress.Style = ProgressBarStyle.Marquee;
                pnlPaths.Enabled = false;
                btnSync.Enabled = false;
                btnScan.Text = CANCEL;
                _metricsStart = DateTime.Now;
                bw.RunWorkerAsync();
            }
        }
        private void btnSync_Click(object sender, EventArgs e)
        {
            if (bwIO.IsBusy)
            {
                bwIO.CancelAsync();
            }
            else
            {
                pnlPaths.Enabled = false;
                btnScan.Enabled = false;
                btnSync.Text = CANCEL;
                _metricsStart = DateTime.Now;
                bwIO.RunWorkerAsync();
            }
        }

        private void btnFolderDialog_Click(object sender, EventArgs e)
        {
            bool isSourcePath = (sender as Button).Name.Contains("Source");
            FolderBrowserDialog dialog = new FolderBrowserDialog();
            if (isSourcePath)
            {
                dialog.SelectedPath = txtFrom.Text;
            }
            else
            {
                dialog.SelectedPath = txtTo.Text;
            }

            DialogResult result = dialog.ShowDialog();
            if (result == DialogResult.OK)
            {
                if (isSourcePath)
                {
                    txtFrom.Text = dialog.SelectedPath + "\\";
                }
                else
                {
                    txtTo.Text = dialog.SelectedPath + "\\";
                }
            }
        }


        private void DoTheScan(object sender, DoWorkEventArgs e)
        {
            var worker = sender as BackgroundWorker;
            var result = new ScanInfo();

            string folderFrom = txtFrom.Text;
            string folderTo = txtTo.Text;
            
            //Directory Compare
            string[] fromDirectories = Directory.GetDirectories(folderFrom, "*", SearchOption.AllDirectories);
            string[] fromDirectoriesRelative = fromDirectories.Select(f => f.Replace(folderFrom, "")).ToArray();

            string[] toDirectories = Directory.GetDirectories(folderTo, "*", SearchOption.AllDirectories);
            string[] toDirectoriesRelative = toDirectories.Select(f => f.Replace(folderTo, "")).ToArray();

            string[] destinationDirectoriesToRemove = toDirectoriesRelative.Except(fromDirectoriesRelative).ToArray();
            string[] sourceDirectoriesToCreate = fromDirectoriesRelative.Except(toDirectoriesRelative).ToArray();

            if (worker.CancellationPending)
            {
                e.Cancel = true;
                return;
            }
            //Files Compare
            string[] fromFiles = Directory.GetFiles(folderFrom, "*", SearchOption.AllDirectories);
            string[] fromFilesRelative = fromFiles.Select(f => f.Replace(folderFrom, "")).ToArray();

            string[] toFiles = Directory.GetFiles(folderTo, "*", SearchOption.AllDirectories);
            string[] toFilesRelative = toFiles.Select(f => f.Replace(folderTo, "")).ToArray();

            string[] destinationFilesToRemove = toFilesRelative.Except(fromFilesRelative).ToArray();
            
            //Deep FileScan
            foreach (var filepath in destinationFilesToRemove)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }

                FileInfo toInfo = new FileInfo(folderTo + filepath);
                result.SizeFilesToDelete += toInfo.Length;
            }

            var filesToCopyList = new List<string>();
            foreach (var filepath in fromFilesRelative)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }

                FileInfo fromInfo = new FileInfo(folderFrom + filepath);
                FileInfo toInfo = new FileInfo(folderTo + filepath);
                if (!toInfo.Exists)
                {
                    filesToCopyList.Add(filepath);
                    result.SizeFilesToCopy += fromInfo.Length;
                }
                else
                {
                    if (fromInfo.Length != toInfo.Length || DateTime.Compare(fromInfo.LastWriteTime, toInfo.LastWriteTime) != 0)
                    {
                        filesToCopyList.Add(filepath);
                        result.SizeFilesToCopy += fromInfo.Length;
                    }
                }
            }

            result.DirectoriesToDelete = destinationDirectoriesToRemove;
            result.DirectoriesToCopy = sourceDirectoriesToCreate;
            result.FilesToDelete = destinationFilesToRemove;
            result.FilesToCopy = filesToCopyList.ToArray();
            e.Result = result;
        }

        private void DoTheSync(object sender, DoWorkEventArgs e)
        {
            var worker = sender as BackgroundWorker;
 
            string folderFrom = txtFrom.Text;
            string folderTo = txtTo.Text;

            var operations = 0;
            var filesProcessed = 0;
            var filesTotal = _scanInfo.DirectoriesToDelete.Length + _scanInfo.DirectoriesToCopy.Length + _scanInfo.FilesToDelete.Length + _scanInfo.FilesToCopy.Length;
            var onePercent = filesTotal / 100;

            foreach (var filepath in _scanInfo.FilesToDelete)
            {
                #region ReportProgress
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                if (filesProcessed % onePercent == 0)
                    worker.ReportProgress((int)(100L * filesProcessed / filesTotal), filesProcessed);
                #endregion

                FileInfo toInfo = new FileInfo(folderTo + filepath);
                toInfo.Delete();
                
                filesProcessed++;
            }

            foreach (var dirpath in _scanInfo.DirectoriesToDelete)
            {
                #region ReportProgress
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                if (filesProcessed % onePercent == 0)
                    worker.ReportProgress((int)(100L * filesProcessed / filesTotal), filesProcessed);
                #endregion

                DirectoryInfo toInfo = new DirectoryInfo(folderTo + dirpath);
                try
                {
                    toInfo.Delete(true);
                    operations++;
                }
                catch (UnauthorizedAccessException ex)
                {
                    var str = ex.Message;
                    throw;
                }
                catch (Exception ex) { }

                filesProcessed++;
            }

            foreach (var dirpath in _scanInfo.DirectoriesToCopy)
            {
                #region ReportProgress
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                if (filesProcessed % onePercent == 0)
                    worker.ReportProgress((int)(100L * filesProcessed / filesTotal), filesProcessed);
                #endregion

                DirectoryInfo toInfo = new DirectoryInfo(folderTo + dirpath);
                try
                {
                    toInfo.Create();
                    operations++;
                }
                catch (UnauthorizedAccessException ex)
                {
                    var str = ex.Message;
                    throw;
                }
                catch (Exception ex) { }

                filesProcessed++;
            }

            foreach (var filepath in _scanInfo.FilesToCopy)
            {
                if (worker.CancellationPending)
                {
                    e.Cancel = true;
                    break;
                }
                if (filesProcessed % onePercent == 0)
                    worker.ReportProgress((int)(100L * filesProcessed / filesTotal), filesProcessed);

                FileInfo fromInfo = new FileInfo(folderFrom + filepath);
                try
                {
                    fromInfo.CopyTo(folderTo + filepath, true);
                    operations++;
                }
                catch (UnauthorizedAccessException ex)
                {
                    var str = ex.Message;
                    throw;
                }
                catch (Exception ex) { }

                filesProcessed++;
            }
        }
    }
}
