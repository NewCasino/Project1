/****** Object:  Table [dbo].[cmDomainConfigration]    Script Date: 05/10/2011 13:31:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sysobjects WHERE [type]='U' and [name]='cmSite')
CREATE TABLE [cmSite](
	[SiteID] [int] IDENTITY(2000,1) NOT NULL,
	[DomainID] [int] NULL,
	[DistinctName] [nvarchar](50) NOT NULL,
	[DisplayName] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[TemplateDomainDistinctName] [nvarchar](50) NULL,
	[DefaultTheme] [nvarchar](50) NULL,
	[DefaultUrl] [nvarchar](50) NOT NULL,
	[DefaultCulture] [nvarchar](50) NOT NULL,
	[HttpPort] [int] NOT NULL,
	[HttpsPort] [int] NOT NULL,
	[Ins] [smalldatetime] NOT NULL,
 CONSTRAINT [PK_cmSite] PRIMARY KEY CLUSTERED 
(
	[SiteID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'DF_cmSite_DefaultUrl') AND type = 'D')
ALTER TABLE [cmSite] ADD  CONSTRAINT [DF_cmSite_DefaultUrl]  DEFAULT (N'/Home') FOR [DefaultUrl]
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'DF_cmSite_DefaultCulture') AND type = 'D')
ALTER TABLE [cmSite] ADD  CONSTRAINT [DF_cmSite_DefaultCulture]  DEFAULT (N'en') FOR [DefaultCulture]
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'DF_Site_Ins') AND type = 'D')
ALTER TABLE [cmSite] ADD  CONSTRAINT [DF_Site_Ins]  DEFAULT (getdate()) FOR [Ins]
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'DF_cmSite_HttpPort') AND type = 'D')
ALTER TABLE [cmSite] ADD  CONSTRAINT [DF_cmSite_HttpPort]  DEFAULT (80) FOR [HttpPort]
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'DF_cmSite_HttpsPort') AND type = 'D')
ALTER TABLE [cmSite] ADD  CONSTRAINT [DF_cmSite_HttpsPort]  DEFAULT (0) FOR [HttpsPort]
GO


IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'cmSite') AND name = N'IDX_cmSite_DistinctName')
CREATE UNIQUE NONCLUSTERED INDEX [IDX_cmSite_DistinctName] ON [cmSite] 
(
	[DistinctName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO


IF NOT EXISTS (SELECT * FROM sysobjects WHERE [type]='U' and [name]='cmHost')
CREATE TABLE [cmHost](
	[HostID] [int] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NOT NULL,
	[HostName] [nvarchar](255) NOT NULL,
	[DefaultCulture] [nvarchar](50) NULL,
 CONSTRAINT [PK_cmHost] PRIMARY KEY CLUSTERED 
(
	[HostID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'cmHost') AND name = N'IDX_cmHost_HostName')
CREATE UNIQUE NONCLUSTERED INDEX [IDX_cmHost_HostName] ON [dbo].[cmHost] 
(
	[HostName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO



IF NOT EXISTS (SELECT * FROM sysobjects WHERE [type]='U' and [name]='cmRevision')
CREATE TABLE [dbo].[cmRevision](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Ins] [datetime] NOT NULL CONSTRAINT [DF_cmRevision_Ins]  DEFAULT (getdate()),
	[UserID] [int] NOT NULL CONSTRAINT [DF_cmRevision_UserID]  DEFAULT ((0)),
	[SiteID] [int] NOT NULL,
	[RelativePath] [nvarchar](2048) NOT NULL,
	[Comments] [nvarchar](2048) NOT NULL,
	[FilePath] [nvarchar](2048) NULL,
 CONSTRAINT [PK_cmRevision] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sysobjects WHERE [type]='U' and [name]='cmSessionValue')
CREATE TABLE [dbo].[cmSessionValue](
	[SessionGuid] [varchar](36) NOT NULL,
	[SessionName] [nvarchar](255) NOT NULL,
	[SessionValue] [nvarchar](4000) NULL,
	[Ins] [datetime] NOT NULL,
 CONSTRAINT [PK_cmSessionValue] PRIMARY KEY CLUSTERED 
(
	[SessionGuid] ASC,
	[SessionName] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO


IF NOT EXISTS (SELECT * FROM syscolumns WHERE [id] = (SELECT id FROM sysobjects WHERE [type]='U' AND [name]='cmLog') AND [name] = 'MachineName')
ALTER TABLE cmLog ADD  MachineName NVARCHAR(255) NULL
GO

IF NOT EXISTS (SELECT * FROM syscolumns WHERE [id] = (SELECT id FROM sysobjects WHERE [type]='U' AND [name]='cmDomain') AND [name] = 'ApiUsername')
ALTER TABLE cmDomain ADD  ApiUsername NVARCHAR(255) NULL
GO

ALTER TABLE cmTransParameter ALTER COLUMN ParameterValue NVARCHAR(max) NULL
GO

-- 数据初始化
--------------------------------------


DELETE FROM cmDomain WHERE ID > 1
GO
 SET IDENTITY_INSERT [cmDomain] ON
GO
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 13 , 1 , 0 , '2009-08-12 10:23:02.407' , 0 , 'GammatrixDemo' , 0 , 'gammatrixGUIDTest' , 'demo1.gammatrix.com' , 133 , 1 , 'GmDemo' , 'gammatrix.com' , 'Hellenic' , 'gammatrix.com' , 'en' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 18 , 1 , 0 , '2009-11-02 10:42:23.313' , 0 , 'BetExpress' , 0 , 'cmSession' , 'demo1.gammatrix.com' , 1701 , 1 , 'f03ee567-a0a1-472c-8db3-c039a419084c' , 'BetExpress.com' , 'BetExpress' , 'demo1.gammatrix.com' , 'en' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 21 , 1 , 0 , '2010-01-07 11:18:09.173' , 0 , 'BetWize.com' , 0 , 'cmSession' , '' , 435 , 1 , '9a68f0f1-f23d-4b64-8b2a-5a5de527562a' , 'betwize.com' , 'BetWize' , 'betwize.gammatrix-dev.net' , 'en' , 'http://sports.betwize.gammatrix-dev.net:8080/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 23 , 1 , 0 , '2010-01-21 04:04:23.780' , 0 , 'Guts.com' , 0 , 'cmSession' , '' , 591 , 1 , '9cc27c43-1592-4c59-8165-5d6bc30068f8' , 'Guts.com' , 'Guts' , 'guts.gammatrix-dev.net' , 'en' , 'http://sports.guts.gammatrix-dev.net/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , 'http://m.guts.com' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 24 , 1 , 0 , '2010-03-31 07:24:33.170' , 0 , 'Jetbull.com' , 0 , 'cmSession' , '' , 1084 , 1 , '61b19466-5d82-41ce-8f51-ef2281324789' , 'Jetbull.com' , 'Jetbull' , 'jetbull.gammatrix-dev.net' , 'en' , 'http://sports.jetbull.gammatrix-dev.net:8080/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 26 , 1 , 0 , '2010-04-06 05:47:38.843' , 0 , 'In2Win.com' , 0 , 'cmSession' , '' , 1176 , 1 , '6cc503fb27f346feb17' , 'in2win.com' , 'In2Win' , 'in2win.gammatrix-dev.net' , 'en' , 'http://sports.in2win.gammatrix-dev.net/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 29 , 1 , 0 , '2010-04-07 08:05:59.717' , 0 , 'BetConvivia.com' , 0 , 'cmSession' , '' , 1201 , 1 , 'b5f3a952-1a6d-467f-b525-d3061dd83d80' , 'BetConvivia.com' , 'BetConvivia' , 'bbia.gammatrix-dev.net' , 'sr' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 31 , 1 , 0 , '2010-06-30 02:14:17.257' , 0 , 'NouBet.com' , 0 , 'cmSession' , '' , 3884 , 1 , 'e46ffd3b65d0411fb28' , 'noubet.com' , 'NouBet' , 'noubet.gammatrix-dev.net' , 'es' , 'http://sports2.noubet.gammatrix-dev.net/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 32 , 1 , 0 , '2010-08-22 22:32:05.080' , 0 , 'GaymingCasino.com' , 0 , 'cmSession' , '' , 5000 , 1 , '1a09db29f2174424a18' , 'Gayming.com' , 'Gayming' , 'gayming.gammatrix-dev.net' , 'en' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 36 , 1 , 0 , '2010-10-21 01:06:43.097' , 0 , 'CasinoLuck.com' , 0 , 'cmSession' , '' , 7239 , 1 , '38802d7be3e24904bcd' , 'CasinoLuck.com' , 'CasinoLuck' , 'casinoluck.gammatrix-dev.net' , 'en' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 37 , 1 , 0 , '2010-10-21 22:56:44.497' , 0 , 'KeyZone' , 0 , 'cmSession' , '' , 7460 , 1 , '4f973ed71aad42dd94f' , 'KeyZone.com' , 'KeyZone' , 'keyzone.gammatrix-dev.net' , 'en' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 38 , 1 , 0 , '2010-11-04 22:55:09.127' , 0 , 'Boraboracasino.com' , 0 , 'cmSession' , '' , 7589 , 1 , 'a235fe1b31ac45eba74' , 'BoraboraCasino.com' , 'BoraboraCasino' , 'boraboracasino.gammatrix-dev.net' , 'nl' , '' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [ApiUsername] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 39 , 1 , 0 , '2010-11-15 23:34:05.337' , 0 , 'BoogieBet.com' , 0 , 'cmSession' , '' , 7897 , 1 , 'aba83f1b0d0a45c499b' , 'BoogieBet.com' , 'BoogieBet' , 'BoogieBet.gammatrix-dev.net' , 'en' , 'http://sports.boogiebet.gammatrix-dev.net/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '_Api_Cms' , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 40 , 1 , 0 , '2010-12-29 03:16:40.710' , 0 , 'EuroSuperPoker.com' , 0 , 'cmSession' , '' , 8409 , 1 , '67f3a6408a3d4b2fbe5' , 'eurosuperpoker.gammatrix-dev.net' , 'EuroSuperPoker' , 'eurosuperpoker.gammatrix-dev.net' , 'en' , '' , 1 , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 41 , 1 , 0 , '2011-02-27 22:48:36.137' , 0 , 'EyBet.com' , 0 , 'cmSession' , '' , 9745 , 1 , 'db020430922a4bffbb9' , 'EyBet.com' , 'EyBet' , 'Eybet.gammatrix-dev.net' , 'en' , 'http://sports.eybet.gammatrix-dev.net/partnerapi1/customerLogout.do?currentSession={0}&username={1}' , 1 , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 42 , 1 , 0 , '2011-03-07 03:59:35.353' , 0 , 'NogaBet.com' , 0 , 'cmSession' , '' , 9986 , 1 , '46239575b60041bcb98' , 'nogabet.gammatrix-dev.net' , 'nogabet' , 'nogabet.gammatrix-dev.net' , 'en' , '' , 1 , '' )
 INSERT [cmDomain] ( [Dsc] , [UserID] , [PasswordEncryptionMode] , [ID] , [DomainID] , [FolderID] , [Ins] , [IsDeleted] , [Title] , [IsMultiDomain] , [SessionCookieName] , [Hosts] , [ArtID] , [IsExported] , [SecurityToken] , [EmailHost] , [DistinctName] , [SessionCookieDomain] , [DefaultLanguage] , [LogoffNotificationUrl] , [IsLiveMode] , [MobileSiteUrl] ) VALUES ( '' , 0 , 0 , 43 , 1 , 0 , '2011-05-09 11:42:31.673' , 0 , 'StarVenusCasino.com' , 0 , 'cmSession' , '' , 10863 , 1 , '8f757ab5a6e24bf1afa' , 'starvenuscasino.gammatrix-dev.net' , 'StarVenusCasino' , 'starvenuscasino.com' , 'en' , '' , 1 , '' )


 SET IDENTITY_INSERT [cmDomain] OFF
GO

SET IDENTITY_INSERT cmSite ON
GO
INSERT INTO [cmSite]
           ([SiteID]
           ,[DomainID]
           ,[DistinctName]
           ,[DisplayName]
           ,[Description]
           ,[TemplateDomainDistinctName]
           ,[DefaultTheme]
           ,[DefaultUrl]
           ,[DefaultCulture]
           ,[Ins])
     VALUES
           (1
           ,1
           ,'System'
           ,'CMS Console'
           ,'CMS Console'
           ,''
           ,'AdminConsole'
           ,'/SignIn'
           ,'en'
           ,GETDATE()
           )
GO 
SET IDENTITY_INSERT cmSite OFF
GO

INSERT INTO [cmSite]
           ([DomainID]
           ,[DistinctName]
           ,[DisplayName]
           ,[Description]
           ,[TemplateDomainDistinctName]
           ,[DefaultTheme]
           ,[DefaultUrl]
           ,[DefaultCulture]
           ,[Ins])
     VALUES
           (1
           ,'Shared'
           ,'Shared Template'
           ,'Shared Template'
           ,''
           ,''
           ,'/'
           ,'en'
           ,GETDATE()
           )
GO 


INSERT INTO [cmHost]
           ([SiteID]
           ,[HostName]
           ,[DefaultCulture])
     VALUES
           (1
           ,'localhost'
           ,'en'
           )
GO



-- DEV server
UPDATE cmDomain SET SecurityToken = N'f03ee567-a0a1-472c-8db3-c039a419084c' WHERE [Title] = 'BetExpress'


UPDATE cmDomain SET [ApiUsername] = '_Api_Cms'
GO

-- FOR LOCAL AND DEV ONLY!!
UPDATE cmDomain SET [ApiUsername] = 'sa' WHERE [ID] = 1
UPDATE cmDomain SET [SecurityToken]=N'ad59638d-8972-4e54-a234-ad914f7fc137' WHERE [ID] = 1
GO