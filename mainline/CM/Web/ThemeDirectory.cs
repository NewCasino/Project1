using System.Collections;
using System.Security.Permissions;
using System.Web;
using System.Web.Hosting;

namespace CM.Web
{
    /// <summary>
    /// Override VirtualDirectory to ignore stylesheet files in AppTheme directory
    /// </summary>
    [AspNetHostingPermission(SecurityAction.Demand, Level = AspNetHostingPermissionLevel.Minimal)]
    [AspNetHostingPermission(SecurityAction.InheritanceDemand, Level = AspNetHostingPermissionLevel.Minimal)]
    public class ThemeDirectory : VirtualDirectory
    {
        VirtualDirectory m_VirtualDirectory;
        private ArrayList m_Children = new ArrayList();
        private ArrayList m_Directories = new ArrayList();
        private ArrayList m_Files = new ArrayList();

        /// <summary>
        /// override parent properties. Children
        /// </summary>
        public override IEnumerable Children
        {
            get { return m_Children; }
        }

        /// <summary>
        /// override parent properties. Directories
        /// </summary>
        public override IEnumerable Directories
        {
            get { return m_Directories; }
        }

        /// <summary>
        /// override parent properties. Files
        /// </summary>
        public override IEnumerable Files
        {
            get { return m_Files; }
        }

        /// <summary>
        /// contructor, do nothing
        /// </summary>
        /// <param name="toFilter">VirtualDirectory directory</param>
        public ThemeDirectory(VirtualDirectory toFilter)
            : base(toFilter.VirtualPath)
        {
            m_VirtualDirectory = toFilter;
        }

    }

}
