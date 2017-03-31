<%@ Control Language="C#" Inherits="CM.Web.ViewUserControlEx" %>

<div class="Aff_top">
<%= this.GetMetadata(".TopTitle") %>
</div>

<div class="topContentMain AffVedio">
    <div class="TopContentContainer">
        <a class="Button closeTopContent" href="javascript:void(0)" title="<%= this.GetMetadata(".CloseTitle") %>">
            <span class="ButtonIcon">&times;</span>
            <span class="ButtonText"><%= this.GetMetadata(".Close") %></span>
        </a>
        <ul class="topContentList">
            <li class="topContent_item">
                <div class="topContent_Container"><%= this.GetMetadata(".Vedio") %></div>
            </li>
        </ul>
    </div>
</div>