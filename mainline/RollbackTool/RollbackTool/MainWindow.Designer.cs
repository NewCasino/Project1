namespace RollbackTool
{
    partial class MainWindow
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.btnSync = new System.Windows.Forms.Button();
            this.pbProgress = new System.Windows.Forms.ProgressBar();
            this.txtFrom = new System.Windows.Forms.TextBox();
            this.txtTo = new System.Windows.Forms.TextBox();
            this.lblFrom = new System.Windows.Forms.Label();
            this.lblTo = new System.Windows.Forms.Label();
            this.lblOperations = new System.Windows.Forms.Label();
            this.lblTotalTime = new System.Windows.Forms.Label();
            this.btnDestinationFolderDialog = new System.Windows.Forms.Button();
            this.btnSourceFolderDialog = new System.Windows.Forms.Button();
            this.btnScan = new System.Windows.Forms.Button();
            this.lblFilesToDeleteSize = new System.Windows.Forms.Label();
            this.lblFilesToCopySize = new System.Windows.Forms.Label();
            this.pnlPaths = new System.Windows.Forms.Panel();
            this.chkSyncOnlySystemViewsFolders = new System.Windows.Forms.CheckBox();
            this.gvDifferences = new System.Windows.Forms.DataGridView();
            this.ColumnIndex = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.ColumnName = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.pnlPaths.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.gvDifferences)).BeginInit();
            this.SuspendLayout();
            // 
            // btnSync
            // 
            this.btnSync.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSync.Location = new System.Drawing.Point(475, 45);
            this.btnSync.Name = "btnSync";
            this.btnSync.Size = new System.Drawing.Size(112, 23);
            this.btnSync.TabIndex = 0;
            this.btnSync.Text = "Sync";
            this.btnSync.UseVisualStyleBackColor = true;
            this.btnSync.Click += new System.EventHandler(this.btnSync_Click);
            // 
            // pbProgress
            // 
            this.pbProgress.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pbProgress.Location = new System.Drawing.Point(15, 101);
            this.pbProgress.MarqueeAnimationSpeed = 10;
            this.pbProgress.Name = "pbProgress";
            this.pbProgress.Size = new System.Drawing.Size(572, 23);
            this.pbProgress.TabIndex = 1;
            // 
            // txtFrom
            // 
            this.txtFrom.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtFrom.Location = new System.Drawing.Point(39, 2);
            this.txtFrom.Name = "txtFrom";
            this.txtFrom.Size = new System.Drawing.Size(370, 20);
            this.txtFrom.TabIndex = 2;
            this.txtFrom.Text = "d:\\Everymatrix\\CopyTest\\1\\";
            // 
            // txtTo
            // 
            this.txtTo.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.txtTo.Location = new System.Drawing.Point(39, 36);
            this.txtTo.Name = "txtTo";
            this.txtTo.Size = new System.Drawing.Size(370, 20);
            this.txtTo.TabIndex = 3;
            this.txtTo.Text = "d:\\Everymatrix\\CopyTest\\2\\";
            // 
            // lblFrom
            // 
            this.lblFrom.AutoSize = true;
            this.lblFrom.Location = new System.Drawing.Point(3, 5);
            this.lblFrom.Name = "lblFrom";
            this.lblFrom.Size = new System.Drawing.Size(30, 13);
            this.lblFrom.TabIndex = 4;
            this.lblFrom.Text = "From";
            // 
            // lblTo
            // 
            this.lblTo.AutoSize = true;
            this.lblTo.Location = new System.Drawing.Point(3, 37);
            this.lblTo.Name = "lblTo";
            this.lblTo.Size = new System.Drawing.Size(20, 13);
            this.lblTo.TabIndex = 5;
            this.lblTo.Text = "To";
            // 
            // lblOperations
            // 
            this.lblOperations.AutoSize = true;
            this.lblOperations.Location = new System.Drawing.Point(312, 134);
            this.lblOperations.Name = "lblOperations";
            this.lblOperations.Size = new System.Drawing.Size(88, 13);
            this.lblOperations.TabIndex = 6;
            this.lblOperations.Text = "Total Operations:";
            // 
            // lblTotalTime
            // 
            this.lblTotalTime.AutoSize = true;
            this.lblTotalTime.Location = new System.Drawing.Point(312, 157);
            this.lblTotalTime.Name = "lblTotalTime";
            this.lblTotalTime.Size = new System.Drawing.Size(60, 13);
            this.lblTotalTime.TabIndex = 9;
            this.lblTotalTime.Text = "Total Time:";
            // 
            // btnDestinationFolderDialog
            // 
            this.btnDestinationFolderDialog.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnDestinationFolderDialog.Location = new System.Drawing.Point(415, 34);
            this.btnDestinationFolderDialog.Name = "btnDestinationFolderDialog";
            this.btnDestinationFolderDialog.Size = new System.Drawing.Size(33, 23);
            this.btnDestinationFolderDialog.TabIndex = 11;
            this.btnDestinationFolderDialog.Text = "...";
            this.btnDestinationFolderDialog.UseVisualStyleBackColor = true;
            this.btnDestinationFolderDialog.Click += new System.EventHandler(this.btnFolderDialog_Click);
            // 
            // btnSourceFolderDialog
            // 
            this.btnSourceFolderDialog.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnSourceFolderDialog.Location = new System.Drawing.Point(415, -1);
            this.btnSourceFolderDialog.Name = "btnSourceFolderDialog";
            this.btnSourceFolderDialog.Size = new System.Drawing.Size(33, 23);
            this.btnSourceFolderDialog.TabIndex = 12;
            this.btnSourceFolderDialog.Text = "...";
            this.btnSourceFolderDialog.UseVisualStyleBackColor = true;
            this.btnSourceFolderDialog.Click += new System.EventHandler(this.btnFolderDialog_Click);
            // 
            // btnScan
            // 
            this.btnScan.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Right)));
            this.btnScan.Location = new System.Drawing.Point(475, 10);
            this.btnScan.Name = "btnScan";
            this.btnScan.Size = new System.Drawing.Size(112, 23);
            this.btnScan.TabIndex = 13;
            this.btnScan.Text = "Scan";
            this.btnScan.UseVisualStyleBackColor = true;
            this.btnScan.Click += new System.EventHandler(this.btnScan_Click);
            // 
            // lblFilesToDeleteSize
            // 
            this.lblFilesToDeleteSize.AutoSize = true;
            this.lblFilesToDeleteSize.Location = new System.Drawing.Point(12, 134);
            this.lblFilesToDeleteSize.Name = "lblFilesToDeleteSize";
            this.lblFilesToDeleteSize.Size = new System.Drawing.Size(107, 13);
            this.lblFilesToDeleteSize.TabIndex = 14;
            this.lblFilesToDeleteSize.Text = "Files To Delete Size: ";
            // 
            // lblFilesToCopySize
            // 
            this.lblFilesToCopySize.AutoSize = true;
            this.lblFilesToCopySize.Location = new System.Drawing.Point(12, 157);
            this.lblFilesToCopySize.Name = "lblFilesToCopySize";
            this.lblFilesToCopySize.Size = new System.Drawing.Size(100, 13);
            this.lblFilesToCopySize.TabIndex = 15;
            this.lblFilesToCopySize.Text = "Files To Copy Size: ";
            // 
            // pnlPaths
            // 
            this.pnlPaths.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pnlPaths.Controls.Add(this.chkSyncOnlySystemViewsFolders);
            this.pnlPaths.Controls.Add(this.lblFrom);
            this.pnlPaths.Controls.Add(this.txtFrom);
            this.pnlPaths.Controls.Add(this.txtTo);
            this.pnlPaths.Controls.Add(this.lblTo);
            this.pnlPaths.Controls.Add(this.btnSourceFolderDialog);
            this.pnlPaths.Controls.Add(this.btnDestinationFolderDialog);
            this.pnlPaths.Location = new System.Drawing.Point(12, 11);
            this.pnlPaths.Name = "pnlPaths";
            this.pnlPaths.Size = new System.Drawing.Size(453, 84);
            this.pnlPaths.TabIndex = 16;
            // 
            // chkSyncOnlySystemViewsFolders
            // 
            this.chkSyncOnlySystemViewsFolders.AutoSize = true;
            this.chkSyncOnlySystemViewsFolders.Checked = true;
            this.chkSyncOnlySystemViewsFolders.CheckState = System.Windows.Forms.CheckState.Checked;
            this.chkSyncOnlySystemViewsFolders.Location = new System.Drawing.Point(39, 61);
            this.chkSyncOnlySystemViewsFolders.Name = "chkSyncOnlySystemViewsFolders";
            this.chkSyncOnlySystemViewsFolders.Size = new System.Drawing.Size(280, 17);
            this.chkSyncOnlySystemViewsFolders.TabIndex = 13;
            this.chkSyncOnlySystemViewsFolders.Text = "Sync only Shared, MobileShared and System in Views";
            this.chkSyncOnlySystemViewsFolders.UseVisualStyleBackColor = true;
            this.chkSyncOnlySystemViewsFolders.Visible = false;
            // 
            // gvDifferences
            // 
            this.gvDifferences.AllowUserToAddRows = false;
            this.gvDifferences.AllowUserToDeleteRows = false;
            this.gvDifferences.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.gvDifferences.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.gvDifferences.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.ColumnIndex,
            this.ColumnName});
            this.gvDifferences.Location = new System.Drawing.Point(12, 181);
            this.gvDifferences.Name = "gvDifferences";
            this.gvDifferences.ReadOnly = true;
            this.gvDifferences.Size = new System.Drawing.Size(572, 258);
            this.gvDifferences.TabIndex = 17;
            // 
            // ColumnIndex
            // 
            this.ColumnIndex.DataPropertyName = "Index";
            this.ColumnIndex.HeaderText = "#";
            this.ColumnIndex.Name = "ColumnIndex";
            this.ColumnIndex.ReadOnly = true;
            // 
            // ColumnName
            // 
            this.ColumnName.DataPropertyName = "Name";
            this.ColumnName.HeaderText = "Path";
            this.ColumnName.Name = "ColumnName";
            this.ColumnName.ReadOnly = true;
            // 
            // MainWindow
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(599, 451);
            this.Controls.Add(this.gvDifferences);
            this.Controls.Add(this.pnlPaths);
            this.Controls.Add(this.lblFilesToCopySize);
            this.Controls.Add(this.lblFilesToDeleteSize);
            this.Controls.Add(this.btnScan);
            this.Controls.Add(this.lblTotalTime);
            this.Controls.Add(this.lblOperations);
            this.Controls.Add(this.pbProgress);
            this.Controls.Add(this.btnSync);
            this.Name = "MainWindow";
            this.Text = "Sync Tool";
            this.pnlPaths.ResumeLayout(false);
            this.pnlPaths.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.gvDifferences)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button btnSync;
        private System.Windows.Forms.ProgressBar pbProgress;
        private System.Windows.Forms.TextBox txtFrom;
        private System.Windows.Forms.TextBox txtTo;
        private System.Windows.Forms.Label lblFrom;
        private System.Windows.Forms.Label lblTo;
        private System.Windows.Forms.Label lblOperations;
        private System.Windows.Forms.Label lblTotalTime;
        private System.Windows.Forms.Button btnDestinationFolderDialog;
        private System.Windows.Forms.Button btnSourceFolderDialog;
        private System.Windows.Forms.Button btnScan;
        private System.Windows.Forms.Label lblFilesToDeleteSize;
        private System.Windows.Forms.Label lblFilesToCopySize;
        private System.Windows.Forms.Panel pnlPaths;
        private System.Windows.Forms.DataGridView gvDifferences;
        private System.Windows.Forms.DataGridViewTextBoxColumn ColumnIndex;
        private System.Windows.Forms.DataGridViewTextBoxColumn ColumnName;
        private System.Windows.Forms.CheckBox chkSyncOnlySystemViewsFolders;
    }
}

