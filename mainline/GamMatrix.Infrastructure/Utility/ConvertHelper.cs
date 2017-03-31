using System;

/// <summary>
/// Converts a base data type to another base data type, Never throw exceptions whatever the conversion succeeded or failed.
/// </summary>
public class ConvertHelper
{
    public static object ChangeType(object value, Type conversionType, object defaultValue)
    {
        object obj = null;
        try
        {
            obj = Convert.ChangeType(value, conversionType);
        }
        catch
        {
            obj = Convert.ChangeType(defaultValue, conversionType);
        }
        return obj;
    }

    #region Try to ...
    public static bool TryToBoolean(object value, out bool result, bool? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = false;

        try
        {
            result = Convert.ToBoolean(value);
        }
        catch
        {
            return false;
        }
        return true;
    }


    public static bool TryToDateTime(object value, out DateTime result, DateTime? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = new DateTime(1900, 1, 1);

        try
        {
            result = Convert.ToDateTime(value);
        }
        catch
        {
            return false;
        }
        return true;
    }


    public static bool TryToDecimal(object value, out decimal result, decimal? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0.00m;

        try
        {
            result = Convert.ToDecimal(value);
        }
        catch
        {
            return false;
        }
        return true;
    }


    public static bool TryToDouble(object value, out double result, double? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0.0;

        try
        {
            result = Convert.ToDouble(value);
        }
        catch
        {
            return false;
        }
        return true;
    }


    public static bool TryToInt16(object value, out short result, short? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0;

        try
        {
            result = Convert.ToInt16(value);
        }
        catch
        {
            return false;
        }
        return true;
    }


    /// <summary>
    /// Try to convert object to int32
    /// </summary>
    /// <param name="value"></param>
    /// <param name="result"></param>
    /// <param name="defaultValue"></param>
    /// <returns></returns>
    public static bool TryToInt32(object value, out int result, int? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0;

        try
        {
            result = Convert.ToInt32(value);
        }
        catch
        {
            return false;
        }
        return true;
    }

    public static bool TryToInt64(object value, out long result, long? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0L;

        try
        {
            result = Convert.ToInt64(value);
        }
        catch
        {
            return false;
        }
        return true;
    }

    public static bool TryToUInt64(object value, out ulong result, ulong? defaultValue)
    {
        if (defaultValue.HasValue)
            result = defaultValue.Value;
        else
            result = 0L;

        try
        {
            result = Convert.ToUInt64(value);
        }
        catch
        {
            return false;
        }
        return true;
    }
    #endregion

    #region
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>bool, If the conversion is failed, it will returns false</returns>
    public static bool ToBoolean(object value)
    {
        return ToBoolean(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>bool, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or false</returns>
    public static bool ToBoolean(object value, bool? defaultValue)
    {
        try
        {
            return Convert.ToBoolean(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return false;
        }
    }

    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>DateTime, If the conversion is failed, it will returns '1900-01-01'</returns>
    public static DateTime ToDateTime(object value)
    {
        return ToDateTime(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>DateTime, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or '1900-01-01'</returns>
    public static DateTime ToDateTime(object value, DateTime? defaultValue)
    {
        try
        {
            return Convert.ToDateTime(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return new DateTime(1900, 1, 1);
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>decimal, If the conversion is failed, it will returns 0.00m</returns>
    public static decimal ToDecimal(object value)
    {
        return ToDecimal(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>Decimal, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0.00m</returns>
    public static decimal ToDecimal(object value, decimal? defaultValue)
    {
        try
        {
            return Convert.ToDecimal(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0.00m;
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>double, If the conversion is failed, it will returns 0.0</returns>
    public static double ToDouble(object value)
    {
        return ToDouble(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>Double, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0.0</returns>
    public static double ToDouble(object value, double? defaultValue)
    {
        try
        {
            return Convert.ToDouble(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0.0;
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>short, If the conversion is failed, it will returns 0</returns>
    public static short ToInt16(object value)
    {
        return ToInt16(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>short, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0</returns>
    public static short ToInt16(object value, short? defaultValue)
    {
        try
        {
            return Convert.ToInt16(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0;
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>int, If the conversion is failed, it will returns 0</returns>
    public static int ToInt32(object value)
    {
        return ToInt32(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>int, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0</returns>
    public static int ToInt32(object value, int? defaultValue)
    {
        try
        {
            return Convert.ToInt32(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0;
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>long, If the conversion is failed, it will returns 0L</returns>
    public static long ToInt64(object value)
    {
        return ToInt64(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>long, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0L</returns>
    public static long ToInt64(object value, long? defaultValue)
    {
        try
        {
            return Convert.ToInt64(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0L;
        }
    }


    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <returns>ulong, If the conversion is failed, it will returns 0L</returns>
    public static ulong ToUInt64(object value)
    {
        return ToUInt64(value, null);
    }
    /// <summary>
    /// 
    /// </summary>
    /// <param name="value"></param>
    /// <param name="defaultValue"></param>
    /// <returns>ulong, If the conversion is failed, it will returns defaultValue(only when defaultValue has value) or 0L</returns>
    public static ulong ToUInt64(object value, ulong? defaultValue)
    {
        try
        {
            return Convert.ToUInt64(value);
        }
        catch
        {
            if (defaultValue.HasValue)
                return defaultValue.Value;
            else
                return 0L;
        }
    }
    #endregion

    public static string ToString(object value)
    {
        return Convert.ToString(value);
    }
    public static string ToString(object value, string defaultValue)
    {
        string result = value.ToString();
        if (string.IsNullOrEmpty(result) && !string.IsNullOrEmpty(defaultValue))
            result = defaultValue;

        return result;
    }

}
