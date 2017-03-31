namespace SiteMapGenerator
{
    partial class ProjectInstaller
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region 组件设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.sitemapServiceProcessInstaller = new System.ServiceProcess.ServiceProcessInstaller();
            this.serviceInstaller1 = new System.ServiceProcess.ServiceInstaller();
            // 
            // sitemapServiceProcessInstaller
            // 
            this.sitemapServiceProcessInstaller.Account = System.ServiceProcess.ServiceAccount.LocalSystem;
            this.sitemapServiceProcessInstaller.Password = null;
            this.sitemapServiceProcessInstaller.Username = null;
            // 
            // serviceInstaller1
            // 
            this.serviceInstaller1.ServiceName = "SiteMapGenerator";
            this.serviceInstaller1.StartType = System.ServiceProcess.ServiceStartMode.Automatic;
            // 
            // ProjectInstaller
            // 
            this.Installers.AddRange(new System.Configuration.Install.Installer[] {
            this.sitemapServiceProcessInstaller,
            this.serviceInstaller1});

        }

        #endregion

        private System.ServiceProcess.ServiceProcessInstaller sitemapServiceProcessInstaller;
        private System.ServiceProcess.ServiceInstaller serviceInstaller1;
    }
}