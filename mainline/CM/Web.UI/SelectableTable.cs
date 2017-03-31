using System;
using System.Collections;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Mvc;
using System.Web.Script.Serialization;

namespace CM.Web.UI
{
    public sealed class SelectableTableColumn
    {
        public string DateFieldName { get; set; }
        public bool IsVisible { get; set; }
        public string VerticalAlign { get; set; }
        public string CssClass { get; set; }

        public SelectableTableColumn()
        {
            this.IsVisible = true;
            this.VerticalAlign = "middle";
        }
    }

    public sealed class SelectableTable : IDisposable
    {
        public string ClientID { get; set; }
        public string UniqueKeyFieldName { get; set; }
        public SelectableTableColumn[] Columns { get; private set; }

        private bool _disposed;
        private readonly ViewContext _viewContext;
        private readonly TextWriter _writer;
        private int _rowCount;
        private StringBuilder _jsonData = new StringBuilder();



        public string OnClientSelectionChanged { get; set; }

        internal SelectableTable(ViewContext viewContext)
        {
            this._viewContext = viewContext;
            this._writer = viewContext.Writer;
            this._rowCount = 0;
        }


        ~SelectableTable()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            bool isAjax = HttpContext.Current.Request.IsAjaxRequest();
            if (!this._disposed)
            {
                this._disposed = true;
                this._writer.Write("</table>");

                this._writer.WriteLine( string.Format(@"
<script language=""javascript"" type=""text/javascript"">
//<![CDATA[
if( self.tableData == null ) self.tableData = {{}};
self.tableData[""{0}""] = {{}};{1}"
                    , this.ClientID
                    , this._jsonData
                    , this.OnClientSelectionChanged
                    ));

                if (HttpContext.Current.Request.IsAjaxRequest())
                {
                    this._writer.WriteLine(string.Format(@"
setTimeout( function() {{ $('#{0}').initilizeSelectableTable({1}); }}, 500);"
                        , this.ClientID
                        , this.OnClientSelectionChanged
                        ));
                }
                else
                {
                    this._writer.WriteLine(string.Format(@"
$(document).ready( function() {{ $('#{0}').initilizeSelectableTable({1}); }});"
                        , this.ClientID
                        , this.OnClientSelectionChanged
                        ));
                }

                this._writer.WriteLine(@"
//]]>
</script>");
            }
        }

        public void EndForm()
        {
            this.Dispose(true);
        }

        public void DefineColumns(params SelectableTableColumn[] columns)
        {
            this.Columns = columns;
        }

        public void RenderRow(object data)
        {
            string key = ObjectHelper.GetFieldValue<object>(data, this.UniqueKeyFieldName).ToString();
            StringBuilder sb = new StringBuilder();
            this._writer.Write( string.Format( @"
<tr key=""{1}"" {0}>", (_rowCount % 2) == 0 ? string.Empty : "class=\"alternate_Row\""
                     , key.SafeJavascriptStringEncode()
                     )
            );

            this._jsonData.AppendFormat("\nself.tableData[\"{0}\"][\"{1}\"] = {2};"
                , this.ClientID.SafeJavascriptStringEncode()
                , key.SafeJavascriptStringEncode()
                , (new JavaScriptSerializer()).Serialize(data)
                );

            for (int col = 0; col < this.Columns.Length; col++)
            {
                string value = ObjectHelper.GetFieldValue<object>(data, this.Columns[col].DateFieldName).ToString();
                this._writer.Write( string.Format( @"
    <td valign=""{0}"" class=""col-{1} {2}"" {3}>{4}</td>"
                    , this.Columns[col].VerticalAlign.SafeHtmlEncode()
                    , col+1
                    , this.Columns[col].CssClass.SafeHtmlEncode()
                    , this.Columns[col].IsVisible ? string.Empty : "style=\"display:none\""
                    , value.SafeHtmlEncode()
                    ) );
            }

            this._writer.Write(@"
</tr>");
            _rowCount++;
        }

        public void RenderRows(IEnumerable rows)
        {
            foreach( object row in rows)
            {
                this.RenderRow(row);
            }
        }
    }
}
