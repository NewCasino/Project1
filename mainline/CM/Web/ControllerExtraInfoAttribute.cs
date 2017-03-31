using System;

namespace CM.Web
{
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = false, Inherited = false)]
    public sealed class ControllerExtraInfoAttribute : Attribute
    {
        public string DefaultAction { get; set; }
        public string ParameterUrl { get; set; }
    }
}
