var g_sitemap =
{
    children:
    [
        {
            url: "/ContentMgt",
            title: "Content Management",
            description: "Edit the content of the selected site",
            icon: "/images/icon/layout_content.png", roles: "*", children: []
        },
        {
            url: "/OperatorMgt",
            title: "Operator Management",
            description: "Create/Maintance operators",
            icon: "/images/icon/application_view_tile.png",
            roles: "CMS System Admin", children: []
        },
        {
            url: "/DDOSRedirectionMgt",
            title: "DDOS Redirection Management",
            description: "Manage DDOS Redirection",
            icon: "/images/icon/application_view_tile.png",
            roles: "CMS System Admin", children: []
        },
        {
            url: "javascript:void(0)",
            title: "Tools",
            description: "",
            icon: "/images/icon/wrench_orange.png",
            roles: "CMS System Admin",
            children:
            [
                /*{
                    url: "/Monitor", title: "Monitor",
                    description: "System Monitor", icon: "/images/icon/chart_curve.png",
                    roles: "CMS System Admin",
                    children: []
                },
                {
                    url: "http://log.dev.everymatrix.com/", title: "LogViewer", target: "_blank",
                    description: "System Monitor", icon: "/images/icon/map_magnify.png",
                    roles: "CMS System Admin",
                    children: []
                },*/
                {
                    url: "/IDQCheck", title: "IDQCheck",
                    description: "System Monitor", icon: "/images/icon/map_magnify.png",
                    roles: "CMS System Admin",
                    children: []
                },
                {
                    url: "/Dashboard", title: "Dashboard",
                    description: "", icon: "/images/icon/application_view_detail.png",
                    roles: "CMS System Admin",
                    children: []
                }
            ]
        }
    ] 
};
