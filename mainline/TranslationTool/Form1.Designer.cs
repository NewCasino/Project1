namespace TranslationTool
{
    partial class Form1
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
            this.lstDirectories = new System.Windows.Forms.ListView();
            this.columnHeader1 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.btnSave = new System.Windows.Forms.Button();
            this.ctlContainer = new System.Windows.Forms.TableLayoutPanel();
            this.SuspendLayout();
            // 
            // lstDirectories
            // 
            this.lstDirectories.CausesValidation = false;
            this.lstDirectories.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.columnHeader1});
            this.lstDirectories.Dock = System.Windows.Forms.DockStyle.Left;
            this.lstDirectories.FullRowSelect = true;
            this.lstDirectories.GridLines = true;
            this.lstDirectories.Location = new System.Drawing.Point(0, 0);
            this.lstDirectories.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.lstDirectories.MultiSelect = false;
            this.lstDirectories.Name = "lstDirectories";
            this.lstDirectories.ShowGroups = false;
            this.lstDirectories.Size = new System.Drawing.Size(446, 635);
            this.lstDirectories.TabIndex = 0;
            this.lstDirectories.UseCompatibleStateImageBehavior = false;
            this.lstDirectories.View = System.Windows.Forms.View.Details;
            this.lstDirectories.SelectedIndexChanged += new System.EventHandler(this.lstDirectories_SelectedIndexChanged);
            // 
            // columnHeader1
            // 
            this.columnHeader1.Text = "Directories";
            this.columnHeader1.Width = 380;
            // 
            // btnSave
            // 
            this.btnSave.Dock = System.Windows.Forms.DockStyle.Bottom;
            this.btnSave.Location = new System.Drawing.Point(446, 584);
            this.btnSave.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.btnSave.Name = "btnSave";
            this.btnSave.Size = new System.Drawing.Size(510, 51);
            this.btnSave.TabIndex = 2;
            this.btnSave.Text = "Save(&S)";
            this.btnSave.UseVisualStyleBackColor = true;
            this.btnSave.Click += new System.EventHandler(this.btnSave_Click);
            // 
            // ctlContainer
            // 
            this.ctlContainer.AutoScroll = true;
            this.ctlContainer.ColumnCount = 1;
            this.ctlContainer.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Percent, 100F));
            this.ctlContainer.ColumnStyles.Add(new System.Windows.Forms.ColumnStyle(System.Windows.Forms.SizeType.Absolute, 24F));
            this.ctlContainer.Dock = System.Windows.Forms.DockStyle.Fill;
            this.ctlContainer.Location = new System.Drawing.Point(446, 0);
            this.ctlContainer.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.ctlContainer.Name = "ctlContainer";
            this.ctlContainer.RowCount = 1;
            this.ctlContainer.RowStyles.Add(new System.Windows.Forms.RowStyle());
            this.ctlContainer.Size = new System.Drawing.Size(510, 584);
            this.ctlContainer.TabIndex = 3;
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(7F, 16F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.AutoSize = true;
            this.ClientSize = new System.Drawing.Size(956, 635);
            this.Controls.Add(this.ctlContainer);
            this.Controls.Add(this.btnSave);
            this.Controls.Add(this.lstDirectories);
            this.Font = new System.Drawing.Font("Tahoma", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.Margin = new System.Windows.Forms.Padding(4, 3, 4, 3);
            this.Name = "Form1";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Translation Tool";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.Load += new System.EventHandler(this.Form1_Load);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.ListView lstDirectories;
        private System.Windows.Forms.ColumnHeader columnHeader1;
        private System.Windows.Forms.Button btnSave;
        private System.Windows.Forms.TableLayoutPanel ctlContainer;
    }
}

