using System;
using System.Collections.Generic;
using System.Globalization;
using System.Text;
using System.Web.Mvc;
using System.Web.Routing;

/// <summary>
/// Extension class for controls
/// </summary>
public static class ControlExtension
{
    /// <summary>
    /// The level of the head
    /// </summary>
    public enum HeadLevel
    {
        /// <summary>
        /// H1
        /// </summary>
        h1,
        /// <summary>
        /// H2
        /// </summary>
        h2,
        /// <summary>
        /// H3
        /// </summary>
        h3,
        /// <summary>
        /// H4
        /// </summary>
        h4,
        /// <summary>
        /// H5
        /// </summary>
        h5,
    }

    /// <summary>
    /// Message type
    /// </summary>
    public enum MessageType
    {
        /// <summary>
        /// Information
        /// </summary>
        Information,

        /// <summary>
        /// Warning
        /// </summary>
        Warning,

        /// <summary>
        /// Error
        /// </summary>
        Error,

        /// <summary>
        /// Success
        /// </summary>
        Success,
    }

    /// <summary>
    /// {0} = css class
    /// {1} = html
    /// </summary>
    public static readonly string HEADER_FORMAT_STRING = @"
<div class=""{0}_Right"">
    <div class=""{0}_Left"">
        <div class=""{0}_Middle"">
            <span>{1}</span>
        </div>
    </div>
</div>";

    /// <summary>
    /// {0} = css class
    /// {1} = html
    /// </summary>
    public static readonly string MESSAGE_FORMAT_STRING = @"
<table cellpadding=""0"" cellspacing=""0"" border=""0"" class=""{0}_Table"">
    <tr>
        <td class=""{0}_Col_Icon"" align=""center"" valign=""middle""><div class=""{0}_Icon""></div></td>
        <td class=""{0}_Col_Text"" valign=""middle""><div class=""{0}_Text"">{1}</div></td>
    </tr>
</table>";

    /// <summary>
    /// {0} = css class
    /// {1} = html
    /// </summary>
    public static readonly string BUTTON_FORMAT_STRING = @"
<span class=""{0}_Right"">
    <span class=""{0}_Left"">
        <span class=""{0}_Center"">
            <span>{1}</span>
        </span>
    </span>
</span>";

    /// <summary>
    /// {0} = css class
    /// {1} = html
    /// </summary>
    public static readonly string LINK_FORMAT_STRING = @"
<span class=""{0}_Right"">
    <span class=""{0}_Left"">
        <span class=""{0}_Center"">
            <span>{1}</span>
        </span>
    </span>
</span>";

    

