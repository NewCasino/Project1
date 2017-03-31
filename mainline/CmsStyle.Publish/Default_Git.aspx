<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default_Git.aspx.cs" Inherits="CmsStyle.Publish.Default_Git" %>

<!DOCTYPE html>

<html>
<head runat="server">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title></title>
    <link href="/js/jquery-ui/jquery-ui.min.css" rel="stylesheet" />
    <script type="text/javascript" src="/js/jquery-2.1.3.min.js"></script>
    <script type="text/javascript" src="/js/jquery-ui/jquery-ui.min.js"></script>
    <style type="text/css">
        body
        {
            font-size:18px;
            line-height:22px;
        }
        ul, li
        {
            list-style:none;
        }
        .dir-list
        {
            list-style:none;
        }
            .dir-list li
            {
                float:left;
                width: 23%;
                padding:2px 1%;
            }
                .dir-list li:hover, .dir-list li.selected
                {
                    background-color:#643DBE;
                    color:#FFFFFF;                    
                }
                .dir-list li.selected
                {
                    font-weight:bold;
                }
                .dir-list li input, .dir-list li label
                {
                    cursor: pointer;
                }
        #e-input, #e-list
        {
            display: block;
            background-color:#287EEB;
            color:#FFFFFF;
            font-size:24px;
            padding:5px 0;
            line-height:34px;
            text-align:center;
            cursor: pointer;
            margin-top:5px;
        }
            #e-input:hover, #e-list:hover, #e-input.selected, #e-list.selected
            {
                background-color:#009819;
            }


        #c-single, #c-list
        {
            padding: 10px;
            border:1px solid #009819;
        }

        #loader
        {
            display: none;
            position:absolute;
            left:0;
            top:0;
            z-index:999999;
            height:100%;
            width:100%;
            background-color:#287EEB;
            color:#ffffff;
            opacity:0.8;
        }
            #loader .loader-content
            {
                position:absolute;
                top:50%;
                left:48%;
            }
        .c-control
        {

        }
            .c-control a
            {
                cursor: pointer;
                color: blue;
                text-decoration: underline;
            }

    
    </style>
</head>
<body>        
    <div style="border: 1px solid #009819; padding: 5px;">  
        <h2 style=" margin: 5px 0">Options</h2>  
        <ul>
            <li>            
            <input type="checkbox" id="cbMandatory" name="cbMandatory" /> <label for="cbMandatory">Mandatory(takes longer)</label>
            </li>
        </ul>  
    </div>
    <a id="e-input" class="selected">Input</a>
    <div id="c-single">
        Distinct Name: <input type="text" id="txtDistinctName" /> <button id="btnPubSingle" data-handle="/Handler.ashx?type=git">Publish</button>
        <button id="combinedCSS_single" data-handle="/CimbineHandle.ashx">Combine CSS files</button>
    </div>
    
    <a  id="e-list">Select</a>
    <div id="c-list" style="display:none;">
        <div class="c-control">
        <a id="e-all">All</a> <a id="e-none">None</a>  <a id="e-invert">Invert</a>
            <button id="btnPubList" data-handle="/Handler.ashx?type=git">Publish</button>
            <button id="combinedCSS_multi" data-handle="/CimbineHandle.ashx">Combine CSS files</button>
        </div>
    <ul class="dir-list">
    <%= GetAllDirectoriesHtml() %>
    </ul>
        <div style="clear:both;"></div>
    </div>

    <div id="loader"><div class="loader-content"><img src="/image/loading.gif" width="150" height="150" /></div></div>
    
    <script type="text/javascript">
        $(function () {

            var json = <%=GetAllDirectoriesJson()%>;

            $('#txtDistinctName').autocomplete(json);

            $('#e-input').click(function () {
                $('#e-input').addClass('selected');
                $('#e-list').removeClass('selected');
                $('#c-single').slideDown();
                $('#c-list').slideUp();
            });

            $('#e-list').click(function () {
                $('#e-list').addClass('selected');
                $('#e-input').removeClass('selected');
                $('#c-list').slideDown();
                $('#c-single').slideUp();
            });

            $('input[name="subdir"]').change(function () {
                var $this = $(this);
                if ($this.prop('checked'))
                    $this.parents('li').addClass('selected');
                else
                    $this.parents('li').removeClass('selected');
            });

            $('#e-all').click(function () {
                $('#c-list input:checkbox').prop('checked', true);
                initCheckboxStatus();
            });

            $('#e-none').click(function () {
                $('#c-list input:checkbox').prop('checked', false);
                initCheckboxStatus();
            });

            $('#e-invert').click(function () {
                $('#c-list input:checkbox').each(function (i, n) {
                    $(n).prop('checked', !$(n).prop('checked'));
                });
                initCheckboxStatus();
            });

            function initCheckboxStatus(){
                $('#c-list input:checkbox').parents('li').removeClass('selected');
                $('#c-list input:checked').parents('li').addClass('selected');
            }

            $('#btnPubSingle,#combinedCSS_single').click(function (e) {
                if ($('#txtDistinctName').val().trim() == '')
                    alert('please type the distinct name');
                else
                {
                    post($('#txtDistinctName').val().trim(),$(this).data("handle"));
                }
            });

            $('#btnPubList,#combinedCSS_multi').click(function (e) {
                var dirs='';
                $('#c-list .dir-list input:checkbox').each(function (i, n) {
                    if ($(n).prop('checked'))
                    {
                        dirs += $(n).val()+',';
                    }
                });
                if(dirs == '')
                    alert('please select one item at least');
                else
                    post(dirs,$(this).data("handle"));
            });

            function post(str,handle)
            {
                loading(true);
                var _data = { target: str};
                if($('#cbMandatory').prop('checked'))
                {
                    _data.mandatory = true;
                }
                $.post(handle, _data, function (data) {
                    if (data.success)
                        alert('success');
                    else
                        alert(data.error);

                    loading(false);
                });
            }

            function loading(enable)
            {
                if (enable) {
                    $('#loader').show();
                }
                else {
                    $('#loader').hide();
                }
            }

            initCheckboxStatus();
        });
    </script>
</body>
</html>
