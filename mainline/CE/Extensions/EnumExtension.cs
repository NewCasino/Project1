using System;
using System.ComponentModel;
using System.Reflection;

namespace CE.Extensions
{
    public static class EnumExtension
    {
        public static string GetDescription(this Enum value)
        {
            FieldInfo field = value.GetType().GetField(value.ToString());
            if (field == null)
                return string.Empty;
            object[] attribs = field.GetCustomAttributes(typeof(DescriptionAttribute), false);
            if (attribs.Length > 0)
            {
                return ((DescriptionAttribute)attribs[0]).Description;
            }
            return value.ToString();
        }
    }
}
