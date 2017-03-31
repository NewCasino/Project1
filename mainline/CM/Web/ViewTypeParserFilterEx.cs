using System;
using System.Collections;
using System.Web.Mvc;
using System.Web.UI;

namespace CM.Web
{
    /// <summary>
    /// JERRY:
    /// Replace the ViewTypeParserFilter from System.Web.Mvc.dll
    /// 
    /// The way ASP.NET MVC worked around this was by fooling the underlying page parser into thinking that the page is not generic. 
    /// They did this by building a custom PageParserFilter and a custom FileLevelPageControlBuilder. 
    /// The parser filter looks for a generic type, and if it finds one, swaps it out for the non-generic ViewPage type 
    /// so that the ASP.NET parser doesn't choke. 
    /// Then, much later in the page compilation lifecycle, their custom page builder class swaps the generic type back in.
    /// </summary>
    public sealed class ViewTypeParserFilterEx : PageParserFilter
    {
        // Fields
        private DirectiveType _directiveType;
        private string _viewBaseType;
        private bool _viewTypeControlAdded;

        // Methods
        public override bool AllowBaseType(Type baseType)
        {
            return true;
        }

        public override bool AllowControl(Type controlType, ControlBuilder builder)
        {
            return true;
        }

        public override bool AllowServerSideInclude(string includeVirtualPath)
        {
            return true;
        }

        public override bool AllowVirtualReference(string referenceVirtualPath, VirtualReferenceType referenceType)
        {
            return true;
        }

        private static bool IsGenericTypeString(string typeName)
        {
            return (typeName.IndexOfAny(new char[] { '<', '(' }) >= 0);
        }

        public override void ParseComplete(ControlBuilder rootBuilder)
        {
            base.ParseComplete(rootBuilder);
            Type type = rootBuilder.GetType();

            ViewPageControlBuilderEx viewPageControlBuilder = rootBuilder as ViewPageControlBuilderEx;
            if (viewPageControlBuilder != null)
                viewPageControlBuilder.PageBaseType = this._viewBaseType;

            ViewUserControlControlBuilderEx viewUserControlControlBuilder = rootBuilder as ViewUserControlControlBuilderEx;
            if (viewUserControlControlBuilder != null)
                viewUserControlControlBuilder.UserControlBaseType = this._viewBaseType;
        }

        public override void PreprocessDirective(string directiveName, IDictionary attributes)
        {
            base.PreprocessDirective(directiveName, attributes);
            string fullName = null;
            string str3 = directiveName;
            if (str3 != null)
            {
                if (!(str3 == "page"))
                {
                    if (string.Compare( "control", str3, true) == 0)
                    {
                        this._directiveType = DirectiveType.UserControl;
                        fullName = typeof(ViewUserControlEx).FullName; // replace here, use extended class
                    }
                    else if (str3 == "master")
                    {
                        this._directiveType = DirectiveType.Master;
                        fullName = typeof(ViewMasterPageEx).FullName; // replace here, use extended class
                    }
                }
                else
                {
                    this._directiveType = DirectiveType.Page;
                    fullName = typeof(ViewPageEx).FullName; // replace here, use extended class
                }
            }
            if (this._directiveType != DirectiveType.Unknown)
            {
                string str2 = (string)attributes["inherits"];
                if (!string.IsNullOrEmpty(str2) && IsGenericTypeString(str2))
                {
                    attributes["inherits"] = fullName;
                    this._viewBaseType = str2;
                }
            }
        }

        public override bool ProcessCodeConstruct(CodeConstructType codeType, string code)
        {
            if ((!this._viewTypeControlAdded && (this._viewBaseType != null)) && (this._directiveType == DirectiveType.Master))
            {
                // If we're dealing with a master page that needs to have its base type set, do it here.
                // It's done by adding the ViewType control, which has a builder that sets the base type.

                // The code currently assumes that the file in question contains a code snippet, since
                // that's the item we key off of in order to know when to add the ViewType control.

                Hashtable attributes = new Hashtable();
                attributes["typename"] = this._viewBaseType;
                base.AddControl(typeof(ViewType), attributes);
                this._viewTypeControlAdded = true;
            }
            return base.ProcessCodeConstruct(codeType, code);
        }

        // Properties
        public override bool AllowCode
        {
            get
            {
                return true;
            }
        }

        public override int NumberOfControlsAllowed
        {
            get
            {
                return -1;
            }
        }

        public override int NumberOfDirectDependenciesAllowed
        {
            get
            {
                return -1;
            }
        }

        public override int TotalNumberOfDependenciesAllowed
        {
            get
            {
                return -1;
            }
        }

        // Nested Types
        private enum DirectiveType
        {
            Unknown,
            Page,
            UserControl,
            Master
        }
    }


}
