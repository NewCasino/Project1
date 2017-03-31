using System.CodeDom;
using System.Web.UI;

namespace CM.Web
{
    public sealed class ViewPageControlBuilderEx : FileLevelPageControlBuilder
    {
        // Methods
        public override void ProcessGeneratedCode(CodeCompileUnit codeCompileUnit, CodeTypeDeclaration baseType, CodeTypeDeclaration derivedType, CodeMemberMethod buildMethod, CodeMemberMethod dataBindingMethod)
        {
            if (this.PageBaseType != null)
            {
                
                derivedType.BaseTypes[0] = new CodeTypeReference(this.PageBaseType);
            }
        }

        // Properties
        public string PageBaseType
        {
            get; set;
        }
    }
}
