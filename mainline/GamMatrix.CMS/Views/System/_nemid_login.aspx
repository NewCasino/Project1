<%@ Page Language="C#" AutoEventWireup="true" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
    <style type="text/css">
        html, body { width:100%; height:100%; background-color: transparent; margin:0; padding:0;}
        body { overflow:hidden; }
        iframe { width: 100%; height:100%; overflow:hidden; background-color: transparent;}
        form { display: none }
    </style>
</head>
<body>
    <iframe id="ifmMain" name="ifmMain" frameborder="0" scrolling="no" allowTransparency="true" src="<%= Request.Form["url"] %>">
    </iframe>

    <form id="returnForm" target="_self" method="post" action="<%= Request.Form["returnUrl"] %>">
        <input type="hidden" id="hdSignature" name="signature" value="" />
    </form>

    <script type="text/nemid" id="nemid_parameters"><%= Request.Form["parameters"] %></script>

    <script type="text/javascript">
    function onNemIDMessage(e) {
        var event = e || event;
        var win = document.getElementById('ifmMain').contentWindow,
            postMessage = {},
            message;
        message = JSON.parse(event.data);

        if (event.origin.toLowerCase() !== '<%= Request.Form["origin"] %>') {
            window.alert('Received message from unexpected origin : ' + event.origin);
            return;
        }
        if (message.command === 'SendParameters') {
            postMessage.command = 'parameters';
            postMessage.content = document.getElementById('nemid_parameters').innerHTML;
            win.postMessage(JSON.stringify(postMessage), '<%= Request.Form["origin"] %>');
        }
        if (message.command === 'changeResponseAndSubmit') {
            document.getElementById('hdSignature').value = message.content;
            document.getElementById('returnForm').submit();
        }
    }

    if( !window.postMessage )
        alert('Your web browser is too old, please upgrade or try Chrome');
    if (window.addEventListener) {
        window.addEventListener('message', onNemIDMessage);
    } else if (window.attachEvent) {
        window.attachEvent('onmessage', onNemIDMessage);
    }
    </script>
</body>
</html>