    #region Header
    /// <summary>
    /// H1 - H7
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="headLevel">header level</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString Header(this HtmlHelper htmlHelper, HeadLevel headLevel, string text, object htmlAttributes = null)
    {
        TagBuilder builder = new TagBuilder(headLevel.ToString());
        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty(headLevel.ToString());
        builder.Attributes["class"] = cssClass;
        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)), false);

        builder.InnerHtml = string.Format( HEADER_FORMAT_STRING
            , cssClass.SafeHtmlEncode()
            , text.SafeHtmlEncode().DefaultIfNullOrEmpty("&#160;")
            );

        return MvcHtmlString.Create(builder.ToString(TagRenderMode.Normal));
    }

    /// <summary>
    /// H1
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString H1(this HtmlHelper htmlHelper, string text, object htmlAttributes = null)
    {
        return ControlExtension.Header(htmlHelper, HeadLevel.h1, text, htmlAttributes);
    }

    /// <summary>
    /// H2
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString H2(this HtmlHelper htmlHelper, string text, object htmlAttributes = null)
    {
        return ControlExtension.Header(htmlHelper, HeadLevel.h2, text, htmlAttributes);
    }

    /// <summary>
    /// H3
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString H3(this HtmlHelper htmlHelper, string text, object htmlAttributes = null)
    {
        return ControlExtension.Header(htmlHelper, HeadLevel.h3, text, htmlAttributes);
    }

    /// <summary>
    /// H4
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString H4(this HtmlHelper htmlHelper, string text, object htmlAttributes = null)
    {
        return ControlExtension.Header(htmlHelper, HeadLevel.h4, text, htmlAttributes);
    }

    /// <summary>
    /// H5
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="text">text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString H5(this HtmlHelper htmlHelper, string text, object htmlAttributes = null)
    {
        return ControlExtension.Header(htmlHelper, HeadLevel.h5, text, htmlAttributes);
    }
    #endregion

    #region Message
    /// <summary>
    /// Message
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="messageType">message type</param>
    /// <param name="textOrHtml">text or html</param>
    /// <param name="isHtml">indicates the textOrHtml is html or plain text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    private static MvcHtmlString Message(this HtmlHelper htmlHelper, MessageType messageType, string textOrHtml, bool isHtml, object htmlAttributes)
    {
        TagBuilder builder = new TagBuilder("div");
        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty("message");
        
        builder.Attributes["class"] = string.Format( "{0} {1}"
            , cssClass
            , messageType.ToString().ToLower(CultureInfo.InvariantCulture)
            );
        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)), false);

        builder.InnerHtml = string.Format(MESSAGE_FORMAT_STRING
            , cssClass.SafeHtmlEncode()
            , isHtml ? textOrHtml : textOrHtml.SafeHtmlEncode()
            );

        return MvcHtmlString.Create(builder.ToString(TagRenderMode.Normal));
    }

    /// <summary>
    /// Success message
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="textOrHtml">text or html</param>
    /// <param name="isHtml">indicates the textOrHtml is html or plain text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString SuccessMessage(this HtmlHelper htmlHelper, string textOrHtml, bool isHtml = false, object htmlAttributes = null)
    {
        return ControlExtension.Message(htmlHelper, MessageType.Success, textOrHtml, isHtml, htmlAttributes);
    }

    /// <summary>
    /// Information message
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="textOrHtml">text or html</param>
    /// <param name="isHtml">indicates the textOrHtml is html or plain text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString InformationMessage(this HtmlHelper htmlHelper, string textOrHtml, bool isHtml = false, object htmlAttributes = null)
    {
        return ControlExtension.Message(htmlHelper, MessageType.Information, textOrHtml, isHtml, htmlAttributes);
    }

    /// <summary>
    /// Warning message
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="textOrHtml">text or html</param>
    /// <param name="isHtml">indicates the textOrHtml is html or plain text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString WarningMessage(this HtmlHelper htmlHelper, string textOrHtml, bool isHtml = false, object htmlAttributes = null)
    {
        return ControlExtension.Message(htmlHelper, MessageType.Warning, textOrHtml, isHtml, htmlAttributes);
    }

    /// <summary>
    /// Error message
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="textOrHtml">text or html</param>
    /// <param name="isHtml">indicates the textOrHtml is html or plain text</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString ErrorMessage(this HtmlHelper htmlHelper, string textOrHtml, bool isHtml = false, object htmlAttributes = null)
    {
        return ControlExtension.Message(htmlHelper, MessageType.Error, textOrHtml, isHtml, htmlAttributes);
    }
    #endregion

    /// <summary>
    /// Button
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="buttonText">the text of the button</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString Button(this HtmlHelper htmlHelper, string buttonText, object htmlAttributes = null)
    {
        TagBuilder builder = new TagBuilder("button");

        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty("button");
        builder.Attributes["class"] = cssClass;

        string onclick = ObjectHelper.GetFieldValue<string>(htmlAttributes, "onclick");
        

        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)), false);

        builder.Attributes["onclick"] = "this.blur();" + onclick; 

        builder.InnerHtml = string.Format(BUTTON_FORMAT_STRING
            , cssClass.SafeHtmlEncode()
            , buttonText.SafeHtmlEncode()
            );

        return MvcHtmlString.Create(builder.ToString(TagRenderMode.Normal));
    }



    /// <summary>
    /// Link button
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="buttonText">text of the button</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString LinkButton(this HtmlHelper htmlHelper, string buttonText, object htmlAttributes = null)
    {
        TagBuilder builder = new TagBuilder("a");

        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty("linkbutton");
        builder.Attributes["class"] = cssClass;

        string onclick = ObjectHelper.GetFieldValue<string>(htmlAttributes, "onclick");


        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)), false);

        builder.Attributes["onclick"] = "this.blur();" + onclick;

        builder.InnerHtml = string.Format(LINK_FORMAT_STRING
            , cssClass.SafeHtmlEncode()
            , buttonText.SafeHtmlEncode()
            );

        return MvcHtmlString.Create(builder.ToString(TagRenderMode.Normal));
    }


    /// <summary>
    /// Begin render selectable table component
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="name">name of the post value</param>
    /// <param name="value">value</param>
    /// <param name="uniqueKeyFieldName">the field name of unique key</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>SelectableTable</returns>
    public static CM.Web.UI.SelectableTable BeginSelectableTable(this HtmlHelper htmlHelper
        , string name
        , object value
        , string uniqueKeyFieldName
        , object htmlAttributes = null
        )
    {
        if (string.IsNullOrWhiteSpace(uniqueKeyFieldName) || string.IsNullOrWhiteSpace(name))
            throw new ArgumentException();

        string hiddenID = "_" + Guid.NewGuid().ToString("N");
        TagBuilder builder = new TagBuilder("input");
        builder.MergeAttribute("type", "hidden");
        if( value != null )
            builder.MergeAttribute("value", value.ToString());
        builder.MergeAttribute("name", name);
        builder.MergeAttribute("id", hiddenID);
        
        htmlHelper.ViewContext.Writer.Write(builder.ToString(TagRenderMode.SelfClosing));

        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty("selectableTable");
        string id = ObjectHelper.GetFieldValue<string>(htmlAttributes, "id").DefaultIfNullOrEmpty("_" + Guid.NewGuid().ToString("N"));
        
        builder = new TagBuilder("table");
        builder.MergeAttribute("cellpadding", "0");
        builder.MergeAttribute("cellspacing", "0");
        builder.MergeAttribute("border", "0");

        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)));

        builder.MergeAttribute("class", cssClass, true);
        builder.MergeAttribute("elementId", hiddenID, true);
        builder.MergeAttribute("id", "0");
        htmlHelper.ViewContext.Writer.Write(builder.ToString(TagRenderMode.StartTag));

        return new CM.Web.UI.SelectableTable(htmlHelper.ViewContext)
            {
                UniqueKeyFieldName = uniqueKeyFieldName,
                ClientID = id,
            };
    }

    /// <summary>
    /// Begin render a navigation menu
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="menuType">Menu type</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <returns>NavigationMenu</returns>
    public static CM.Web.UI.NavigationMenu BeginNavigationMenu(this HtmlHelper htmlHelper
       , CM.Web.UI.MenuType menuType
       , object htmlAttributes = null
       )
    {
        string cssClass = ObjectHelper.GetFieldValue<string>(htmlAttributes, "class").DefaultIfNullOrEmpty(menuType.ToString().ToLowerInvariant());
        string id = ObjectHelper.GetFieldValue<string>(htmlAttributes, "id").DefaultIfNullOrEmpty("_" + Guid.NewGuid().ToString("N"));

        TagBuilder builder = new TagBuilder("div");

        if (htmlAttributes != null)
            builder.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)));

        builder.MergeAttribute("class", cssClass, true);
        builder.MergeAttribute("id", id, true);
        htmlHelper.ViewContext.Writer.Write(builder.ToString(TagRenderMode.StartTag));

        return new CM.Web.UI.NavigationMenu(htmlHelper.ViewContext, menuType) { ClientID = id };
    }


    /// <summary>
    /// Render a textbox
    /// </summary>
    /// <param name="htmlHelper">HtmlHelper</param>
    /// <param name="name">name of this textbox</param>
    /// <param name="value">value of this textbox</param>
    /// <param name="wartermark">warter mark text shown when the value is empty</param>
    /// <param name="htmlAttributes">html attributes</param>
    /// <param name="wrapperCssClass">the css class of the wrapper div</param>
    /// <returns>MvcHtmlString</returns>
    public static MvcHtmlString TextboxEx(this HtmlHelper htmlHelper
        , string name
        , string value
        , string wartermark
        , object htmlAttributes = null
        , string wrapperCssClass = null
        )
    {
        TagBuilder builder = new TagBuilder("div");
        builder.AddCssClass(wrapperCssClass.DefaultIfNullOrEmpty("textboxex"));

        StringBuilder innerHTML = new StringBuilder();
        {
            TagBuilder builder2 = new TagBuilder("input");
            if (htmlAttributes != null)
                builder2.MergeAttributes<string, object>(((IDictionary<string, object>)new RouteValueDictionary(htmlAttributes)));
            if (!string.IsNullOrEmpty(name))
                builder2.MergeAttribute("name", name, true);
            if (!string.IsNullOrEmpty(value))
                builder2.MergeAttribute("value", value, true);
            builder2.MergeAttribute("autocomplete", "off");

            innerHTML.AppendFormat( @"
<div class=""{0}_Right"">
    <div class=""{0}_Center"">"
                , wrapperCssClass.DefaultIfNullOrEmpty("textboxex").SafeHtmlEncode()
                );
            innerHTML.AppendLine(builder2.ToString(TagRenderMode.SelfClosing));

            if (!string.IsNullOrEmpty(wartermark))
            {
                TagBuilder builder3 = new TagBuilder("input");
                builder3.AddCssClass("textboxex_wartermark");
                builder3.Attributes["style"] = "display:none";
                builder3.Attributes["readonly"] = "readonly";
                builder3.Attributes["type"] = "text";
                builder3.Attributes["value"] = wartermark;
                innerHTML.AppendLine(builder3.ToString(TagRenderMode.SelfClosing));
            }

            innerHTML.AppendFormat(@"
	</div>
</div>");
        }
        builder.InnerHtml = innerHTML.ToString();
        return MvcHtmlString.Create(builder.ToString(TagRenderMode.Normal));
    }


    /// <summary>
    /// add the disabled="disabled" attribute to DOM 
    /// </summary>
    /// <param name="dic"></param>
    /// <param name="isDisabled">true if disabled</param>
    /// <returns></returns>
    public static Dictionary<string, object> SetDisabled( this Dictionary<string, object> dic, bool isDisabled)
    {
        if (isDisabled)
            dic.Add("disabled", "disabled");
        return dic;
    }

    /// <summary>
    /// add the readonly="readonly" attribute to DOM 
    /// </summary>
    /// <param name="dic"></param>
    /// <param name="isReadOnly">true if readonly</param>
    /// <returns></returns>
    public static Dictionary<string, object> SetReadOnly(this Dictionary<string, object> dic, bool isReadOnly)
    {
        if (isReadOnly)
            dic.Add("readonly", "readonly");
        return dic;
    }

}

