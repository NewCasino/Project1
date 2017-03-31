using System.CodeDom;
using System.Web.UI;

namespace CM.Web
{
    /// <summary>
    /// JERRY:
    /// Replace the ViewUserControlControlBuilder from System.Web.Mvc.dll
    /// </summary>
    public sealed class ViewUserControlControlBuilderEx : FileLevelUserControlBuilder
    {
        // Properties
        public string UserControlBaseType
        {
            get;
            set;
        }

        // Methods
        public override void ProcessGeneratedCode(CodeCompileUnit codeCompileUnit, CodeTypeDeclaration baseType, CodeTypeDeclaration derivedType, CodeMemberMethod buildMethod, CodeMemberMethod dataBindingMethod)
        {
            if (this.UserControlBaseType != null)
            {
                derivedType.BaseTypes[0] = new CodeTypeReference(this.UserControlBaseType);
            }
        }        
    }

 

}
