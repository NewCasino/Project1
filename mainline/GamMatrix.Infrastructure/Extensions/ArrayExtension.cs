using System;
using System.Collections;
using System.Text;

public static class ArrayExtension
{
    public static string ConvertToCommaSplitedString( this IEnumerable array)
    {
        if (array == null) return string.Empty;
        StringBuilder sb = new StringBuilder();
        foreach (var item in array)
        {
            if( item != null )
                sb.AppendFormat("{0},", item.ToString());
        }
        if (sb.Length > 0 && sb[sb.Length - 1] == ',')
            sb.Remove(sb.Length - 1, 1);
        return sb.ToString();
    }
}
