using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.Serialization.Formatters.Binary;
using System.Web;
using System.Web.Caching;
using System.Web.Hosting;
using System.Web.Routing;
using BLToolkit.DataAccess;
using CM.Content;
using CM.db;
using CM.Sites;
using GamMatrix.Infrastructure;

/// <summary>
/// Summary description for CountryManager
/// </summary>
public static class CountryManager
{

    /// <summary>
    /// Get all the countries
    /// </summary>
    /// <param name="domainDistinctName">optional</param>
    /// <returns></returns>
    public static List<CountryInfo> GetAllCountries(string domainDistinctName = null)
    {
        if( string.IsNullOrEmpty(domainDistinctName) )
            domainDistinctName = SiteManager.Current.DistinctName;

        string cacheKey = string.Format("site_all_countries_{0}", domainDistinctName);
        List<CountryInfo> countries = HttpRuntime.Cache[cacheKey] as List<CountryInfo>;
        if (countries != null)
            return countries;

        lock(typeof(CountryManager))
        {
            countries = HttpRuntime.Cache[cacheKey] as List<CountryInfo>;
            if (countries != null)
                return countries;

            countries = new List<CountryInfo>();

            #region initialize the countries
            /*
DECLARE @table TABLE
(
ISO_Code INT,
ISO_3166_Name NVARCHAR(255), 
ISO_3166_Alpha2Code CHAR(2), 
ISO_3166_Alpha3Code CHAR(3), 
EnglishName NVARCHAR(255),
CurrencyCode NVARCHAR(3)
)

INSERT INTO @table (ISO_3166_Alpha2Code, ISO_3166_Name, EnglishName, ISO_3166_Alpha3Code, ISO_Code) VALUES
('AF', 'AFGHANISTAN', 'Afghanistan', 'AFG', 4),
('AL', 'ALBANIA', 'Albania', 'ALB', 8),
('DZ', 'ALGERIA', 'Algeria', 'DZA', 12),
('AS', 'AMERICAN SAMOA', 'American Samoa', 'ASM', 16),
('AD', 'ANDORRA', 'Andorra', 'AND', 20),
('AO', 'ANGOLA', 'Angola', 'AGO', 24),
('AI', 'ANGUILLA', 'Anguilla', 'AIA', 660),
('AQ', 'ANTARCTICA', 'Antarctica', NULL, NULL),
('AG', 'ANTIGUA AND BARBUDA', 'Antigua and Barbuda', 'ATG', 28),
('AR', 'ARGENTINA', 'Argentina', 'ARG', 32),
('AM', 'ARMENIA', 'Armenia', 'ARM', 51),
('AW', 'ARUBA', 'Aruba', 'ABW', 533),
('AU', 'AUSTRALIA', 'Australia', 'AUS', 36),
('AT', 'AUSTRIA', 'Austria', 'AUT', 40),
('AZ', 'AZERBAIJAN', 'Azerbaijan', 'AZE', 31),
('BS', 'BAHAMAS', 'Bahamas', 'BHS', 44),
('BH', 'BAHRAIN', 'Bahrain', 'BHR', 48),
('BD', 'BANGLADESH', 'Bangladesh', 'BGD', 50),
('BB', 'BARBADOS', 'Barbados', 'BRB', 52),
('BY', 'BELARUS', 'Belarus', 'BLR', 112),
('BE', 'BELGIUM', 'Belgium', 'BEL', 56),
('BZ', 'BELIZE', 'Belize', 'BLZ', 84),
('BJ', 'BENIN', 'Benin', 'BEN', 204),
('BM', 'BERMUDA', 'Bermuda', 'BMU', 60),
('BT', 'BHUTAN', 'Bhutan', 'BTN', 64),
('BO', 'BOLIVIA', 'Bolivia', 'BOL', 68),
('BA', 'BOSNIA AND HERZEGOVINA', 'Bosnia and Herzegovina', 'BIH', 70),
('BW', 'BOTSWANA', 'Botswana', 'BWA', 72),
('BV', 'BOUVET ISLAND', 'Bouvet Island', NULL, NULL),
('BR', 'BRAZIL', 'Brazil', 'BRA', 76),
('IO', 'BRITISH INDIAN OCEAN TERRITORY', 'British Indian Ocean Territory', NULL, NULL),
('BN', 'BRUNEI DARUSSALAM', 'Brunei Darussalam', 'BRN', 96),
('BG', 'BULGARIA', 'Bulgaria', 'BGR', 100),
('BF', 'BURKINA FASO', 'Burkina Faso', 'BFA', 854),
('BI', 'BURUNDI', 'Burundi', 'BDI', 108),
('KH', 'CAMBODIA', 'Cambodia', 'KHM', 116),
('CM', 'CAMEROON', 'Cameroon', 'CMR', 120),
('CA', 'CANADA', 'Canada', 'CAN', 124),
('CV', 'CAPE VERDE', 'Cape Verde', 'CPV', 132),
('KY', 'CAYMAN ISLANDS', 'Cayman Islands', 'CYM', 136),
('CF', 'CENTRAL AFRICAN REPUBLIC', 'Central African Republic', 'CAF', 140),
('TD', 'CHAD', 'Chad', 'TCD', 148),
('CL', 'CHILE', 'Chile', 'CHL', 152),
('CN', 'CHINA', 'China', 'CHN', 156),
('CX', 'CHRISTMAS ISLAND', 'Christmas Island', NULL, NULL),
('CC', 'COCOS (KEELING) ISLANDS', 'Cocos (Keeling) Islands', NULL, NULL),
('CO', 'COLOMBIA', 'Colombia', 'COL', 170),
('KM', 'COMOROS', 'Comoros', 'COM', 174),
('CG', 'CONGO', 'Congo', 'COG', 178),
('CD', 'CONGO, THE DEMOCRATIC REPUBLIC OF THE', 'Congo, the Democratic Republic of the', 'COD', 180),
('CK', 'COOK ISLANDS', 'Cook Islands', 'COK', 184),
('CR', 'COSTA RICA', 'Costa Rica', 'CRI', 188),
('CI', 'COTE D''IVOIRE', 'Cote D''Ivoire', 'CIV', 384),
('HR', 'CROATIA', 'Croatia', 'HRV', 191),
('CU', 'CUBA', 'Cuba', 'CUB', 192),
('CY', 'CYPRUS', 'Cyprus', 'CYP', 196),
('CZ', 'CZECH REPUBLIC', 'Czech Republic', 'CZE', 203),
('DK', 'DENMARK', 'Denmark', 'DNK', 208),
('DJ', 'DJIBOUTI', 'Djibouti', 'DJI', 262),
('DM', 'DOMINICA', 'Dominica', 'DMA', 212),
('DO', 'DOMINICAN REPUBLIC', 'Dominican Republic', 'DOM', 214),
('EC', 'ECUADOR', 'Ecuador', 'ECU', 218),
('EG', 'EGYPT', 'Egypt', 'EGY', 818),
('SV', 'EL SALVADOR', 'El Salvador', 'SLV', 222),
('GQ', 'EQUATORIAL GUINEA', 'Equatorial Guinea', 'GNQ', 226),
('ER', 'ERITREA', 'Eritrea', 'ERI', 232),
('EE', 'ESTONIA', 'Estonia', 'EST', 233),
('ET', 'ETHIOPIA', 'Ethiopia', 'ETH', 231),
('FK', 'FALKLAND ISLANDS (MALVINAS)', 'Falkland Islands (Malvinas)', 'FLK', 238),
('FO', 'FAROE ISLANDS', 'Faroe Islands', 'FRO', 234),
('FJ', 'FIJI', 'Fiji', 'FJI', 242),
('FI', 'FINLAND', 'Finland', 'FIN', 246),
('FR', 'FRANCE', 'France', 'FRA', 250),
('GF', 'FRENCH GUIANA', 'French Guiana', 'GUF', 254),
('PF', 'FRENCH POLYNESIA', 'French Polynesia', 'PYF', 258),
('TF', 'FRENCH SOUTHERN TERRITORIES', 'French Southern Territories', NULL, NULL),
('GA', 'GABON', 'Gabon', 'GAB', 266),
('GM', 'GAMBIA', 'Gambia', 'GMB', 270),
('GE', 'GEORGIA', 'Georgia', 'GEO', 268),
('DE', 'GERMANY', 'Germany', 'DEU', 276),
('GH', 'GHANA', 'Ghana', 'GHA', 288),
('GI', 'GIBRALTAR', 'Gibraltar', 'GIB', 292),
('GR', 'GREECE', 'Greece', 'GRC', 300),
('GL', 'GREENLAND', 'Greenland', 'GRL', 304),
('GD', 'GRENADA', 'Grenada', 'GRD', 308),
('GP', 'GUADELOUPE', 'Guadeloupe', 'GLP', 312),
('GU', 'GUAM', 'Guam', 'GUM', 316),
('GT', 'GUATEMALA', 'Guatemala', 'GTM', 320),
('GN', 'GUINEA', 'Guinea', 'GIN', 324),
('GW', 'GUINEA-BISSAU', 'Guinea-Bissau', 'GNB', 624),
('GY', 'GUYANA', 'Guyana', 'GUY', 328),
('HT', 'HAITI', 'Haiti', 'HTI', 332),
('HM', 'HEARD ISLAND AND MCDONALD ISLANDS', 'Heard Island and Mcdonald Islands', NULL, NULL),
('VA', 'HOLY SEE (VATICAN CITY STATE)', 'Holy See (Vatican City State)', 'VAT', 336),
('HN', 'HONDURAS', 'Honduras', 'HND', 340),
('HK', 'HONG KONG', 'Hong Kong', 'HKG', 344),
('HU', 'HUNGARY', 'Hungary', 'HUN', 348),
('IS', 'ICELAND', 'Iceland', 'ISL', 352),
('IN', 'INDIA', 'India', 'IND', 356),
('ID', 'INDONESIA', 'Indonesia', 'IDN', 360),
('IR', 'IRAN, ISLAMIC REPUBLIC OF', 'Iran, Islamic Republic of', 'IRN', 364),
('IQ', 'IRAQ', 'Iraq', 'IRQ', 368),
('IE', 'IRELAND', 'Ireland', 'IRL', 372),
('IL', 'ISRAEL', 'Israel', 'ISR', 376),
('IT', 'ITALY', 'Italy', 'ITA', 380),
('JM', 'JAMAICA', 'Jamaica', 'JAM', 388),
('JP', 'JAPAN', 'Japan', 'JPN', 392),
('JO', 'JORDAN', 'Jordan', 'JOR', 400),
('KZ', 'KAZAKHSTAN', 'Kazakhstan', 'KAZ', 398),
('KE', 'KENYA', 'Kenya', 'KEN', 404),
('KI', 'KIRIBATI', 'Kiribati', 'KIR', 296),
('KP', 'KOREA, DEMOCRATIC PEOPLE''S REPUBLIC OF', 'Korea, Democratic People''s Republic of', 'PRK', 408),
('KR', 'KOREA, REPUBLIC OF', 'Korea, Republic of', 'KOR', 410),
('KW', 'KUWAIT', 'Kuwait', 'KWT', 414),
('KG', 'KYRGYZSTAN', 'Kyrgyzstan', 'KGZ', 417),
('LA', 'LAO PEOPLE''S DEMOCRATIC REPUBLIC', 'Lao People''s Democratic Republic', 'LAO', 418),
('LV', 'LATVIA', 'Latvia', 'LVA', 428),
('LB', 'LEBANON', 'Lebanon', 'LBN', 422),
('LS', 'LESOTHO', 'Lesotho', 'LSO', 426),
('LR', 'LIBERIA', 'Liberia', 'LBR', 430),
('LY', 'LIBYAN ARAB JAMAHIRIYA', 'Libyan Arab Jamahiriya', 'LBY', 434),
('LI', 'LIECHTENSTEIN', 'Liechtenstein', 'LIE', 438),
('LT', 'LITHUANIA', 'Lithuania', 'LTU', 440),
('LU', 'LUXEMBOURG', 'Luxembourg', 'LUX', 442),
('MO', 'MACAO', 'Macao', 'MAC', 446),
('MK', 'MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF', 'Macedonia, the Former Yugoslav Republic of', 'MKD', 807),
('MG', 'MADAGASCAR', 'Madagascar', 'MDG', 450),
('MW', 'MALAWI', 'Malawi', 'MWI', 454),
('MY', 'MALAYSIA', 'Malaysia', 'MYS', 458),
('MV', 'MALDIVES', 'Maldives', 'MDV', 462),
('ML', 'MALI', 'Mali', 'MLI', 466),
('MT', 'MALTA', 'Malta', 'MLT', 470),
('MH', 'MARSHALL ISLANDS', 'Marshall Islands', 'MHL', 584),
('MQ', 'MARTINIQUE', 'Martinique', 'MTQ', 474),
('MR', 'MAURITANIA', 'Mauritania', 'MRT', 478),
('MU', 'MAURITIUS', 'Mauritius', 'MUS', 480),
('YT', 'MAYOTTE', 'Mayotte', NULL, NULL),
('MX', 'MEXICO', 'Mexico', 'MEX', 484),
('FM', 'MICRONESIA, FEDERATED STATES OF', 'Micronesia, Federated States of', 'FSM', 583),
('MD', 'MOLDOVA, REPUBLIC OF', 'Moldova, Republic of', 'MDA', 498),
('MC', 'MONACO', 'Monaco', 'MCO', 492),
('MN', 'MONGOLIA', 'Mongolia', 'MNG', 496),
('MS', 'MONTSERRAT', 'Montserrat', 'MSR', 500),
('MA', 'MOROCCO', 'Morocco', 'MAR', 504),
('MZ', 'MOZAMBIQUE', 'Mozambique', 'MOZ', 508),
('MM', 'MYANMAR', 'Myanmar', 'MMR', 104),
('NA', 'NAMIBIA', 'Namibia', 'NAM', 516),
('NR', 'NAURU', 'Nauru', 'NRU', 520),
('NP', 'NEPAL', 'Nepal', 'NPL', 524),
('NL', 'NETHERLANDS', 'Netherlands', 'NLD', 528),
('AN', 'NETHERLANDS ANTILLES', 'Netherlands Antilles', 'ANT', 530),
('NC', 'NEW CALEDONIA', 'New Caledonia', 'NCL', 540),
('NZ', 'NEW ZEALAND', 'New Zealand', 'NZL', 554),
('NI', 'NICARAGUA', 'Nicaragua', 'NIC', 558),
('NE', 'NIGER', 'Niger', 'NER', 562),
('NG', 'NIGERIA', 'Nigeria', 'NGA', 566),
('NU', 'NIUE', 'Niue', 'NIU', 570),
('NF', 'NORFOLK ISLAND', 'Norfolk Island', 'NFK', 574),
('MP', 'NORTHERN MARIANA ISLANDS', 'Northern Mariana Islands', 'MNP', 580),
('NO', 'NORWAY', 'Norway', 'NOR', 578),
('OM', 'OMAN', 'Oman', 'OMN', 512),
('PK', 'PAKISTAN', 'Pakistan', 'PAK', 586),
('PW', 'PALAU', 'Palau', 'PLW', 585),
('PS', 'PALESTINIAN TERRITORY, OCCUPIED', 'Palestinian Territory, Occupied', NULL, NULL),
('PA', 'PANAMA', 'Panama', 'PAN', 591),
('PG', 'PAPUA NEW GUINEA', 'Papua New Guinea', 'PNG', 598),
('PY', 'PARAGUAY', 'Paraguay', 'PRY', 600),
('PE', 'PERU', 'Peru', 'PER', 604),
('PH', 'PHILIPPINES', 'Philippines', 'PHL', 608),
('PN', 'PITCAIRN', 'Pitcairn', 'PCN', 612),
('PL', 'POLAND', 'Poland', 'POL', 616),
('PT', 'PORTUGAL', 'Portugal', 'PRT', 620),
('PR', 'PUERTO RICO', 'Puerto Rico', 'PRI', 630),
('QA', 'QATAR', 'Qatar', 'QAT', 634),
('RE', 'REUNION', 'Reunion', 'REU', 638),
('RO', 'ROMANIA', 'Romania', 'ROM', 642),
('RU', 'RUSSIAN FEDERATION', 'Russian Federation', 'RUS', 643),
('RW', 'RWANDA', 'Rwanda', 'RWA', 646),
('SH', 'SAINT HELENA', 'Saint Helena', 'SHN', 654),
('KN', 'SAINT KITTS AND NEVIS', 'Saint Kitts and Nevis', 'KNA', 659),
('LC', 'SAINT LUCIA', 'Saint Lucia', 'LCA', 662),
('PM', 'SAINT PIERRE AND MIQUELON', 'Saint Pierre and Miquelon', 'SPM', 666),
('VC', 'SAINT VINCENT AND THE GRENADINES', 'Saint Vincent and the Grenadines', 'VCT', 670),
('WS', 'SAMOA', 'Samoa', 'WSM', 882),
('SM', 'SAN MARINO', 'San Marino', 'SMR', 674),
('ST', 'SAO TOME AND PRINCIPE', 'Sao Tome and Principe', 'STP', 678),
('SA', 'SAUDI ARABIA', 'Saudi Arabia', 'SAU', 682),
('SN', 'SENEGAL', 'Senegal', 'SEN', 686),
('CS', 'SERBIA AND MONTENEGRO', 'Serbia and Montenegro', NULL, NULL),
('SC', 'SEYCHELLES', 'Seychelles', 'SYC', 690),
('SL', 'SIERRA LEONE', 'Sierra Leone', 'SLE', 694),
('SG', 'SINGAPORE', 'Singapore', 'SGP', 702),
('SK', 'SLOVAKIA', 'Slovakia', 'SVK', 703),
('SI', 'SLOVENIA', 'Slovenia', 'SVN', 705),
('SB', 'SOLOMON ISLANDS', 'Solomon Islands', 'SLB', 90),
('SO', 'SOMALIA', 'Somalia', 'SOM', 706),
('ZA', 'SOUTH AFRICA', 'South Africa', 'ZAF', 710),
('GS', 'SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS', 'South Georgia and the South Sandwich Islands', NULL, NULL),
('ES', 'SPAIN', 'Spain', 'ESP', 724),
('LK', 'SRI LANKA', 'Sri Lanka', 'LKA', 144),
('SD', 'SUDAN', 'Sudan', 'SDN', 736),
('SR', 'SURINAME', 'Suriname', 'SUR', 740),
('SJ', 'SVALBARD AND JAN MAYEN', 'Svalbard and Jan Mayen', 'SJM', 744),
('SZ', 'SWAZILAND', 'Swaziland', 'SWZ', 748),
('SE', 'SWEDEN', 'Sweden', 'SWE', 752),
('CH', 'SWITZERLAND', 'Switzerland', 'CHE', 756),
('SY', 'SYRIAN ARAB REPUBLIC', 'Syrian Arab Republic', 'SYR', 760),
('TW', 'TAIWAN, PROVINCE OF CHINA', 'Taiwan, Province of China', 'TWN', 158),
('TJ', 'TAJIKISTAN', 'Tajikistan', 'TJK', 762),
('TZ', 'TANZANIA, UNITED REPUBLIC OF', 'Tanzania, United Republic of', 'TZA', 834),
('TH', 'THAILAND', 'Thailand', 'THA', 764),
('TL', 'TIMOR-LESTE', 'Timor-Leste', NULL, NULL),
('TG', 'TOGO', 'Togo', 'TGO', 768),
('TK', 'TOKELAU', 'Tokelau', 'TKL', 772),
('TO', 'TONGA', 'Tonga', 'TON', 776),
('TT', 'TRINIDAD AND TOBAGO', 'Trinidad and Tobago', 'TTO', 780),
('TN', 'TUNISIA', 'Tunisia', 'TUN', 788),
('TR', 'TURKEY', 'Turkey', 'TUR', 792),
('TM', 'TURKMENISTAN', 'Turkmenistan', 'TKM', 795),
('TC', 'TURKS AND CAICOS ISLANDS', 'Turks and Caicos Islands', 'TCA', 796),
('TV', 'TUVALU', 'Tuvalu', 'TUV', 798),
('UG', 'UGANDA', 'Uganda', 'UGA', 800),
('UA', 'UKRAINE', 'Ukraine', 'UKR', 804),
('AE', 'UNITED ARAB EMIRATES', 'United Arab Emirates', 'ARE', 784),
('GB', 'UNITED KINGDOM', 'United Kingdom', 'GBR', 826),
('US', 'UNITED STATES', 'United States', 'USA', 840),
('UM', 'UNITED STATES MINOR OUTLYING ISLANDS', 'United States Minor Outlying Islands', NULL, NULL),
('UY', 'URUGUAY', 'Uruguay', 'URY', 858),
('UZ', 'UZBEKISTAN', 'Uzbekistan', 'UZB', 860),
('VU', 'VANUATU', 'Vanuatu', 'VUT', 548),
('VE', 'VENEZUELA', 'Venezuela', 'VEN', 862),
('VN', 'VIET NAM', 'Viet Nam', 'VNM', 704),
('VG', 'VIRGIN ISLANDS, BRITISH', 'Virgin Islands, British', 'VGB', 92),
('VI', 'VIRGIN ISLANDS, U.S.', 'Virgin Islands, U.s.', 'VIR', 850),
('WF', 'WALLIS AND FUTUNA', 'Wallis and Futuna', 'WLF', 876),
('EH', 'WESTERN SAHARA', 'Western Sahara', 'ESH', 732),
('YE', 'YEMEN', 'Yemen', 'YEM', 887),
('ZM', 'ZAMBIA', 'Zambia', 'ZMB', 894),
('ZW', 'ZIMBABWE', 'Zimbabwe', 'ZWE', 716);

UPDATE @table SET [CurrencyCode] = 'AFA' WHERE ISO_3166_Alpha2Code = 'AF'
UPDATE @table SET [CurrencyCode] = 'ALL' WHERE ISO_3166_Alpha2Code = 'AL'
UPDATE @table SET [CurrencyCode] = 'DZD' WHERE ISO_3166_Alpha2Code = 'DZ'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'AS'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'AD'
UPDATE @table SET [CurrencyCode] = 'AOK' WHERE ISO_3166_Alpha2Code = 'AO'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'AI'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'AG'
UPDATE @table SET [CurrencyCode] = 'ARP' WHERE ISO_3166_Alpha2Code = 'AR'
UPDATE @table SET [CurrencyCode] = 'AMD' WHERE ISO_3166_Alpha2Code = 'AM'
UPDATE @table SET [CurrencyCode] = 'ANG' WHERE ISO_3166_Alpha2Code = 'AW'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'AU'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'AT'
UPDATE @table SET [CurrencyCode] = 'AZM' WHERE ISO_3166_Alpha2Code = 'AZ'
UPDATE @table SET [CurrencyCode] = 'BSD' WHERE ISO_3166_Alpha2Code = 'BS'
UPDATE @table SET [CurrencyCode] = 'BHD' WHERE ISO_3166_Alpha2Code = 'BH'
UPDATE @table SET [CurrencyCode] = 'BDT' WHERE ISO_3166_Alpha2Code = 'BD'
UPDATE @table SET [CurrencyCode] = 'BBD' WHERE ISO_3166_Alpha2Code = 'BB'
UPDATE @table SET [CurrencyCode] = 'BYR' WHERE ISO_3166_Alpha2Code = 'BY'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'BE'
UPDATE @table SET [CurrencyCode] = 'BZD' WHERE ISO_3166_Alpha2Code = 'BZ'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'BJ'
UPDATE @table SET [CurrencyCode] = 'BMD' WHERE ISO_3166_Alpha2Code = 'BM'
UPDATE @table SET [CurrencyCode] = 'INR' WHERE ISO_3166_Alpha2Code = 'BT'
UPDATE @table SET [CurrencyCode] = 'BOB' WHERE ISO_3166_Alpha2Code = 'BO'
UPDATE @table SET [CurrencyCode] = 'BAK' WHERE ISO_3166_Alpha2Code = 'BA'
UPDATE @table SET [CurrencyCode] = 'BWP' WHERE ISO_3166_Alpha2Code = 'BW'
UPDATE @table SET [CurrencyCode] = 'NOK' WHERE ISO_3166_Alpha2Code = 'BV'
UPDATE @table SET [CurrencyCode] = 'BRR' WHERE ISO_3166_Alpha2Code = 'BR'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'IO'
UPDATE @table SET [CurrencyCode] = 'BND' WHERE ISO_3166_Alpha2Code = 'BN'
UPDATE @table SET [CurrencyCode] = 'BGL' WHERE ISO_3166_Alpha2Code = 'BG'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'BF'
UPDATE @table SET [CurrencyCode] = 'BIF' WHERE ISO_3166_Alpha2Code = 'BI'
UPDATE @table SET [CurrencyCode] = 'KHR' WHERE ISO_3166_Alpha2Code = 'KH'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'CM'
UPDATE @table SET [CurrencyCode] = 'CAD' WHERE ISO_3166_Alpha2Code = 'CA'
UPDATE @table SET [CurrencyCode] = 'CVE' WHERE ISO_3166_Alpha2Code = 'CV'
UPDATE @table SET [CurrencyCode] = 'KYD' WHERE ISO_3166_Alpha2Code = 'KY'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'CF'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'TD'
UPDATE @table SET [CurrencyCode] = 'CLP' WHERE ISO_3166_Alpha2Code = 'CL'
UPDATE @table SET [CurrencyCode] = 'CNY' WHERE ISO_3166_Alpha2Code = 'CN'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'CX'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'CC'
UPDATE @table SET [CurrencyCode] = 'COP' WHERE ISO_3166_Alpha2Code = 'CO'
UPDATE @table SET [CurrencyCode] = 'KMF' WHERE ISO_3166_Alpha2Code = 'KM'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'CG'
UPDATE @table SET [CurrencyCode] = 'CDF' WHERE ISO_3166_Alpha2Code = 'CD'
UPDATE @table SET [CurrencyCode] = 'NZD' WHERE ISO_3166_Alpha2Code = 'CK'
UPDATE @table SET [CurrencyCode] = 'CRC' WHERE ISO_3166_Alpha2Code = 'CR'
UPDATE @table SET [CurrencyCode] = 'HRK' WHERE ISO_3166_Alpha2Code = 'HR'
UPDATE @table SET [CurrencyCode] = 'CUP' WHERE ISO_3166_Alpha2Code = 'CU'
UPDATE @table SET [CurrencyCode] = 'CYP' WHERE ISO_3166_Alpha2Code = 'CY'
UPDATE @table SET [CurrencyCode] = 'CSK' WHERE ISO_3166_Alpha2Code = 'CZ'
UPDATE @table SET [CurrencyCode] = 'DKK' WHERE ISO_3166_Alpha2Code = 'DK'
UPDATE @table SET [CurrencyCode] = 'DJF' WHERE ISO_3166_Alpha2Code = 'DJ'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'DM'
UPDATE @table SET [CurrencyCode] = 'DOP' WHERE ISO_3166_Alpha2Code = 'DO'
UPDATE @table SET [CurrencyCode] = 'IDR' WHERE ISO_3166_Alpha2Code = 'TP'
UPDATE @table SET [CurrencyCode] = 'ECS' WHERE ISO_3166_Alpha2Code = 'EC'
UPDATE @table SET [CurrencyCode] = 'EGP' WHERE ISO_3166_Alpha2Code = 'EG'
UPDATE @table SET [CurrencyCode] = 'SVC' WHERE ISO_3166_Alpha2Code = 'SV'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'GQ'
UPDATE @table SET [CurrencyCode] = 'ETB' WHERE ISO_3166_Alpha2Code = 'ER'
UPDATE @table SET [CurrencyCode] = 'EEK' WHERE ISO_3166_Alpha2Code = 'EE'
UPDATE @table SET [CurrencyCode] = 'ETB' WHERE ISO_3166_Alpha2Code = 'ET'
UPDATE @table SET [CurrencyCode] = 'FKP' WHERE ISO_3166_Alpha2Code = 'FK'
UPDATE @table SET [CurrencyCode] = 'DKK' WHERE ISO_3166_Alpha2Code = 'FO'
UPDATE @table SET [CurrencyCode] = 'FJD' WHERE ISO_3166_Alpha2Code = 'FJ'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'FI'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'FR'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'GF'
UPDATE @table SET [CurrencyCode] = 'XPF' WHERE ISO_3166_Alpha2Code = 'PF'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'TF'
UPDATE @table SET [CurrencyCode] = 'XAF' WHERE ISO_3166_Alpha2Code = 'GA'
UPDATE @table SET [CurrencyCode] = 'GMD' WHERE ISO_3166_Alpha2Code = 'GM'
UPDATE @table SET [CurrencyCode] = 'GEL' WHERE ISO_3166_Alpha2Code = 'GE'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'DE'
UPDATE @table SET [CurrencyCode] = 'GHC' WHERE ISO_3166_Alpha2Code = 'GH'
UPDATE @table SET [CurrencyCode] = 'GIP' WHERE ISO_3166_Alpha2Code = 'GI'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'GR'
UPDATE @table SET [CurrencyCode] = 'DKK' WHERE ISO_3166_Alpha2Code = 'GL'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'GD'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'GP'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'GU'
UPDATE @table SET [CurrencyCode] = 'GTQ' WHERE ISO_3166_Alpha2Code = 'GT'
UPDATE @table SET [CurrencyCode] = 'GNF' WHERE ISO_3166_Alpha2Code = 'GN'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'GW'
UPDATE @table SET [CurrencyCode] = 'GYD' WHERE ISO_3166_Alpha2Code = 'GY'
UPDATE @table SET [CurrencyCode] = 'HTG' WHERE ISO_3166_Alpha2Code = 'HT'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'HM'
UPDATE @table SET [CurrencyCode] = 'HNL' WHERE ISO_3166_Alpha2Code = 'HN'
UPDATE @table SET [CurrencyCode] = 'HKD' WHERE ISO_3166_Alpha2Code = 'HK'
UPDATE @table SET [CurrencyCode] = 'HUF' WHERE ISO_3166_Alpha2Code = 'HU'
UPDATE @table SET [CurrencyCode] = 'ISK' WHERE ISO_3166_Alpha2Code = 'IS'
UPDATE @table SET [CurrencyCode] = 'INR' WHERE ISO_3166_Alpha2Code = 'IN'
UPDATE @table SET [CurrencyCode] = 'IDR' WHERE ISO_3166_Alpha2Code = 'ID'
UPDATE @table SET [CurrencyCode] = 'IRR' WHERE ISO_3166_Alpha2Code = 'IR'
UPDATE @table SET [CurrencyCode] = 'IQD' WHERE ISO_3166_Alpha2Code = 'IQ'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'IE'
UPDATE @table SET [CurrencyCode] = 'ILS' WHERE ISO_3166_Alpha2Code = 'IL'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'IT'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'CI'
UPDATE @table SET [CurrencyCode] = 'JMD' WHERE ISO_3166_Alpha2Code = 'JM'
UPDATE @table SET [CurrencyCode] = 'JPY' WHERE ISO_3166_Alpha2Code = 'JP'
UPDATE @table SET [CurrencyCode] = 'JOD' WHERE ISO_3166_Alpha2Code = 'JO'
UPDATE @table SET [CurrencyCode] = 'KZT' WHERE ISO_3166_Alpha2Code = 'KZ'
UPDATE @table SET [CurrencyCode] = 'KES' WHERE ISO_3166_Alpha2Code = 'KE'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'KI'
UPDATE @table SET [CurrencyCode] = 'KPW' WHERE ISO_3166_Alpha2Code = 'KP'
UPDATE @table SET [CurrencyCode] = 'KRW' WHERE ISO_3166_Alpha2Code = 'KR'
UPDATE @table SET [CurrencyCode] = 'KWD' WHERE ISO_3166_Alpha2Code = 'KW'
UPDATE @table SET [CurrencyCode] = 'KGS' WHERE ISO_3166_Alpha2Code = 'KG'
UPDATE @table SET [CurrencyCode] = 'LAK' WHERE ISO_3166_Alpha2Code = 'LA'
UPDATE @table SET [CurrencyCode] = 'LVL' WHERE ISO_3166_Alpha2Code = 'LV'
UPDATE @table SET [CurrencyCode] = 'LBP' WHERE ISO_3166_Alpha2Code = 'LB'
UPDATE @table SET [CurrencyCode] = 'LSL' WHERE ISO_3166_Alpha2Code = 'LS'
UPDATE @table SET [CurrencyCode] = 'LRD' WHERE ISO_3166_Alpha2Code = 'LR'
UPDATE @table SET [CurrencyCode] = 'LYD' WHERE ISO_3166_Alpha2Code = 'LY'
UPDATE @table SET [CurrencyCode] = 'CHF' WHERE ISO_3166_Alpha2Code = 'LI'
UPDATE @table SET [CurrencyCode] = 'LTL' WHERE ISO_3166_Alpha2Code = 'LT'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'LU'
UPDATE @table SET [CurrencyCode] = 'MOP' WHERE ISO_3166_Alpha2Code = 'MO'
UPDATE @table SET [CurrencyCode] = 'MKD' WHERE ISO_3166_Alpha2Code = 'MK'
UPDATE @table SET [CurrencyCode] = 'MGF' WHERE ISO_3166_Alpha2Code = 'MG'
UPDATE @table SET [CurrencyCode] = 'MWK' WHERE ISO_3166_Alpha2Code = 'MW'
UPDATE @table SET [CurrencyCode] = 'MYR' WHERE ISO_3166_Alpha2Code = 'MY'
UPDATE @table SET [CurrencyCode] = 'MVR' WHERE ISO_3166_Alpha2Code = 'MV'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'ML'
UPDATE @table SET [CurrencyCode] = 'MTL' WHERE ISO_3166_Alpha2Code = 'MT'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'MH'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'MQ'
UPDATE @table SET [CurrencyCode] = 'MRO' WHERE ISO_3166_Alpha2Code = 'MR'
UPDATE @table SET [CurrencyCode] = 'MUR' WHERE ISO_3166_Alpha2Code = 'MU'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'YT'
UPDATE @table SET [CurrencyCode] = 'MXP' WHERE ISO_3166_Alpha2Code = 'MX'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'FM'
UPDATE @table SET [CurrencyCode] = 'MDL' WHERE ISO_3166_Alpha2Code = 'MD'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'MC'
UPDATE @table SET [CurrencyCode] = 'MNT' WHERE ISO_3166_Alpha2Code = 'MN'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'MS'
UPDATE @table SET [CurrencyCode] = 'MAD' WHERE ISO_3166_Alpha2Code = 'MA'
UPDATE @table SET [CurrencyCode] = 'MZM' WHERE ISO_3166_Alpha2Code = 'MZ'
UPDATE @table SET [CurrencyCode] = 'MMK' WHERE ISO_3166_Alpha2Code = 'MM'
UPDATE @table SET [CurrencyCode] = 'NAD' WHERE ISO_3166_Alpha2Code = 'NA'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'NR'
UPDATE @table SET [CurrencyCode] = 'NPR' WHERE ISO_3166_Alpha2Code = 'NP'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'NL'
UPDATE @table SET [CurrencyCode] = 'ANG' WHERE ISO_3166_Alpha2Code = 'AN'
UPDATE @table SET [CurrencyCode] = 'XPF' WHERE ISO_3166_Alpha2Code = 'NC'
UPDATE @table SET [CurrencyCode] = 'NZD' WHERE ISO_3166_Alpha2Code = 'NZ'
UPDATE @table SET [CurrencyCode] = 'NIO' WHERE ISO_3166_Alpha2Code = 'NI'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'NE'
UPDATE @table SET [CurrencyCode] = 'NGN' WHERE ISO_3166_Alpha2Code = 'NG'
UPDATE @table SET [CurrencyCode] = 'NZD' WHERE ISO_3166_Alpha2Code = 'NU'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'NF'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'MP'
UPDATE @table SET [CurrencyCode] = 'NOK' WHERE ISO_3166_Alpha2Code = 'NO'
UPDATE @table SET [CurrencyCode] = 'OMR' WHERE ISO_3166_Alpha2Code = 'OM'
UPDATE @table SET [CurrencyCode] = 'PKR' WHERE ISO_3166_Alpha2Code = 'PK'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'PW'
UPDATE @table SET [CurrencyCode] = 'PAB' WHERE ISO_3166_Alpha2Code = 'PA'
UPDATE @table SET [CurrencyCode] = 'PGK' WHERE ISO_3166_Alpha2Code = 'PG'
UPDATE @table SET [CurrencyCode] = 'PYG' WHERE ISO_3166_Alpha2Code = 'PY'
UPDATE @table SET [CurrencyCode] = 'PEN' WHERE ISO_3166_Alpha2Code = 'PE'
UPDATE @table SET [CurrencyCode] = 'PHP' WHERE ISO_3166_Alpha2Code = 'PH'
UPDATE @table SET [CurrencyCode] = 'NZD' WHERE ISO_3166_Alpha2Code = 'PN'
UPDATE @table SET [CurrencyCode] = 'PLZ' WHERE ISO_3166_Alpha2Code = 'PL'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'PT'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'PR'
UPDATE @table SET [CurrencyCode] = 'QAR' WHERE ISO_3166_Alpha2Code = 'QA'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'RE'
UPDATE @table SET [CurrencyCode] = 'RON' WHERE ISO_3166_Alpha2Code = 'RO'
UPDATE @table SET [CurrencyCode] = 'RUB' WHERE ISO_3166_Alpha2Code = 'RU'
UPDATE @table SET [CurrencyCode] = 'RWF' WHERE ISO_3166_Alpha2Code = 'RW'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'KN'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'LC'
UPDATE @table SET [CurrencyCode] = 'XCD' WHERE ISO_3166_Alpha2Code = 'VC'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'WS'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'SM'
UPDATE @table SET [CurrencyCode] = 'STD' WHERE ISO_3166_Alpha2Code = 'ST'
UPDATE @table SET [CurrencyCode] = 'SAR' WHERE ISO_3166_Alpha2Code = 'SA'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'SN'
UPDATE @table SET [CurrencyCode] = 'SCR' WHERE ISO_3166_Alpha2Code = 'SC'
UPDATE @table SET [CurrencyCode] = 'SLL' WHERE ISO_3166_Alpha2Code = 'SL'
UPDATE @table SET [CurrencyCode] = 'SGD' WHERE ISO_3166_Alpha2Code = 'SG'
UPDATE @table SET [CurrencyCode] = 'SKK' WHERE ISO_3166_Alpha2Code = 'SK'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'SI'
UPDATE @table SET [CurrencyCode] = 'SBD' WHERE ISO_3166_Alpha2Code = 'SB'
UPDATE @table SET [CurrencyCode] = 'SOS' WHERE ISO_3166_Alpha2Code = 'SO'
UPDATE @table SET [CurrencyCode] = 'ZAR' WHERE ISO_3166_Alpha2Code = 'ZA'
UPDATE @table SET [CurrencyCode] = 'GBP' WHERE ISO_3166_Alpha2Code = 'GS'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'ES'
UPDATE @table SET [CurrencyCode] = 'LKR' WHERE ISO_3166_Alpha2Code = 'LK'
UPDATE @table SET [CurrencyCode] = 'SDD' WHERE ISO_3166_Alpha2Code = 'SD'
UPDATE @table SET [CurrencyCode] = 'SRG' WHERE ISO_3166_Alpha2Code = 'SR'
UPDATE @table SET [CurrencyCode] = 'NOK' WHERE ISO_3166_Alpha2Code = 'SJ'
UPDATE @table SET [CurrencyCode] = 'SZL' WHERE ISO_3166_Alpha2Code = 'SZ'
UPDATE @table SET [CurrencyCode] = 'SEK' WHERE ISO_3166_Alpha2Code = 'SE'
UPDATE @table SET [CurrencyCode] = 'CHF' WHERE ISO_3166_Alpha2Code = 'CH'
UPDATE @table SET [CurrencyCode] = 'SYP' WHERE ISO_3166_Alpha2Code = 'SY'
UPDATE @table SET [CurrencyCode] = 'TWD' WHERE ISO_3166_Alpha2Code = 'TW'
UPDATE @table SET [CurrencyCode] = 'TJR' WHERE ISO_3166_Alpha2Code = 'TJ'
UPDATE @table SET [CurrencyCode] = 'TZS' WHERE ISO_3166_Alpha2Code = 'TZ'
UPDATE @table SET [CurrencyCode] = 'THB' WHERE ISO_3166_Alpha2Code = 'TH'
UPDATE @table SET [CurrencyCode] = 'XOF' WHERE ISO_3166_Alpha2Code = 'TG'
UPDATE @table SET [CurrencyCode] = 'NZD' WHERE ISO_3166_Alpha2Code = 'TK'
UPDATE @table SET [CurrencyCode] = 'TOP' WHERE ISO_3166_Alpha2Code = 'TO'
UPDATE @table SET [CurrencyCode] = 'TTD' WHERE ISO_3166_Alpha2Code = 'TT'
UPDATE @table SET [CurrencyCode] = 'TND' WHERE ISO_3166_Alpha2Code = 'TN'
UPDATE @table SET [CurrencyCode] = 'TRL' WHERE ISO_3166_Alpha2Code = 'TR'
UPDATE @table SET [CurrencyCode] = 'TMM' WHERE ISO_3166_Alpha2Code = 'TM'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'TC'
UPDATE @table SET [CurrencyCode] = 'AUD' WHERE ISO_3166_Alpha2Code = 'TV'
UPDATE @table SET [CurrencyCode] = 'UGX' WHERE ISO_3166_Alpha2Code = 'UG'
UPDATE @table SET [CurrencyCode] = 'UAH' WHERE ISO_3166_Alpha2Code = 'UA'
UPDATE @table SET [CurrencyCode] = 'AED' WHERE ISO_3166_Alpha2Code = 'AE'
UPDATE @table SET [CurrencyCode] = 'GBP' WHERE ISO_3166_Alpha2Code = 'GB'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'US'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'UM'
UPDATE @table SET [CurrencyCode] = 'UYU' WHERE ISO_3166_Alpha2Code = 'UY'
UPDATE @table SET [CurrencyCode] = 'UZS' WHERE ISO_3166_Alpha2Code = 'UZ'
UPDATE @table SET [CurrencyCode] = 'VUV' WHERE ISO_3166_Alpha2Code = 'VU'
UPDATE @table SET [CurrencyCode] = 'EUR' WHERE ISO_3166_Alpha2Code = 'VA'
UPDATE @table SET [CurrencyCode] = 'VEB' WHERE ISO_3166_Alpha2Code = 'VE'
UPDATE @table SET [CurrencyCode] = 'VND' WHERE ISO_3166_Alpha2Code = 'VN'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'VG'
UPDATE @table SET [CurrencyCode] = 'USD' WHERE ISO_3166_Alpha2Code = 'VI'
UPDATE @table SET [CurrencyCode] = 'XPF' WHERE ISO_3166_Alpha2Code = 'WF'
UPDATE @table SET [CurrencyCode] = 'MAD' WHERE ISO_3166_Alpha2Code = 'EH'
UPDATE @table SET [CurrencyCode] = 'YER' WHERE ISO_3166_Alpha2Code = 'YE'
UPDATE @table SET [CurrencyCode] = 'YUN' WHERE ISO_3166_Alpha2Code = 'YU'
UPDATE @table SET [CurrencyCode] = 'ZMK' WHERE ISO_3166_Alpha2Code = 'ZM'
UPDATE @table SET [CurrencyCode] = 'ZWD' WHERE ISO_3166_Alpha2Code = 'ZW'

SELECT 'countries.Add(new CountryInfo() { InternalID = ' + CAST( ISNULL(c.StrongID, 0) AS NVARCHAR(5)) + ',' +
 'EnglishName = "' + ISNULL(a.EnglishName,'') + '",' +
 'ISO_3166_Name = @"' + ISNULL(a.ISO_3166_Name,'') + '",' +
 'ISO_3166_Alpha2Code = "' + ISNULL(a.ISO_3166_Alpha2Code,'') + '",' +
 'ISO_3166_Alpha3Code = "' + ISNULL(a.ISO_3166_Alpha3Code,'') + '",' + 
 'PhoneCode = "' + ISNULL(d.Prefix,'') + '",' +
 'CurrencyCode = "' + ISNULL(a.CurrencyCode,'') + '",' +
 'NetEntCountryName = "' + ISNULL(c.NetEntCountryCode,'') + '"' +
'});' AS Column1
FROM @table a
LEFT JOIN GmCore..GmCountry b ON a.ISO_3166_Alpha2Code = b.Alpha2Code
LEFT JOIN cm..CmCountry c ON a.ISO_3166_Alpha2Code = c.Code
LEFT JOIN cm..CmPhoneCode d ON d.CountryID = c.StrongID
             */
            countries.Add(new CountryInfo() { InternalID = 8, EnglishName = "Afghanistan", ISO_3166_Name = @"AFGHANISTAN", ISO_3166_Alpha2Code = "AF", ISO_3166_Alpha3Code = "AFG", PhoneCode = "+93", CurrencyCode = "AFA", NetEntCountryName = "AFGHANISTAN" });
            countries.Add(new CountryInfo() { InternalID = 9, EnglishName = "Albania", ISO_3166_Name = @"ALBANIA", ISO_3166_Alpha2Code = "AL", ISO_3166_Alpha3Code = "ALB", PhoneCode = "+355", CurrencyCode = "ALL", NetEntCountryName = "ALBANIA" });
            countries.Add(new CountryInfo() { InternalID = 10, EnglishName = "Algeria", ISO_3166_Name = @"ALGERIA", ISO_3166_Alpha2Code = "DZ", ISO_3166_Alpha3Code = "DZA", PhoneCode = "+213", CurrencyCode = "DZD", NetEntCountryName = "ALGERIA" });
            countries.Add(new CountryInfo() { InternalID = 11, EnglishName = "American Samoa", ISO_3166_Name = @"AMERICAN SAMOA", ISO_3166_Alpha2Code = "AS", ISO_3166_Alpha3Code = "ASM", PhoneCode = "+684", CurrencyCode = "EUR", NetEntCountryName = "AMERICAN SAMOA" });
            countries.Add(new CountryInfo() { InternalID = 12, EnglishName = "Andorra", ISO_3166_Name = @"ANDORRA", ISO_3166_Alpha2Code = "AD", ISO_3166_Alpha3Code = "AND", PhoneCode = "+376", CurrencyCode = "EUR", NetEntCountryName = "ANDORRA" });
            countries.Add(new CountryInfo() { InternalID = 13, EnglishName = "Angola", ISO_3166_Name = @"ANGOLA", ISO_3166_Alpha2Code = "AO", ISO_3166_Alpha3Code = "AGO", PhoneCode = "+244", CurrencyCode = "AOK", NetEntCountryName = "ANGOLA" });
            countries.Add(new CountryInfo() { InternalID = 14, EnglishName = "Anguilla", ISO_3166_Name = @"ANGUILLA", ISO_3166_Alpha2Code = "AI", ISO_3166_Alpha3Code = "AIA", PhoneCode = "+1-264", CurrencyCode = "XCD", NetEntCountryName = "ANGUILLA" });
            countries.Add(new CountryInfo() { InternalID = 15, EnglishName = "Antarctica", ISO_3166_Name = @"ANTARCTICA", ISO_3166_Alpha2Code = "AQ", ISO_3166_Alpha3Code = "   ", PhoneCode = "+672", CurrencyCode = "", NetEntCountryName = "ANTARCTICA" });
            countries.Add(new CountryInfo() { InternalID = 16, EnglishName = "Antigua and Barbuda", ISO_3166_Name = @"ANTIGUA AND BARBUDA", ISO_3166_Alpha2Code = "AG", ISO_3166_Alpha3Code = "ATG", PhoneCode = "+1-268", CurrencyCode = "XCD", NetEntCountryName = "ANTIGUA AND BARBUDA" });
            countries.Add(new CountryInfo() { InternalID = 17, EnglishName = "Argentina", ISO_3166_Name = @"ARGENTINA", ISO_3166_Alpha2Code = "AR", ISO_3166_Alpha3Code = "ARG", PhoneCode = "+54", CurrencyCode = "ARP", NetEntCountryName = "ARGENTINA" });
            countries.Add(new CountryInfo() { InternalID = 18, EnglishName = "Armenia", ISO_3166_Name = @"ARMENIA", ISO_3166_Alpha2Code = "AM", ISO_3166_Alpha3Code = "ARM", PhoneCode = "+374", CurrencyCode = "AMD", NetEntCountryName = "ARMENIA" });
            countries.Add(new CountryInfo() { InternalID = 19, EnglishName = "Aruba", ISO_3166_Name = @"ARUBA", ISO_3166_Alpha2Code = "AW", ISO_3166_Alpha3Code = "ABW", PhoneCode = "+297", CurrencyCode = "ANG", NetEntCountryName = "ARUBA" });
            countries.Add(new CountryInfo() { InternalID = 20, EnglishName = "Australia", ISO_3166_Name = @"AUSTRALIA", ISO_3166_Alpha2Code = "AU", ISO_3166_Alpha3Code = "AUS", PhoneCode = "+61", CurrencyCode = "AUD", NetEntCountryName = "AUSTRALIA" });
            countries.Add(new CountryInfo() { InternalID = 21, EnglishName = "Austria", ISO_3166_Name = @"AUSTRIA", ISO_3166_Alpha2Code = "AT", ISO_3166_Alpha3Code = "AUT", PhoneCode = "+43", CurrencyCode = "EUR", NetEntCountryName = "AUSTRIA" });
            countries.Add(new CountryInfo() { InternalID = 22, EnglishName = "Azerbaijan", ISO_3166_Name = @"AZERBAIJAN", ISO_3166_Alpha2Code = "AZ", ISO_3166_Alpha3Code = "AZE", PhoneCode = "+994", CurrencyCode = "AZM", NetEntCountryName = "AZERBAIJAN" });
            countries.Add(new CountryInfo() { InternalID = 23, EnglishName = "Bahamas", ISO_3166_Name = @"BAHAMAS", ISO_3166_Alpha2Code = "BS", ISO_3166_Alpha3Code = "BHS", PhoneCode = "+1-242", CurrencyCode = "BSD", NetEntCountryName = "THE BAHAMAS" });
            countries.Add(new CountryInfo() { InternalID = 24, EnglishName = "Bahrain", ISO_3166_Name = @"BAHRAIN", ISO_3166_Alpha2Code = "BH", ISO_3166_Alpha3Code = "BHR", PhoneCode = "+973", CurrencyCode = "BHD", NetEntCountryName = "BAHRAIN" });
            countries.Add(new CountryInfo() { InternalID = 25, EnglishName = "Bangladesh", ISO_3166_Name = @"BANGLADESH", ISO_3166_Alpha2Code = "BD", ISO_3166_Alpha3Code = "BGD", PhoneCode = "+880", CurrencyCode = "BDT", NetEntCountryName = "BANGLADESH" });
            countries.Add(new CountryInfo() { InternalID = 26, EnglishName = "Barbados", ISO_3166_Name = @"BARBADOS", ISO_3166_Alpha2Code = "BB", ISO_3166_Alpha3Code = "BRB", PhoneCode = "+1-246", CurrencyCode = "BBD", NetEntCountryName = "BARBADOS" });
            countries.Add(new CountryInfo() { InternalID = 27, EnglishName = "Belarus", ISO_3166_Name = @"BELARUS", ISO_3166_Alpha2Code = "BY", ISO_3166_Alpha3Code = "BLR", PhoneCode = "+375", CurrencyCode = "BYR", NetEntCountryName = "BELARUS" });
            countries.Add(new CountryInfo() { InternalID = 28, EnglishName = "Belgium", ISO_3166_Name = @"BELGIUM", ISO_3166_Alpha2Code = "BE", ISO_3166_Alpha3Code = "BEL", PhoneCode = "+32", CurrencyCode = "EUR", NetEntCountryName = "BELGIUM" });
            countries.Add(new CountryInfo() { InternalID = 29, EnglishName = "Belize", ISO_3166_Name = @"BELIZE", ISO_3166_Alpha2Code = "BZ", ISO_3166_Alpha3Code = "BLZ", PhoneCode = "+501", CurrencyCode = "BZD", NetEntCountryName = "BELIZE" });
            countries.Add(new CountryInfo() { InternalID = 30, EnglishName = "Benin", ISO_3166_Name = @"BENIN", ISO_3166_Alpha2Code = "BJ", ISO_3166_Alpha3Code = "BEN", PhoneCode = "+229", CurrencyCode = "XOF", NetEntCountryName = "BENIN" });
            countries.Add(new CountryInfo() { InternalID = 31, EnglishName = "Bermuda", ISO_3166_Name = @"BERMUDA", ISO_3166_Alpha2Code = "BM", ISO_3166_Alpha3Code = "BMU", PhoneCode = "+1-441", CurrencyCode = "BMD", NetEntCountryName = "BERMUDA" });
            countries.Add(new CountryInfo() { InternalID = 32, EnglishName = "Bhutan", ISO_3166_Name = @"BHUTAN", ISO_3166_Alpha2Code = "BT", ISO_3166_Alpha3Code = "BTN", PhoneCode = "+975", CurrencyCode = "INR", NetEntCountryName = "BHUTAN" });
            countries.Add(new CountryInfo() { InternalID = 33, EnglishName = "Bolivia", ISO_3166_Name = @"BOLIVIA", ISO_3166_Alpha2Code = "BO", ISO_3166_Alpha3Code = "BOL", PhoneCode = "+591", CurrencyCode = "BOB", NetEntCountryName = "BOLIVIA" });
            countries.Add(new CountryInfo() { InternalID = 34, EnglishName = "Bosnia and Herzegovina", ISO_3166_Name = @"BOSNIA AND HERZEGOVINA", ISO_3166_Alpha2Code = "BA", ISO_3166_Alpha3Code = "BIH", PhoneCode = "+387", CurrencyCode = "BAK", NetEntCountryName = "BOSNIA AND HERZEGOVINA" });
            countries.Add(new CountryInfo() { InternalID = 35, EnglishName = "Botswana", ISO_3166_Name = @"BOTSWANA", ISO_3166_Alpha2Code = "BW", ISO_3166_Alpha3Code = "BWA", PhoneCode = "+267", CurrencyCode = "BWP", NetEntCountryName = "BOTSWANA" });
            countries.Add(new CountryInfo() { InternalID = 36, EnglishName = "Bouvet Island", ISO_3166_Name = @"BOUVET ISLAND", ISO_3166_Alpha2Code = "BV", ISO_3166_Alpha3Code = "   ", PhoneCode = "+???", CurrencyCode = "NOK", NetEntCountryName = "BOUVET ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 37, EnglishName = "Brazil", ISO_3166_Name = @"BRAZIL", ISO_3166_Alpha2Code = "BR", ISO_3166_Alpha3Code = "BRA", PhoneCode = "+55", CurrencyCode = "BRR", NetEntCountryName = "BRAZIL" });
            countries.Add(new CountryInfo() { InternalID = 38, EnglishName = "British Indian Ocean Territory", ISO_3166_Name = @"BRITISH INDIAN OCEAN TERRITORY", ISO_3166_Alpha2Code = "IO", ISO_3166_Alpha3Code = "   ", PhoneCode = "+246", CurrencyCode = "USD", NetEntCountryName = "BRITISH INDIAN OCEAN TERRITORY" });
            countries.Add(new CountryInfo() { InternalID = 39, EnglishName = "Brunei Darussalam", ISO_3166_Name = @"BRUNEI DARUSSALAM", ISO_3166_Alpha2Code = "BN", ISO_3166_Alpha3Code = "BRN", PhoneCode = "+673", CurrencyCode = "BND", NetEntCountryName = "BRUNEI DARUSSALAM" });
            countries.Add(new CountryInfo() { InternalID = 40, EnglishName = "Bulgaria", ISO_3166_Name = @"BULGARIA", ISO_3166_Alpha2Code = "BG", ISO_3166_Alpha3Code = "BGR", PhoneCode = "+359", CurrencyCode = "BGL", NetEntCountryName = "BULGARIA" });
            countries.Add(new CountryInfo() { InternalID = 41, EnglishName = "Burkina Faso", ISO_3166_Name = @"BURKINA FASO", ISO_3166_Alpha2Code = "BF", ISO_3166_Alpha3Code = "BFA", PhoneCode = "+226", CurrencyCode = "XOF", NetEntCountryName = "BURKINA FASO" });
            countries.Add(new CountryInfo() { InternalID = 42, EnglishName = "Burundi", ISO_3166_Name = @"BURUNDI", ISO_3166_Alpha2Code = "BI", ISO_3166_Alpha3Code = "BDI", PhoneCode = "+257", CurrencyCode = "BIF", NetEntCountryName = "BURUNDI" });
            countries.Add(new CountryInfo() { InternalID = 43, EnglishName = "Cambodia", ISO_3166_Name = @"CAMBODIA", ISO_3166_Alpha2Code = "KH", ISO_3166_Alpha3Code = "KHM", PhoneCode = "+855", CurrencyCode = "KHR", NetEntCountryName = "CAMBODIA" });
            countries.Add(new CountryInfo() { InternalID = 44, EnglishName = "Cameroon", ISO_3166_Name = @"CAMEROON", ISO_3166_Alpha2Code = "CM", ISO_3166_Alpha3Code = "CMR", PhoneCode = "+237", CurrencyCode = "XAF", NetEntCountryName = "CAMEROON" });
            countries.Add(new CountryInfo() { InternalID = 45, EnglishName = "Canada", ISO_3166_Name = @"CANADA", ISO_3166_Alpha2Code = "CA", ISO_3166_Alpha3Code = "CAN", PhoneCode = "+1", CurrencyCode = "CAD", NetEntCountryName = "CANADA" });
            countries.Add(new CountryInfo() { InternalID = 46, EnglishName = "Cape Verde", ISO_3166_Name = @"CAPE VERDE", ISO_3166_Alpha2Code = "CV", ISO_3166_Alpha3Code = "CPV", PhoneCode = "+238", CurrencyCode = "CVE", NetEntCountryName = "CAPE VERDE" });
            countries.Add(new CountryInfo() { InternalID = 47, EnglishName = "Cayman Islands", ISO_3166_Name = @"CAYMAN ISLANDS", ISO_3166_Alpha2Code = "KY", ISO_3166_Alpha3Code = "CYM", PhoneCode = "+1-345", CurrencyCode = "KYD", NetEntCountryName = "CAYMAN ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 48, EnglishName = "Central African Republic", ISO_3166_Name = @"CENTRAL AFRICAN REPUBLIC", ISO_3166_Alpha2Code = "CF", ISO_3166_Alpha3Code = "CAF", PhoneCode = "+236", CurrencyCode = "XAF", NetEntCountryName = "CENTRAL AFRICAN REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 49, EnglishName = "Chad", ISO_3166_Name = @"CHAD", ISO_3166_Alpha2Code = "TD", ISO_3166_Alpha3Code = "TCD", PhoneCode = "+235", CurrencyCode = "XAF", NetEntCountryName = "CHAD" });
            countries.Add(new CountryInfo() { InternalID = 50, EnglishName = "Chile", ISO_3166_Name = @"CHILE", ISO_3166_Alpha2Code = "CL", ISO_3166_Alpha3Code = "CHL", PhoneCode = "+56", CurrencyCode = "CLP", NetEntCountryName = "CHILE" });
            countries.Add(new CountryInfo() { InternalID = 51, EnglishName = "China", ISO_3166_Name = @"CHINA", ISO_3166_Alpha2Code = "CN", ISO_3166_Alpha3Code = "CHN", PhoneCode = "+86", CurrencyCode = "CNY", NetEntCountryName = "CHINA" });
            countries.Add(new CountryInfo() { InternalID = 52, EnglishName = "Christmas Island", ISO_3166_Name = @"CHRISTMAS ISLAND", ISO_3166_Alpha2Code = "CX", ISO_3166_Alpha3Code = "   ", PhoneCode = "+53", CurrencyCode = "AUD", NetEntCountryName = "CHRISTMAS ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 53, EnglishName = "Cocos (Keeling) Islands", ISO_3166_Name = @"COCOS (KEELING) ISLANDS", ISO_3166_Alpha2Code = "CC", ISO_3166_Alpha3Code = "   ", PhoneCode = "+61", CurrencyCode = "AUD", NetEntCountryName = "COCOS (KEELING) ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 54, EnglishName = "Colombia", ISO_3166_Name = @"COLOMBIA", ISO_3166_Alpha2Code = "CO", ISO_3166_Alpha3Code = "COL", PhoneCode = "+57", CurrencyCode = "COP", NetEntCountryName = "COLOMBIA" });
            countries.Add(new CountryInfo() { InternalID = 55, EnglishName = "Comoros", ISO_3166_Name = @"COMOROS", ISO_3166_Alpha2Code = "KM", ISO_3166_Alpha3Code = "COM", PhoneCode = "+269", CurrencyCode = "KMF", NetEntCountryName = "COMOROS" });
            countries.Add(new CountryInfo() { InternalID = 56, EnglishName = "Congo", ISO_3166_Name = @"CONGO", ISO_3166_Alpha2Code = "CG", ISO_3166_Alpha3Code = "COG", PhoneCode = "+242", CurrencyCode = "XAF", NetEntCountryName = "CONGO" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Congo, the Democratic Republic of the", ISO_3166_Name = @"CONGO, THE DEMOCRATIC REPUBLIC OF THE", ISO_3166_Alpha2Code = "CD", ISO_3166_Alpha3Code = "COD", PhoneCode = "", CurrencyCode = "CDF", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 57, EnglishName = "Cook Islands", ISO_3166_Name = @"COOK ISLANDS", ISO_3166_Alpha2Code = "CK", ISO_3166_Alpha3Code = "COK", PhoneCode = "+682", CurrencyCode = "NZD", NetEntCountryName = "COOK ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 58, EnglishName = "Costa Rica", ISO_3166_Name = @"COSTA RICA", ISO_3166_Alpha2Code = "CR", ISO_3166_Alpha3Code = "CRI", PhoneCode = "+506", CurrencyCode = "CRC", NetEntCountryName = "COSTA RICA" });
            countries.Add(new CountryInfo() { InternalID = 59, EnglishName = "Cote D'Ivoire", ISO_3166_Name = @"COTE D'IVOIRE", ISO_3166_Alpha2Code = "CI", ISO_3166_Alpha3Code = "CIV", PhoneCode = "+225", CurrencyCode = "XOF", NetEntCountryName = "CÈTE D'IVOIRE" });
            countries.Add(new CountryInfo() { InternalID = 60, EnglishName = "Croatia", ISO_3166_Name = @"CROATIA", ISO_3166_Alpha2Code = "HR", ISO_3166_Alpha3Code = "HRV", PhoneCode = "+385", CurrencyCode = "HRK", NetEntCountryName = "CROATIA" });
            countries.Add(new CountryInfo() { InternalID = 61, EnglishName = "Cuba", ISO_3166_Name = @"CUBA", ISO_3166_Alpha2Code = "CU", ISO_3166_Alpha3Code = "CUB", PhoneCode = "+53", CurrencyCode = "CUP", NetEntCountryName = "CUBA" });
            countries.Add(new CountryInfo() { InternalID = 62, EnglishName = "Cyprus", ISO_3166_Name = @"CYPRUS", ISO_3166_Alpha2Code = "CY", ISO_3166_Alpha3Code = "CYP", PhoneCode = "+357", CurrencyCode = "CYP", NetEntCountryName = "CYPRUS" });
            countries.Add(new CountryInfo() { InternalID = 63, EnglishName = "Czech Republic", ISO_3166_Name = @"CZECH REPUBLIC", ISO_3166_Alpha2Code = "CZ", ISO_3166_Alpha3Code = "CZE", PhoneCode = "+420", CurrencyCode = "CSK", NetEntCountryName = "CZECH REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 64, EnglishName = "Denmark", ISO_3166_Name = @"DENMARK", ISO_3166_Alpha2Code = "DK", ISO_3166_Alpha3Code = "DNK", PhoneCode = "+45", CurrencyCode = "DKK", NetEntCountryName = "DENMARK" });
            countries.Add(new CountryInfo() { InternalID = 65, EnglishName = "Djibouti", ISO_3166_Name = @"DJIBOUTI", ISO_3166_Alpha2Code = "DJ", ISO_3166_Alpha3Code = "DJI", PhoneCode = "+253", CurrencyCode = "DJF", NetEntCountryName = "DJIBOUTI" });
            countries.Add(new CountryInfo() { InternalID = 66, EnglishName = "Dominica", ISO_3166_Name = @"DOMINICA", ISO_3166_Alpha2Code = "DM", ISO_3166_Alpha3Code = "DMA", PhoneCode = "+1-767", CurrencyCode = "XCD", NetEntCountryName = "DOMINICA" });
            countries.Add(new CountryInfo() { InternalID = 67, EnglishName = "Dominican Republic", ISO_3166_Name = @"DOMINICAN REPUBLIC", ISO_3166_Alpha2Code = "DO", ISO_3166_Alpha3Code = "DOM", PhoneCode = "+1-829", CurrencyCode = "DOP", NetEntCountryName = "DOMINICAN REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 69, EnglishName = "Ecuador", ISO_3166_Name = @"ECUADOR", ISO_3166_Alpha2Code = "EC", ISO_3166_Alpha3Code = "ECU", PhoneCode = "+593", CurrencyCode = "ECS", NetEntCountryName = "ECUADOR" });
            countries.Add(new CountryInfo() { InternalID = 70, EnglishName = "Egypt", ISO_3166_Name = @"EGYPT", ISO_3166_Alpha2Code = "EG", ISO_3166_Alpha3Code = "EGY", PhoneCode = "+20", CurrencyCode = "EGP", NetEntCountryName = "EGYPT" });
            countries.Add(new CountryInfo() { InternalID = 71, EnglishName = "El Salvador", ISO_3166_Name = @"EL SALVADOR", ISO_3166_Alpha2Code = "SV", ISO_3166_Alpha3Code = "SLV", PhoneCode = "+503", CurrencyCode = "SVC", NetEntCountryName = "EL SALVADOR" });
            countries.Add(new CountryInfo() { InternalID = 72, EnglishName = "Equatorial Guinea", ISO_3166_Name = @"EQUATORIAL GUINEA", ISO_3166_Alpha2Code = "GQ", ISO_3166_Alpha3Code = "GNQ", PhoneCode = "+240", CurrencyCode = "XAF", NetEntCountryName = "EQUATORIAL GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 73, EnglishName = "Eritrea", ISO_3166_Name = @"ERITREA", ISO_3166_Alpha2Code = "ER", ISO_3166_Alpha3Code = "ERI", PhoneCode = "+291", CurrencyCode = "ETB", NetEntCountryName = "ERITREA" });
            countries.Add(new CountryInfo() { InternalID = 74, EnglishName = "Estonia", ISO_3166_Name = @"ESTONIA", ISO_3166_Alpha2Code = "EE", ISO_3166_Alpha3Code = "EST", PhoneCode = "+372", CurrencyCode = "EEK", NetEntCountryName = "ESTONIA" });
            countries.Add(new CountryInfo() { InternalID = 75, EnglishName = "Ethiopia", ISO_3166_Name = @"ETHIOPIA", ISO_3166_Alpha2Code = "ET", ISO_3166_Alpha3Code = "ETH", PhoneCode = "+251", CurrencyCode = "ETB", NetEntCountryName = "ETHIOPIA" });
            countries.Add(new CountryInfo() { InternalID = 76, EnglishName = "Falkland Islands (Malvinas)", ISO_3166_Name = @"FALKLAND ISLANDS (MALVINAS)", ISO_3166_Alpha2Code = "FK", ISO_3166_Alpha3Code = "FLK", PhoneCode = "+500", CurrencyCode = "FKP", NetEntCountryName = "FALKLAND ISLANDS (MALVINAS)" });
            countries.Add(new CountryInfo() { InternalID = 77, EnglishName = "Faroe Islands", ISO_3166_Name = @"FAROE ISLANDS", ISO_3166_Alpha2Code = "FO", ISO_3166_Alpha3Code = "FRO", PhoneCode = "+298", CurrencyCode = "DKK", NetEntCountryName = "FAROE ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 78, EnglishName = "Fiji", ISO_3166_Name = @"FIJI", ISO_3166_Alpha2Code = "FJ", ISO_3166_Alpha3Code = "FJI", PhoneCode = "+679", CurrencyCode = "FJD", NetEntCountryName = "FIJI" });
            countries.Add(new CountryInfo() { InternalID = 79, EnglishName = "Finland", ISO_3166_Name = @"FINLAND", ISO_3166_Alpha2Code = "FI", ISO_3166_Alpha3Code = "FIN", PhoneCode = "+358", CurrencyCode = "EUR", NetEntCountryName = "FINLAND" });
            countries.Add(new CountryInfo() { InternalID = 80, EnglishName = "France", ISO_3166_Name = @"FRANCE", ISO_3166_Alpha2Code = "FR", ISO_3166_Alpha3Code = "FRA", PhoneCode = "+33", CurrencyCode = "EUR", NetEntCountryName = "FRANCE" });
            countries.Add(new CountryInfo() { InternalID = 82, EnglishName = "French Guiana", ISO_3166_Name = @"FRENCH GUIANA", ISO_3166_Alpha2Code = "GF", ISO_3166_Alpha3Code = "GUF", PhoneCode = "+594", CurrencyCode = "EUR", NetEntCountryName = "FRENCH GUIANA" });
            countries.Add(new CountryInfo() { InternalID = 83, EnglishName = "French Polynesia", ISO_3166_Name = @"FRENCH POLYNESIA", ISO_3166_Alpha2Code = "PF", ISO_3166_Alpha3Code = "PYF", PhoneCode = "", CurrencyCode = "XPF", NetEntCountryName = "FRENCH POLYNESIA" });
            countries.Add(new CountryInfo() { InternalID = 84, EnglishName = "French Southern Territories", ISO_3166_Name = @"FRENCH SOUTHERN TERRITORIES", ISO_3166_Alpha2Code = "TF", ISO_3166_Alpha3Code = "   ", PhoneCode = "+596", CurrencyCode = "EUR", NetEntCountryName = "FRENCH SOUTHERN TERRITORIES" });
            countries.Add(new CountryInfo() { InternalID = 85, EnglishName = "Gabon", ISO_3166_Name = @"GABON", ISO_3166_Alpha2Code = "GA", ISO_3166_Alpha3Code = "GAB", PhoneCode = "+241", CurrencyCode = "XAF", NetEntCountryName = "GABON" });
            countries.Add(new CountryInfo() { InternalID = 86, EnglishName = "Gambia", ISO_3166_Name = @"GAMBIA", ISO_3166_Alpha2Code = "GM", ISO_3166_Alpha3Code = "GMB", PhoneCode = "+220", CurrencyCode = "GMD", NetEntCountryName = "GAMBIA" });
            countries.Add(new CountryInfo() { InternalID = 88, EnglishName = "Germany", ISO_3166_Name = @"GERMANY", ISO_3166_Alpha2Code = "DE", ISO_3166_Alpha3Code = "DEU", PhoneCode = "+49", CurrencyCode = "EUR", NetEntCountryName = "GERMANY" });
            countries.Add(new CountryInfo() { InternalID = 89, EnglishName = "Ghana", ISO_3166_Name = @"GHANA", ISO_3166_Alpha2Code = "GH", ISO_3166_Alpha3Code = "GHA", PhoneCode = "+233", CurrencyCode = "GHC", NetEntCountryName = "GHANA" });
            countries.Add(new CountryInfo() { InternalID = 90, EnglishName = "Gibraltar", ISO_3166_Name = @"GIBRALTAR", ISO_3166_Alpha2Code = "GI", ISO_3166_Alpha3Code = "GIB", PhoneCode = "+350", CurrencyCode = "GIP", NetEntCountryName = "GIBRALTAR" });
            countries.Add(new CountryInfo() { InternalID = 91, EnglishName = "Greece", ISO_3166_Name = @"GREECE", ISO_3166_Alpha2Code = "GR", ISO_3166_Alpha3Code = "GRC", PhoneCode = "+30", CurrencyCode = "EUR", NetEntCountryName = "GREECE" });
            countries.Add(new CountryInfo() { InternalID = 92, EnglishName = "Greenland", ISO_3166_Name = @"GREENLAND", ISO_3166_Alpha2Code = "GL", ISO_3166_Alpha3Code = "GRL", PhoneCode = "+299", CurrencyCode = "DKK", NetEntCountryName = "GREENLAND" });
            countries.Add(new CountryInfo() { InternalID = 93, EnglishName = "Grenada", ISO_3166_Name = @"GRENADA", ISO_3166_Alpha2Code = "GD", ISO_3166_Alpha3Code = "GRD", PhoneCode = "+1-473", CurrencyCode = "XCD", NetEntCountryName = "GRENADA" });
            countries.Add(new CountryInfo() { InternalID = 94, EnglishName = "Guadeloupe", ISO_3166_Name = @"GUADELOUPE", ISO_3166_Alpha2Code = "GP", ISO_3166_Alpha3Code = "GLP", PhoneCode = "+590", CurrencyCode = "EUR", NetEntCountryName = "GUADELOUPE" });
            countries.Add(new CountryInfo() { InternalID = 95, EnglishName = "Guam", ISO_3166_Name = @"GUAM", ISO_3166_Alpha2Code = "GU", ISO_3166_Alpha3Code = "GUM", PhoneCode = "+1-671", CurrencyCode = "USD", NetEntCountryName = "GUAM" });
            countries.Add(new CountryInfo() { InternalID = 96, EnglishName = "Guatemala", ISO_3166_Name = @"GUATEMALA", ISO_3166_Alpha2Code = "GT", ISO_3166_Alpha3Code = "GTM", PhoneCode = "+502", CurrencyCode = "GTQ", NetEntCountryName = "GUATEMALA" });
            countries.Add(new CountryInfo() { InternalID = 97, EnglishName = "Guinea", ISO_3166_Name = @"GUINEA", ISO_3166_Alpha2Code = "GN", ISO_3166_Alpha3Code = "GIN", PhoneCode = "+224", CurrencyCode = "GNF", NetEntCountryName = "GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 98, EnglishName = "Guinea-Bissau", ISO_3166_Name = @"GUINEA-BISSAU", ISO_3166_Alpha2Code = "GW", ISO_3166_Alpha3Code = "GNB", PhoneCode = "+245", CurrencyCode = "XOF", NetEntCountryName = "GUINEA-BISSAU" });
            countries.Add(new CountryInfo() { InternalID = 99, EnglishName = "Guyana", ISO_3166_Name = @"GUYANA", ISO_3166_Alpha2Code = "GY", ISO_3166_Alpha3Code = "GUY", PhoneCode = "+592", CurrencyCode = "GYD", NetEntCountryName = "GUYANA" });
            countries.Add(new CountryInfo() { InternalID = 100, EnglishName = "Haiti", ISO_3166_Name = @"HAITI", ISO_3166_Alpha2Code = "HT", ISO_3166_Alpha3Code = "HTI", PhoneCode = "+509", CurrencyCode = "HTG", NetEntCountryName = "HAITI" });
            countries.Add(new CountryInfo() { InternalID = 101, EnglishName = "Heard Island and Mcdonald Islands", ISO_3166_Name = @"HEARD ISLAND AND MCDONALD ISLANDS", ISO_3166_Alpha2Code = "HM", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "AUD", NetEntCountryName = "HEARD ISLAND AND MCDONALD ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 236, EnglishName = "Holy See (Vatican City State)", ISO_3166_Name = @"HOLY SEE (VATICAN CITY STATE)", ISO_3166_Alpha2Code = "VA", ISO_3166_Alpha3Code = "VAT", PhoneCode = "+39", CurrencyCode = "EUR", NetEntCountryName = "HOLY SEE (VATICAN)" });
            countries.Add(new CountryInfo() { InternalID = 102, EnglishName = "Honduras", ISO_3166_Name = @"HONDURAS", ISO_3166_Alpha2Code = "HN", ISO_3166_Alpha3Code = "HND", PhoneCode = "+504", CurrencyCode = "HNL", NetEntCountryName = "HONDURAS" });
            countries.Add(new CountryInfo() { InternalID = 103, EnglishName = "Hong Kong", ISO_3166_Name = @"HONG KONG", ISO_3166_Alpha2Code = "HK", ISO_3166_Alpha3Code = "HKG", PhoneCode = "+852", CurrencyCode = "HKD", NetEntCountryName = "HONG KONG" });
            countries.Add(new CountryInfo() { InternalID = 104, EnglishName = "Hungary", ISO_3166_Name = @"HUNGARY", ISO_3166_Alpha2Code = "HU", ISO_3166_Alpha3Code = "HUN", PhoneCode = "+36", CurrencyCode = "HUF", NetEntCountryName = "HUNGARY" });
            countries.Add(new CountryInfo() { InternalID = 105, EnglishName = "Iceland", ISO_3166_Name = @"ICELAND", ISO_3166_Alpha2Code = "IS", ISO_3166_Alpha3Code = "ISL", PhoneCode = "+354", CurrencyCode = "ISK", NetEntCountryName = "ICELAND" });
            countries.Add(new CountryInfo() { InternalID = 106, EnglishName = "India", ISO_3166_Name = @"INDIA", ISO_3166_Alpha2Code = "IN", ISO_3166_Alpha3Code = "IND", PhoneCode = "+91", CurrencyCode = "INR", NetEntCountryName = "INDIA" });
            countries.Add(new CountryInfo() { InternalID = 107, EnglishName = "Indonesia", ISO_3166_Name = @"INDONESIA", ISO_3166_Alpha2Code = "ID", ISO_3166_Alpha3Code = "IDN", PhoneCode = "+62", CurrencyCode = "IDR", NetEntCountryName = "INDONESIA" });
            countries.Add(new CountryInfo() { InternalID = 108, EnglishName = "Iran, Islamic Republic of", ISO_3166_Name = @"IRAN, ISLAMIC REPUBLIC OF", ISO_3166_Alpha2Code = "IR", ISO_3166_Alpha3Code = "IRN", PhoneCode = "+98", CurrencyCode = "IRR", NetEntCountryName = "IRAN, ISLAMIC REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 109, EnglishName = "Iraq", ISO_3166_Name = @"IRAQ", ISO_3166_Alpha2Code = "IQ", ISO_3166_Alpha3Code = "IRQ", PhoneCode = "+964", CurrencyCode = "IQD", NetEntCountryName = "IRAQ" });
            countries.Add(new CountryInfo() { InternalID = 110, EnglishName = "Ireland", ISO_3166_Name = @"IRELAND", ISO_3166_Alpha2Code = "IE", ISO_3166_Alpha3Code = "IRL", PhoneCode = "+353", CurrencyCode = "EUR", NetEntCountryName = "IRELAND" });
            countries.Add(new CountryInfo() { InternalID = 111, EnglishName = "Israel", ISO_3166_Name = @"ISRAEL", ISO_3166_Alpha2Code = "IL", ISO_3166_Alpha3Code = "ISR", PhoneCode = "+972", CurrencyCode = "ILS", NetEntCountryName = "ISRAEL" });
            countries.Add(new CountryInfo() { InternalID = 112, EnglishName = "Italy", ISO_3166_Name = @"ITALY", ISO_3166_Alpha2Code = "IT", ISO_3166_Alpha3Code = "ITA", PhoneCode = "+39", CurrencyCode = "EUR", NetEntCountryName = "ITALY" });
            countries.Add(new CountryInfo() { InternalID = 113, EnglishName = "Jamaica", ISO_3166_Name = @"JAMAICA", ISO_3166_Alpha2Code = "JM", ISO_3166_Alpha3Code = "JAM", PhoneCode = "+1-876", CurrencyCode = "JMD", NetEntCountryName = "JAMAICA" });
            countries.Add(new CountryInfo() { InternalID = 114, EnglishName = "Japan", ISO_3166_Name = @"JAPAN", ISO_3166_Alpha2Code = "JP", ISO_3166_Alpha3Code = "JPN", PhoneCode = "+81", CurrencyCode = "JPY", NetEntCountryName = "JAPAN" });
            countries.Add(new CountryInfo() { InternalID = 115, EnglishName = "Jordan", ISO_3166_Name = @"JORDAN", ISO_3166_Alpha2Code = "JO", ISO_3166_Alpha3Code = "JOR", PhoneCode = "+962", CurrencyCode = "JOD", NetEntCountryName = "JORDAN" });
            countries.Add(new CountryInfo() { InternalID = 116, EnglishName = "Kazakhstan", ISO_3166_Name = @"KAZAKHSTAN", ISO_3166_Alpha2Code = "KZ", ISO_3166_Alpha3Code = "KAZ", PhoneCode = "+7", CurrencyCode = "KZT", NetEntCountryName = "KAZAKSTAN" });
            countries.Add(new CountryInfo() { InternalID = 117, EnglishName = "Kenya", ISO_3166_Name = @"KENYA", ISO_3166_Alpha2Code = "KE", ISO_3166_Alpha3Code = "KEN", PhoneCode = "+254", CurrencyCode = "KES", NetEntCountryName = "KENYA" });
            countries.Add(new CountryInfo() { InternalID = 118, EnglishName = "Kiribati", ISO_3166_Name = @"KIRIBATI", ISO_3166_Alpha2Code = "KI", ISO_3166_Alpha3Code = "KIR", PhoneCode = "+686", CurrencyCode = "AUD", NetEntCountryName = "KIRIBATI" });
            countries.Add(new CountryInfo() { InternalID = 164, EnglishName = "Korea, Democratic People's Republic of", ISO_3166_Name = @"KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF", ISO_3166_Alpha2Code = "KP", ISO_3166_Alpha3Code = "PRK", PhoneCode = "+850", CurrencyCode = "KPW", NetEntCountryName = "KOREA, DEMOCRATIC PEOPLE'S REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 202, EnglishName = "Korea, Republic of", ISO_3166_Name = @"KOREA, REPUBLIC OF", ISO_3166_Alpha2Code = "KR", ISO_3166_Alpha3Code = "KOR", PhoneCode = "+82", CurrencyCode = "KRW", NetEntCountryName = "KOREA, REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 119, EnglishName = "Kuwait", ISO_3166_Name = @"KUWAIT", ISO_3166_Alpha2Code = "KW", ISO_3166_Alpha3Code = "KWT", PhoneCode = "+965", CurrencyCode = "KWD", NetEntCountryName = "KUWAIT" });
            countries.Add(new CountryInfo() { InternalID = 120, EnglishName = "Kyrgyzstan", ISO_3166_Name = @"KYRGYZSTAN", ISO_3166_Alpha2Code = "KG", ISO_3166_Alpha3Code = "KGZ", PhoneCode = "+996", CurrencyCode = "KGS", NetEntCountryName = "KYRGYZSTAN" });
            countries.Add(new CountryInfo() { InternalID = 121, EnglishName = "Lao People's Democratic Republic", ISO_3166_Name = @"LAO PEOPLE'S DEMOCRATIC REPUBLIC", ISO_3166_Alpha2Code = "LA", ISO_3166_Alpha3Code = "LAO", PhoneCode = "+856", CurrencyCode = "LAK", NetEntCountryName = "LAO PEOPLE'S DEMOCRATIC REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 122, EnglishName = "Latvia", ISO_3166_Name = @"LATVIA", ISO_3166_Alpha2Code = "LV", ISO_3166_Alpha3Code = "LVA", PhoneCode = "+371", CurrencyCode = "LVL", NetEntCountryName = "LATVIA" });
            countries.Add(new CountryInfo() { InternalID = 123, EnglishName = "Lebanon", ISO_3166_Name = @"LEBANON", ISO_3166_Alpha2Code = "LB", ISO_3166_Alpha3Code = "LBN", PhoneCode = "+961", CurrencyCode = "LBP", NetEntCountryName = "LEBANON" });
            countries.Add(new CountryInfo() { InternalID = 124, EnglishName = "Lesotho", ISO_3166_Name = @"LESOTHO", ISO_3166_Alpha2Code = "LS", ISO_3166_Alpha3Code = "LSO", PhoneCode = "+266", CurrencyCode = "LSL", NetEntCountryName = "LESOTHO" });
            countries.Add(new CountryInfo() { InternalID = 125, EnglishName = "Liberia", ISO_3166_Name = @"LIBERIA", ISO_3166_Alpha2Code = "LR", ISO_3166_Alpha3Code = "LBR", PhoneCode = "+231", CurrencyCode = "LRD", NetEntCountryName = "LIBERIA" });
            countries.Add(new CountryInfo() { InternalID = 126, EnglishName = "Libyan Arab Jamahiriya", ISO_3166_Name = @"LIBYAN ARAB JAMAHIRIYA", ISO_3166_Alpha2Code = "LY", ISO_3166_Alpha3Code = "LBY", PhoneCode = "+218", CurrencyCode = "LYD", NetEntCountryName = "LIBYAN ARAB JAMAHIRIYA" });
            countries.Add(new CountryInfo() { InternalID = 127, EnglishName = "Liechtenstein", ISO_3166_Name = @"LIECHTENSTEIN", ISO_3166_Alpha2Code = "LI", ISO_3166_Alpha3Code = "LIE", PhoneCode = "+423", CurrencyCode = "CHF", NetEntCountryName = "LIECHTENSTEIN" });
            countries.Add(new CountryInfo() { InternalID = 128, EnglishName = "Lithuania", ISO_3166_Name = @"LITHUANIA", ISO_3166_Alpha2Code = "LT", ISO_3166_Alpha3Code = "LTU", PhoneCode = "+370", CurrencyCode = "LTL", NetEntCountryName = "LITHUANIA" });
            countries.Add(new CountryInfo() { InternalID = 129, EnglishName = "Luxembourg", ISO_3166_Name = @"LUXEMBOURG", ISO_3166_Alpha2Code = "LU", ISO_3166_Alpha3Code = "LUX", PhoneCode = "+352", CurrencyCode = "EUR", NetEntCountryName = "LUXEMBOURG" });
            countries.Add(new CountryInfo() { InternalID = 130, EnglishName = "Macao", ISO_3166_Name = @"MACAO", ISO_3166_Alpha2Code = "MO", ISO_3166_Alpha3Code = "MAC", PhoneCode = "+853", CurrencyCode = "MOP", NetEntCountryName = "MACAU" });
            countries.Add(new CountryInfo() { InternalID = 131, EnglishName = "Macedonia, the Former Yugoslav Republic of", ISO_3166_Name = @"MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF", ISO_3166_Alpha2Code = "MK", ISO_3166_Alpha3Code = "MKD", PhoneCode = "+389", CurrencyCode = "MKD", NetEntCountryName = "MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 132, EnglishName = "Madagascar", ISO_3166_Name = @"MADAGASCAR", ISO_3166_Alpha2Code = "MG", ISO_3166_Alpha3Code = "MDG", PhoneCode = "+261", CurrencyCode = "MGF", NetEntCountryName = "MADAGASCAR" });
            countries.Add(new CountryInfo() { InternalID = 133, EnglishName = "Malawi", ISO_3166_Name = @"MALAWI", ISO_3166_Alpha2Code = "MW", ISO_3166_Alpha3Code = "MWI", PhoneCode = "+265", CurrencyCode = "MWK", NetEntCountryName = "MALAWI" });
            countries.Add(new CountryInfo() { InternalID = 134, EnglishName = "Malaysia", ISO_3166_Name = @"MALAYSIA", ISO_3166_Alpha2Code = "MY", ISO_3166_Alpha3Code = "MYS", PhoneCode = "+60", CurrencyCode = "MYR", NetEntCountryName = "MALAYSIA" });
            countries.Add(new CountryInfo() { InternalID = 135, EnglishName = "Maldives", ISO_3166_Name = @"MALDIVES", ISO_3166_Alpha2Code = "MV", ISO_3166_Alpha3Code = "MDV", PhoneCode = "+960", CurrencyCode = "MVR", NetEntCountryName = "MALDIVES" });
            countries.Add(new CountryInfo() { InternalID = 136, EnglishName = "Mali", ISO_3166_Name = @"MALI", ISO_3166_Alpha2Code = "ML", ISO_3166_Alpha3Code = "MLI", PhoneCode = "+223", CurrencyCode = "XOF", NetEntCountryName = "MALI" });
            countries.Add(new CountryInfo() { InternalID = 137, EnglishName = "Malta", ISO_3166_Name = @"MALTA", ISO_3166_Alpha2Code = "MT", ISO_3166_Alpha3Code = "MLT", PhoneCode = "+356", CurrencyCode = "MTL", NetEntCountryName = "MALTA" });
            countries.Add(new CountryInfo() { InternalID = 138, EnglishName = "Marshall Islands", ISO_3166_Name = @"MARSHALL ISLANDS", ISO_3166_Alpha2Code = "MH", ISO_3166_Alpha3Code = "MHL", PhoneCode = "+692", CurrencyCode = "USD", NetEntCountryName = "MARSHALL ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 139, EnglishName = "Martinique", ISO_3166_Name = @"MARTINIQUE", ISO_3166_Alpha2Code = "MQ", ISO_3166_Alpha3Code = "MTQ", PhoneCode = "", CurrencyCode = "EUR", NetEntCountryName = "MARTINIQUE" });
            countries.Add(new CountryInfo() { InternalID = 140, EnglishName = "Mauritania", ISO_3166_Name = @"MAURITANIA", ISO_3166_Alpha2Code = "MR", ISO_3166_Alpha3Code = "MRT", PhoneCode = "", CurrencyCode = "MRO", NetEntCountryName = "MAURITANIA" });
            countries.Add(new CountryInfo() { InternalID = 141, EnglishName = "Mauritius", ISO_3166_Name = @"MAURITIUS", ISO_3166_Alpha2Code = "MU", ISO_3166_Alpha3Code = "MUS", PhoneCode = "+230", CurrencyCode = "MUR", NetEntCountryName = "MAURITIUS" });
            countries.Add(new CountryInfo() { InternalID = 142, EnglishName = "Mayotte", ISO_3166_Name = @"MAYOTTE", ISO_3166_Alpha2Code = "YT", ISO_3166_Alpha3Code = "   ", PhoneCode = "+269", CurrencyCode = "EUR", NetEntCountryName = "MAYOTTE" });
            countries.Add(new CountryInfo() { InternalID = 143, EnglishName = "Mexico", ISO_3166_Name = @"MEXICO", ISO_3166_Alpha2Code = "MX", ISO_3166_Alpha3Code = "MEX", PhoneCode = "+52", CurrencyCode = "MXP", NetEntCountryName = "MEXICO" });
            countries.Add(new CountryInfo() { InternalID = 144, EnglishName = "Micronesia, Federated States of", ISO_3166_Name = @"MICRONESIA, FEDERATED STATES OF", ISO_3166_Alpha2Code = "FM", ISO_3166_Alpha3Code = "FSM", PhoneCode = "+691", CurrencyCode = "USD", NetEntCountryName = "MICRONESIA, FEDERATED STATES OF" });
            countries.Add(new CountryInfo() { InternalID = 145, EnglishName = "Moldova, Republic of", ISO_3166_Name = @"MOLDOVA, REPUBLIC OF", ISO_3166_Alpha2Code = "MD", ISO_3166_Alpha3Code = "MDA", PhoneCode = "+373", CurrencyCode = "MDL", NetEntCountryName = "MOLDOVA, REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 146, EnglishName = "Monaco", ISO_3166_Name = @"MONACO", ISO_3166_Alpha2Code = "MC", ISO_3166_Alpha3Code = "MCO", PhoneCode = "+377", CurrencyCode = "EUR", NetEntCountryName = "MONACO" });
            countries.Add(new CountryInfo() { InternalID = 147, EnglishName = "Mongolia", ISO_3166_Name = @"MONGOLIA", ISO_3166_Alpha2Code = "MN", ISO_3166_Alpha3Code = "MNG", PhoneCode = "+976", CurrencyCode = "MNT", NetEntCountryName = "MONGOLIA" });
            countries.Add(new CountryInfo() { InternalID = 148, EnglishName = "Montserrat", ISO_3166_Name = @"MONTSERRAT", ISO_3166_Alpha2Code = "MS", ISO_3166_Alpha3Code = "MSR", PhoneCode = "+1-664", CurrencyCode = "XCD", NetEntCountryName = "MONTSERRAT" });
            countries.Add(new CountryInfo() { InternalID = 149, EnglishName = "Morocco", ISO_3166_Name = @"MOROCCO", ISO_3166_Alpha2Code = "MA", ISO_3166_Alpha3Code = "MAR", PhoneCode = "+212", CurrencyCode = "MAD", NetEntCountryName = "MOROCCO" });
            countries.Add(new CountryInfo() { InternalID = 150, EnglishName = "Mozambique", ISO_3166_Name = @"MOZAMBIQUE", ISO_3166_Alpha2Code = "MZ", ISO_3166_Alpha3Code = "MOZ", PhoneCode = "+258", CurrencyCode = "MZM", NetEntCountryName = "MOZAMBIQUE" });
            countries.Add(new CountryInfo() { InternalID = 151, EnglishName = "Myanmar", ISO_3166_Name = @"MYANMAR", ISO_3166_Alpha2Code = "MM", ISO_3166_Alpha3Code = "MMR", PhoneCode = "+95", CurrencyCode = "MMK", NetEntCountryName = "MYANMAR" });
            countries.Add(new CountryInfo() { InternalID = 152, EnglishName = "Namibia", ISO_3166_Name = @"NAMIBIA", ISO_3166_Alpha2Code = "NA", ISO_3166_Alpha3Code = "NAM", PhoneCode = "+264", CurrencyCode = "NAD", NetEntCountryName = "NAMIBIA" });
            countries.Add(new CountryInfo() { InternalID = 153, EnglishName = "Nauru", ISO_3166_Name = @"NAURU", ISO_3166_Alpha2Code = "NR", ISO_3166_Alpha3Code = "NRU", PhoneCode = "+674", CurrencyCode = "AUD", NetEntCountryName = "NAURU" });
            countries.Add(new CountryInfo() { InternalID = 154, EnglishName = "Nepal", ISO_3166_Name = @"NEPAL", ISO_3166_Alpha2Code = "NP", ISO_3166_Alpha3Code = "NPL", PhoneCode = "+977", CurrencyCode = "NPR", NetEntCountryName = "NEPAL" });
            countries.Add(new CountryInfo() { InternalID = 155, EnglishName = "Netherlands", ISO_3166_Name = @"NETHERLANDS", ISO_3166_Alpha2Code = "NL", ISO_3166_Alpha3Code = "NLD", PhoneCode = "+31", CurrencyCode = "EUR", NetEntCountryName = "THE NETHERLANDS" });
            countries.Add(new CountryInfo() { InternalID = 156, EnglishName = "Netherlands Antilles", ISO_3166_Name = @"NETHERLANDS ANTILLES", ISO_3166_Alpha2Code = "AN", ISO_3166_Alpha3Code = "ANT", PhoneCode = "+599", CurrencyCode = "ANG", NetEntCountryName = "NETHERLANDS ANTILLES" });
            countries.Add(new CountryInfo() { InternalID = 157, EnglishName = "New Caledonia", ISO_3166_Name = @"NEW CALEDONIA", ISO_3166_Alpha2Code = "NC", ISO_3166_Alpha3Code = "NCL", PhoneCode = "+687", CurrencyCode = "XPF", NetEntCountryName = "NEW CALEDONIA" });
            countries.Add(new CountryInfo() { InternalID = 158, EnglishName = "New Zealand", ISO_3166_Name = @"NEW ZEALAND", ISO_3166_Alpha2Code = "NZ", ISO_3166_Alpha3Code = "NZL", PhoneCode = "+64", CurrencyCode = "NZD", NetEntCountryName = "NEW ZEALAND" });
            countries.Add(new CountryInfo() { InternalID = 159, EnglishName = "Nicaragua", ISO_3166_Name = @"NICARAGUA", ISO_3166_Alpha2Code = "NI", ISO_3166_Alpha3Code = "NIC", PhoneCode = "+505", CurrencyCode = "NIO", NetEntCountryName = "NICARAGUA" });
            countries.Add(new CountryInfo() { InternalID = 160, EnglishName = "Niger", ISO_3166_Name = @"NIGER", ISO_3166_Alpha2Code = "NE", ISO_3166_Alpha3Code = "NER", PhoneCode = "+227", CurrencyCode = "XOF", NetEntCountryName = "NIGER" });
            countries.Add(new CountryInfo() { InternalID = 161, EnglishName = "Nigeria", ISO_3166_Name = @"NIGERIA", ISO_3166_Alpha2Code = "NG", ISO_3166_Alpha3Code = "NGA", PhoneCode = "+234", CurrencyCode = "NGN", NetEntCountryName = "NIGERIA" });
            countries.Add(new CountryInfo() { InternalID = 162, EnglishName = "Niue", ISO_3166_Name = @"NIUE", ISO_3166_Alpha2Code = "NU", ISO_3166_Alpha3Code = "NIU", PhoneCode = "+683", CurrencyCode = "NZD", NetEntCountryName = "NIUE" });
            countries.Add(new CountryInfo() { InternalID = 163, EnglishName = "Norfolk Island", ISO_3166_Name = @"NORFOLK ISLAND", ISO_3166_Alpha2Code = "NF", ISO_3166_Alpha3Code = "NFK", PhoneCode = "+672", CurrencyCode = "AUD", NetEntCountryName = "NORFOLK ISLAND" });
            countries.Add(new CountryInfo() { InternalID = 165, EnglishName = "Northern Mariana Islands", ISO_3166_Name = @"NORTHERN MARIANA ISLANDS", ISO_3166_Alpha2Code = "MP", ISO_3166_Alpha3Code = "MNP", PhoneCode = "+1-670", CurrencyCode = "USD", NetEntCountryName = "NORTHERN MARIANA ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 166, EnglishName = "Norway", ISO_3166_Name = @"NORWAY", ISO_3166_Alpha2Code = "NO", ISO_3166_Alpha3Code = "NOR", PhoneCode = "+47", CurrencyCode = "NOK", NetEntCountryName = "NORWAY" });
            countries.Add(new CountryInfo() { InternalID = 167, EnglishName = "Oman", ISO_3166_Name = @"OMAN", ISO_3166_Alpha2Code = "OM", ISO_3166_Alpha3Code = "OMN", PhoneCode = "+968", CurrencyCode = "OMR", NetEntCountryName = "OMAN" });
            countries.Add(new CountryInfo() { InternalID = 169, EnglishName = "Pakistan", ISO_3166_Name = @"PAKISTAN", ISO_3166_Alpha2Code = "PK", ISO_3166_Alpha3Code = "PAK", PhoneCode = "+92", CurrencyCode = "PKR", NetEntCountryName = "PAKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 170, EnglishName = "Palau", ISO_3166_Name = @"PALAU", ISO_3166_Alpha2Code = "PW", ISO_3166_Alpha3Code = "PLW", PhoneCode = "+680", CurrencyCode = "USD", NetEntCountryName = "PALAU" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Palestinian Territory, Occupied", ISO_3166_Name = @"PALESTINIAN TERRITORY, OCCUPIED", ISO_3166_Alpha2Code = "PS", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 171, EnglishName = "Panama", ISO_3166_Name = @"PANAMA", ISO_3166_Alpha2Code = "PA", ISO_3166_Alpha3Code = "PAN", PhoneCode = "+507", CurrencyCode = "PAB", NetEntCountryName = "PANAMA" });
            countries.Add(new CountryInfo() { InternalID = 172, EnglishName = "Papua New Guinea", ISO_3166_Name = @"PAPUA NEW GUINEA", ISO_3166_Alpha2Code = "PG", ISO_3166_Alpha3Code = "PNG", PhoneCode = "+675", CurrencyCode = "PGK", NetEntCountryName = "PAPUA NEW GUINEA" });
            countries.Add(new CountryInfo() { InternalID = 173, EnglishName = "Paraguay", ISO_3166_Name = @"PARAGUAY", ISO_3166_Alpha2Code = "PY", ISO_3166_Alpha3Code = "PRY", PhoneCode = "+595", CurrencyCode = "PYG", NetEntCountryName = "PARAGUAY" });
            countries.Add(new CountryInfo() { InternalID = 174, EnglishName = "Peru", ISO_3166_Name = @"PERU", ISO_3166_Alpha2Code = "PE", ISO_3166_Alpha3Code = "PER", PhoneCode = "+51", CurrencyCode = "PEN", NetEntCountryName = "PERU" });
            countries.Add(new CountryInfo() { InternalID = 175, EnglishName = "Philippines", ISO_3166_Name = @"PHILIPPINES", ISO_3166_Alpha2Code = "PH", ISO_3166_Alpha3Code = "PHL", PhoneCode = "+63", CurrencyCode = "PHP", NetEntCountryName = "THE PHILIPPINES" });
            countries.Add(new CountryInfo() { InternalID = 176, EnglishName = "Pitcairn", ISO_3166_Name = @"PITCAIRN", ISO_3166_Alpha2Code = "PN", ISO_3166_Alpha3Code = "PCN", PhoneCode = "+872", CurrencyCode = "NZD", NetEntCountryName = "PITCAIRN" });
            countries.Add(new CountryInfo() { InternalID = 177, EnglishName = "Poland", ISO_3166_Name = @"POLAND", ISO_3166_Alpha2Code = "PL", ISO_3166_Alpha3Code = "POL", PhoneCode = "+48", CurrencyCode = "PLZ", NetEntCountryName = "POLAND" });
            countries.Add(new CountryInfo() { InternalID = 178, EnglishName = "Portugal", ISO_3166_Name = @"PORTUGAL", ISO_3166_Alpha2Code = "PT", ISO_3166_Alpha3Code = "PRT", PhoneCode = "+351", CurrencyCode = "EUR", NetEntCountryName = "PORTUGAL" });
            countries.Add(new CountryInfo() { InternalID = 179, EnglishName = "Puerto Rico", ISO_3166_Name = @"PUERTO RICO", ISO_3166_Alpha2Code = "PR", ISO_3166_Alpha3Code = "PRI", PhoneCode = "+1-787", CurrencyCode = "USD", NetEntCountryName = "PUERTO RICO" });
            countries.Add(new CountryInfo() { InternalID = 180, EnglishName = "Qatar", ISO_3166_Name = @"QATAR", ISO_3166_Alpha2Code = "QA", ISO_3166_Alpha3Code = "QAT", PhoneCode = "+974", CurrencyCode = "QAR", NetEntCountryName = "QATAR" });
            countries.Add(new CountryInfo() { InternalID = 181, EnglishName = "Reunion", ISO_3166_Name = @"REUNION", ISO_3166_Alpha2Code = "RE", ISO_3166_Alpha3Code = "REU", PhoneCode = "+262", CurrencyCode = "EUR", NetEntCountryName = "R+UNION" });
            countries.Add(new CountryInfo() { InternalID = 182, EnglishName = "Romania", ISO_3166_Name = @"ROMANIA", ISO_3166_Alpha2Code = "RO", ISO_3166_Alpha3Code = "ROM", PhoneCode = "+40", CurrencyCode = "RON", NetEntCountryName = "ROMANIA" });
            countries.Add(new CountryInfo() { InternalID = 183, EnglishName = "Russian Federation", ISO_3166_Name = @"RUSSIAN FEDERATION", ISO_3166_Alpha2Code = "RU", ISO_3166_Alpha3Code = "RUS", PhoneCode = "+7", CurrencyCode = "RUB", NetEntCountryName = "RUSSIAN FEDERATION" });
            countries.Add(new CountryInfo() { InternalID = 184, EnglishName = "Rwanda", ISO_3166_Name = @"RWANDA", ISO_3166_Alpha2Code = "RW", ISO_3166_Alpha3Code = "RWA", PhoneCode = "+250", CurrencyCode = "RWF", NetEntCountryName = "RWANDA" });
            countries.Add(new CountryInfo() { InternalID = 205, EnglishName = "Saint Helena", ISO_3166_Name = @"SAINT HELENA", ISO_3166_Alpha2Code = "SH", ISO_3166_Alpha3Code = "SHN", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "SAINT HELENA" });
            countries.Add(new CountryInfo() { InternalID = 185, EnglishName = "Saint Kitts and Nevis", ISO_3166_Name = @"SAINT KITTS AND NEVIS", ISO_3166_Alpha2Code = "KN", ISO_3166_Alpha3Code = "KNA", PhoneCode = "+1-869", CurrencyCode = "XCD", NetEntCountryName = "SAINT KITTS AND NEVIS" });
            countries.Add(new CountryInfo() { InternalID = 186, EnglishName = "Saint Lucia", ISO_3166_Name = @"SAINT LUCIA", ISO_3166_Alpha2Code = "LC", ISO_3166_Alpha3Code = "LCA", PhoneCode = "+1-758", CurrencyCode = "XCD", NetEntCountryName = "SAINT LUCIA" });
            countries.Add(new CountryInfo() { InternalID = 206, EnglishName = "Saint Pierre and Miquelon", ISO_3166_Name = @"SAINT PIERRE AND MIQUELON", ISO_3166_Alpha2Code = "PM", ISO_3166_Alpha3Code = "SPM", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "SAINT PIERRE AND MIQUELON" });
            countries.Add(new CountryInfo() { InternalID = 187, EnglishName = "Saint Vincent and the Grenadines", ISO_3166_Name = @"SAINT VINCENT AND THE GRENADINES", ISO_3166_Alpha2Code = "VC", ISO_3166_Alpha3Code = "VCT", PhoneCode = "+1-784", CurrencyCode = "XCD", NetEntCountryName = "SAINT VINCENT AND THE GRENADINES" });
            countries.Add(new CountryInfo() { InternalID = 188, EnglishName = "Samoa", ISO_3166_Name = @"SAMOA", ISO_3166_Alpha2Code = "WS", ISO_3166_Alpha3Code = "WSM", PhoneCode = "+684", CurrencyCode = "EUR", NetEntCountryName = "SAMOA" });
            countries.Add(new CountryInfo() { InternalID = 189, EnglishName = "San Marino", ISO_3166_Name = @"SAN MARINO", ISO_3166_Alpha2Code = "SM", ISO_3166_Alpha3Code = "SMR", PhoneCode = "+378", CurrencyCode = "EUR", NetEntCountryName = "SAN MARINO" });
            countries.Add(new CountryInfo() { InternalID = 190, EnglishName = "Sao Tome and Principe", ISO_3166_Name = @"SAO TOME AND PRINCIPE", ISO_3166_Alpha2Code = "ST", ISO_3166_Alpha3Code = "STP", PhoneCode = "", CurrencyCode = "STD", NetEntCountryName = "SAO TOME AND PRINCIPE" });
            countries.Add(new CountryInfo() { InternalID = 191, EnglishName = "Saudi Arabia", ISO_3166_Name = @"SAUDI ARABIA", ISO_3166_Alpha2Code = "SA", ISO_3166_Alpha3Code = "SAU", PhoneCode = "+966", CurrencyCode = "SAR", NetEntCountryName = "SAUDI ARABIA" });
            countries.Add(new CountryInfo() { InternalID = 192, EnglishName = "Senegal", ISO_3166_Name = @"SENEGAL", ISO_3166_Alpha2Code = "SN", ISO_3166_Alpha3Code = "SEN", PhoneCode = "+221", CurrencyCode = "XOF", NetEntCountryName = "SENEGAL" });
            countries.Add(new CountryInfo() { InternalID = 247, EnglishName = "Serbia", ISO_3166_Name = @"SERBIA", ISO_3166_Alpha2Code = "RS", ISO_3166_Alpha3Code = "SRB", PhoneCode = "+381", CurrencyCode = "RSD", NetEntCountryName = "SERBIA" });
            countries.Add(new CountryInfo() { InternalID = 248, EnglishName = "Montenegro", ISO_3166_Name = @"MONTENEGRO", ISO_3166_Alpha2Code = "ME", ISO_3166_Alpha3Code = "MNE", PhoneCode = "+382", CurrencyCode = "EUR", NetEntCountryName = "MONTENEGRO" });
            countries.Add(new CountryInfo() { InternalID = 193, EnglishName = "Seychelles", ISO_3166_Name = @"SEYCHELLES", ISO_3166_Alpha2Code = "SC", ISO_3166_Alpha3Code = "SYC", PhoneCode = "+248", CurrencyCode = "SCR", NetEntCountryName = "SEYCHELLES" });
            countries.Add(new CountryInfo() { InternalID = 194, EnglishName = "Sierra Leone", ISO_3166_Name = @"SIERRA LEONE", ISO_3166_Alpha2Code = "SL", ISO_3166_Alpha3Code = "SLE", PhoneCode = "+232", CurrencyCode = "SLL", NetEntCountryName = "SIERRA LEONE" });
            countries.Add(new CountryInfo() { InternalID = 195, EnglishName = "Singapore", ISO_3166_Name = @"SINGAPORE", ISO_3166_Alpha2Code = "SG", ISO_3166_Alpha3Code = "SGP", PhoneCode = "+65", CurrencyCode = "SGD", NetEntCountryName = "SINGAPORE" });
            countries.Add(new CountryInfo() { InternalID = 196, EnglishName = "Slovakia", ISO_3166_Name = @"SLOVAKIA", ISO_3166_Alpha2Code = "SK", ISO_3166_Alpha3Code = "SVK", PhoneCode = "+421", CurrencyCode = "SKK", NetEntCountryName = "SLOVAKIA" });
            countries.Add(new CountryInfo() { InternalID = 197, EnglishName = "Slovenia", ISO_3166_Name = @"SLOVENIA", ISO_3166_Alpha2Code = "SI", ISO_3166_Alpha3Code = "SVN", PhoneCode = "+386", CurrencyCode = "EUR", NetEntCountryName = "SLOVENIA" });
            countries.Add(new CountryInfo() { InternalID = 198, EnglishName = "Solomon Islands", ISO_3166_Name = @"SOLOMON ISLANDS", ISO_3166_Alpha2Code = "SB", ISO_3166_Alpha3Code = "SLB", PhoneCode = "+677", CurrencyCode = "SBD", NetEntCountryName = "SOLOMON ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 199, EnglishName = "Somalia", ISO_3166_Name = @"SOMALIA", ISO_3166_Alpha2Code = "SO", ISO_3166_Alpha3Code = "SOM", PhoneCode = "+252", CurrencyCode = "SOS", NetEntCountryName = "SOMALIA" });
            countries.Add(new CountryInfo() { InternalID = 200, EnglishName = "South Africa", ISO_3166_Name = @"SOUTH AFRICA", ISO_3166_Alpha2Code = "ZA", ISO_3166_Alpha3Code = "ZAF", PhoneCode = "+27", CurrencyCode = "ZAR", NetEntCountryName = "SOUTH AFRICA" });
            countries.Add(new CountryInfo() { InternalID = 201, EnglishName = "South Georgia and the South Sandwich Islands", ISO_3166_Name = @"SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS", ISO_3166_Alpha2Code = "GS", ISO_3166_Alpha3Code = "   ", PhoneCode = "+82", CurrencyCode = "GBP", NetEntCountryName = "S. GEORGIA & S. SANDW. IS." });
            countries.Add(new CountryInfo() { InternalID = 203, EnglishName = "Spain", ISO_3166_Name = @"SPAIN", ISO_3166_Alpha2Code = "ES", ISO_3166_Alpha3Code = "ESP", PhoneCode = "+34", CurrencyCode = "EUR", NetEntCountryName = "SPAIN" });
            countries.Add(new CountryInfo() { InternalID = 204, EnglishName = "Sri Lanka", ISO_3166_Name = @"SRI LANKA", ISO_3166_Alpha2Code = "LK", ISO_3166_Alpha3Code = "LKA", PhoneCode = "+94", CurrencyCode = "LKR", NetEntCountryName = "SRI LANKA" });
            countries.Add(new CountryInfo() { InternalID = 207, EnglishName = "Sudan", ISO_3166_Name = @"SUDAN", ISO_3166_Alpha2Code = "SD", ISO_3166_Alpha3Code = "SDN", PhoneCode = "+249", CurrencyCode = "SDD", NetEntCountryName = "SUDAN" });
            countries.Add(new CountryInfo() { InternalID = 208, EnglishName = "Suriname", ISO_3166_Name = @"SURINAME", ISO_3166_Alpha2Code = "SR", ISO_3166_Alpha3Code = "SUR", PhoneCode = "+597", CurrencyCode = "SRG", NetEntCountryName = "SURINAME" });
            countries.Add(new CountryInfo() { InternalID = 209, EnglishName = "Svalbard and Jan Mayen", ISO_3166_Name = @"SVALBARD AND JAN MAYEN", ISO_3166_Alpha2Code = "SJ", ISO_3166_Alpha3Code = "SJM", PhoneCode = "+47", CurrencyCode = "NOK", NetEntCountryName = "SVALBARD AND JAN MAYEN" });
            countries.Add(new CountryInfo() { InternalID = 210, EnglishName = "Swaziland", ISO_3166_Name = @"SWAZILAND", ISO_3166_Alpha2Code = "SZ", ISO_3166_Alpha3Code = "SWZ", PhoneCode = "+268", CurrencyCode = "SZL", NetEntCountryName = "SWAZILAND" });
            countries.Add(new CountryInfo() { InternalID = 211, EnglishName = "Sweden", ISO_3166_Name = @"SWEDEN", ISO_3166_Alpha2Code = "SE", ISO_3166_Alpha3Code = "SWE", PhoneCode = "+46", CurrencyCode = "SEK", NetEntCountryName = "SWEDEN",
                                              IsPersonalIdVisible = true,
                                              IsPersonalIdMandatory = true,
                                              PersonalIdValidationRegularExpression = @"^(([\d]{6,6})|([\d]{8,8}))([-]|[\s]{1,1}){0,1}([\d]{4,4})$",
                                              PersonalIdMaxLength = 15,
                                            });
            countries.Add(new CountryInfo() { InternalID = 212, EnglishName = "Switzerland", ISO_3166_Name = @"SWITZERLAND", ISO_3166_Alpha2Code = "CH", ISO_3166_Alpha3Code = "CHE", PhoneCode = "+41", CurrencyCode = "CHF", NetEntCountryName = "SWITZERLAND" });
            countries.Add(new CountryInfo() { InternalID = 213, EnglishName = "Syrian Arab Republic", ISO_3166_Name = @"SYRIAN ARAB REPUBLIC", ISO_3166_Alpha2Code = "SY", ISO_3166_Alpha3Code = "SYR", PhoneCode = "+963", CurrencyCode = "SYP", NetEntCountryName = "SYRIAN ARAB REPUBLIC" });
            countries.Add(new CountryInfo() { InternalID = 214, EnglishName = "Taiwan, Province of China", ISO_3166_Name = @"TAIWAN, PROVINCE OF CHINA", ISO_3166_Alpha2Code = "TW", ISO_3166_Alpha3Code = "TWN", PhoneCode = "+886", CurrencyCode = "TWD", NetEntCountryName = "TAIWAN" });
            countries.Add(new CountryInfo() { InternalID = 215, EnglishName = "Tajikistan", ISO_3166_Name = @"TAJIKISTAN", ISO_3166_Alpha2Code = "TJ", ISO_3166_Alpha3Code = "TJK", PhoneCode = "+992", CurrencyCode = "TJR", NetEntCountryName = "TAJIKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 216, EnglishName = "Tanzania, United Republic of", ISO_3166_Name = @"TANZANIA, UNITED REPUBLIC OF", ISO_3166_Alpha2Code = "TZ", ISO_3166_Alpha3Code = "TZA", PhoneCode = "+255", CurrencyCode = "TZS", NetEntCountryName = "TANZANIA, UNITED REPUBLIC OF" });
            countries.Add(new CountryInfo() { InternalID = 217, EnglishName = "Thailand", ISO_3166_Name = @"THAILAND", ISO_3166_Alpha2Code = "TH", ISO_3166_Alpha3Code = "THA", PhoneCode = "+66", CurrencyCode = "THB", NetEntCountryName = "THAILAND" });
            countries.Add(new CountryInfo() { InternalID = 0, EnglishName = "Timor-Leste", ISO_3166_Name = @"TIMOR-LESTE", ISO_3166_Alpha2Code = "TL", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "", NetEntCountryName = "" });
            countries.Add(new CountryInfo() { InternalID = 218, EnglishName = "Togo", ISO_3166_Name = @"TOGO", ISO_3166_Alpha2Code = "TG", ISO_3166_Alpha3Code = "TGO", PhoneCode = "+228", CurrencyCode = "XOF", NetEntCountryName = "TOGO" });
            countries.Add(new CountryInfo() { InternalID = 219, EnglishName = "Tokelau", ISO_3166_Name = @"TOKELAU", ISO_3166_Alpha2Code = "TK", ISO_3166_Alpha3Code = "TKL", PhoneCode = "+690", CurrencyCode = "NZD", NetEntCountryName = "TOKELAU" });
            countries.Add(new CountryInfo() { InternalID = 220, EnglishName = "Tonga", ISO_3166_Name = @"TONGA", ISO_3166_Alpha2Code = "TO", ISO_3166_Alpha3Code = "TON", PhoneCode = "+676", CurrencyCode = "TOP", NetEntCountryName = "TONGA" });
            countries.Add(new CountryInfo() { InternalID = 221, EnglishName = "Trinidad and Tobago", ISO_3166_Name = @"TRINIDAD AND TOBAGO", ISO_3166_Alpha2Code = "TT", ISO_3166_Alpha3Code = "TTO", PhoneCode = "+1-868", CurrencyCode = "TTD", NetEntCountryName = "TRINIDAD AND TOBAGO" });
            countries.Add(new CountryInfo() { InternalID = 222, EnglishName = "Tunisia", ISO_3166_Name = @"TUNISIA", ISO_3166_Alpha2Code = "TN", ISO_3166_Alpha3Code = "TUN", PhoneCode = "+216", CurrencyCode = "TND", NetEntCountryName = "TUNISIA" });
            countries.Add(new CountryInfo() { InternalID = 223, EnglishName = "Turkey", ISO_3166_Name = @"TURKEY", ISO_3166_Alpha2Code = "TR", ISO_3166_Alpha3Code = "TUR", PhoneCode = "+90", CurrencyCode = "TRL", NetEntCountryName = "TURKEY" });
            countries.Add(new CountryInfo() { InternalID = 224, EnglishName = "Turkmenistan", ISO_3166_Name = @"TURKMENISTAN", ISO_3166_Alpha2Code = "TM", ISO_3166_Alpha3Code = "TKM", PhoneCode = "+993", CurrencyCode = "TMM", NetEntCountryName = "TURKMENISTAN" });
            countries.Add(new CountryInfo() { InternalID = 225, EnglishName = "Turks and Caicos Islands", ISO_3166_Name = @"TURKS AND CAICOS ISLANDS", ISO_3166_Alpha2Code = "TC", ISO_3166_Alpha3Code = "TCA", PhoneCode = "+1-649", CurrencyCode = "USD", NetEntCountryName = "TURKS AND CAICOS ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 226, EnglishName = "Tuvalu", ISO_3166_Name = @"TUVALU", ISO_3166_Alpha2Code = "TV", ISO_3166_Alpha3Code = "TUV", PhoneCode = "+688", CurrencyCode = "AUD", NetEntCountryName = "TUVALU" });
            countries.Add(new CountryInfo() { InternalID = 227, EnglishName = "Uganda", ISO_3166_Name = @"UGANDA", ISO_3166_Alpha2Code = "UG", ISO_3166_Alpha3Code = "UGA", PhoneCode = "+256", CurrencyCode = "UGX", NetEntCountryName = "UGANDA" });
            countries.Add(new CountryInfo() { InternalID = 228, EnglishName = "Ukraine", ISO_3166_Name = @"UKRAINE", ISO_3166_Alpha2Code = "UA", ISO_3166_Alpha3Code = "UKR", PhoneCode = "+380", CurrencyCode = "UAH", NetEntCountryName = "UKRAINE" });
            countries.Add(new CountryInfo() { InternalID = 229, EnglishName = "United Arab Emirates", ISO_3166_Name = @"UNITED ARAB EMIRATES", ISO_3166_Alpha2Code = "AE", ISO_3166_Alpha3Code = "ARE", PhoneCode = "+971", CurrencyCode = "AED", NetEntCountryName = "UNITED ARAB EMIRATES" });
            countries.Add(new CountryInfo() { InternalID = 230, EnglishName = "United Kingdom", ISO_3166_Name = @"UNITED KINGDOM", ISO_3166_Alpha2Code = "GB", ISO_3166_Alpha3Code = "GBR", PhoneCode = "+44", CurrencyCode = "GBP", NetEntCountryName = "UNITED KINGDOM" });
            countries.Add(new CountryInfo() { InternalID = 231, EnglishName = "United States", ISO_3166_Name = @"UNITED STATES", ISO_3166_Alpha2Code = "US", ISO_3166_Alpha3Code = "USA", PhoneCode = "+1", CurrencyCode = "USD", NetEntCountryName = "U S A" });
            countries.Add(new CountryInfo() { InternalID = 232, EnglishName = "United States Minor Outlying Islands", ISO_3166_Name = @"UNITED STATES MINOR OUTLYING ISLANDS", ISO_3166_Alpha2Code = "UM", ISO_3166_Alpha3Code = "   ", PhoneCode = "", CurrencyCode = "USD", NetEntCountryName = "UNITED STATES MINOR OUTLYING ISLANDS" });
            countries.Add(new CountryInfo() { InternalID = 233, EnglishName = "Uruguay", ISO_3166_Name = @"URUGUAY", ISO_3166_Alpha2Code = "UY", ISO_3166_Alpha3Code = "URY", PhoneCode = "+598", CurrencyCode = "UYU", NetEntCountryName = "URUGUAY" });
            countries.Add(new CountryInfo() { InternalID = 234, EnglishName = "Uzbekistan", ISO_3166_Name = @"UZBEKISTAN", ISO_3166_Alpha2Code = "UZ", ISO_3166_Alpha3Code = "UZB", PhoneCode = "+998", CurrencyCode = "UZS", NetEntCountryName = "UZBEKISTAN" });
            countries.Add(new CountryInfo() { InternalID = 235, EnglishName = "Vanuatu", ISO_3166_Name = @"VANUATU", ISO_3166_Alpha2Code = "VU", ISO_3166_Alpha3Code = "VUT", PhoneCode = "+678", CurrencyCode = "VUV", NetEntCountryName = "VANUATU" });
            countries.Add(new CountryInfo() { InternalID = 237, EnglishName = "Venezuela", ISO_3166_Name = @"VENEZUELA", ISO_3166_Alpha2Code = "VE", ISO_3166_Alpha3Code = "VEN", PhoneCode = "+58", CurrencyCode = "VEB", NetEntCountryName = "VENEZUELA" });
            countries.Add(new CountryInfo() { InternalID = 238, EnglishName = "Viet Nam", ISO_3166_Name = @"VIET NAM", ISO_3166_Alpha2Code = "VN", ISO_3166_Alpha3Code = "VNM", PhoneCode = "+84", CurrencyCode = "VND", NetEntCountryName = "VIET NAM" });
            countries.Add(new CountryInfo() { InternalID = 240, EnglishName = "Virgin Islands, British", ISO_3166_Name = @"VIRGIN ISLANDS, BRITISH", ISO_3166_Alpha2Code = "VG", ISO_3166_Alpha3Code = "VGB", PhoneCode = "+1-284", CurrencyCode = "USD", NetEntCountryName = "VIRGIN ISLANDS, BRITISH" });
            countries.Add(new CountryInfo() { InternalID = 239, EnglishName = "Virgin Islands, U.s.", ISO_3166_Name = @"VIRGIN ISLANDS, U.S.", ISO_3166_Alpha2Code = "VI", ISO_3166_Alpha3Code = "VIR", PhoneCode = "+1-340", CurrencyCode = "USD", NetEntCountryName = "VIRGIN ISLANDS, U.S." });
            countries.Add(new CountryInfo() { InternalID = 241, EnglishName = "Wallis and Futuna", ISO_3166_Name = @"WALLIS AND FUTUNA", ISO_3166_Alpha2Code = "WF", ISO_3166_Alpha3Code = "WLF", PhoneCode = "+681", CurrencyCode = "XPF", NetEntCountryName = "WALLIS AND FUTUNA" });
            countries.Add(new CountryInfo() { InternalID = 242, EnglishName = "Western Sahara", ISO_3166_Name = @"WESTERN SAHARA", ISO_3166_Alpha2Code = "EH", ISO_3166_Alpha3Code = "ESH", PhoneCode = "+212", CurrencyCode = "MAD", NetEntCountryName = "WESTERN SAHARA" });
            countries.Add(new CountryInfo() { InternalID = 243, EnglishName = "Yemen", ISO_3166_Name = @"YEMEN", ISO_3166_Alpha2Code = "YE", ISO_3166_Alpha3Code = "YEM", PhoneCode = "+967", CurrencyCode = "YER", NetEntCountryName = "YEMEN" });
            countries.Add(new CountryInfo() { InternalID = 245, EnglishName = "Zambia", ISO_3166_Name = @"ZAMBIA", ISO_3166_Alpha2Code = "ZM", ISO_3166_Alpha3Code = "ZMB", PhoneCode = "+260", CurrencyCode = "ZMK", NetEntCountryName = "Zaire see CONGO, THE DEMOCRATIC REPUBLIC OF THE  ZAMBIA" });
            countries.Add(new CountryInfo() { InternalID = 246, EnglishName = "Zimbabwe", ISO_3166_Name = @"ZIMBABWE", ISO_3166_Alpha2Code = "ZW", ISO_3166_Alpha3Code = "ZWE", PhoneCode = "+263", CurrencyCode = "ZWD", NetEntCountryName = "ZIMBABWE" });

            countries.Add(new CountryInfo() { 
                InternalID = 87,
                EnglishName = "Georgia",
                ISO_3166_Name = @"GEORGIA",
                ISO_3166_Alpha2Code = "GE",
                ISO_3166_Alpha3Code = "GEO",
                PhoneCode = "+995",
                CurrencyCode = "GEL",
                NetEntCountryName = "GEORGIA",
                IsPersonalIdVisible = true,
                IsPersonalIdMandatory = true,
                PersonalIdValidationRegularExpression = @"^(\d{11,11})$",
                PersonalIdMaxLength = 11,
            });
            #endregion

            List<string> dependedFiles = new List<string>();
            #region Load overriding configration
            try
            {
                string templateDomainDistinctName = SiteManager.GetSiteByDistinctName(domainDistinctName).TemplateDomainDistinctName;
                string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/countries.setting", domainDistinctName));
                dependedFiles.Add(path);
                string pathTemplate = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/countries.setting", templateDomainDistinctName));
                dependedFiles.Add(pathTemplate);
                if (!File.Exists(path))
                {
                    path = pathTemplate;
                }
                if (File.Exists(path))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    Hashtable table = null;
                    using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                    {
                        table = (Hashtable)bf.Deserialize(fs);
                    }

                    foreach (CountryInfo country in countries)
                    {
                        Hashtable innerTable = table[country.InternalID] as Hashtable;
                        if (innerTable != null)
                        {
                            foreach (DictionaryEntry entry in innerTable)
                            {
                                ObjectHelper.SetFieldValue(country, entry.Key as string, entry.Value);
                            }
                        }
                    }
                }
                #region load "Admin lock" from template site's setting
                if (!string.IsNullOrWhiteSpace(templateDomainDistinctName) && !string.Equals(domainDistinctName, templateDomainDistinctName, StringComparison.OrdinalIgnoreCase) && File.Exists(pathTemplate))
                {
                    BinaryFormatter bf = new BinaryFormatter();
                    Hashtable table = null;
                    using (FileStream fs = new FileStream(pathTemplate, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
                    {
                        table = (Hashtable)bf.Deserialize(fs);
                    }

                    foreach (CountryInfo country in countries)
                    {
                        Hashtable innerTable = table[country.InternalID] as Hashtable;
                        if (innerTable != null && innerTable.ContainsKey("AdminLock"))
                        {
                            country.AdminLock = (bool)innerTable["AdminLock"];
                        }
                    }
                }
                #endregion load "Admin lock" from template site's setting
            }
            catch (Exception ex)
            {
                Logger.Exception(ex);
            }
            #endregion

            HttpRuntime.Cache.Insert(cacheKey
                , countries
                , new CacheDependencyEx(dependedFiles.ToArray(), false)
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
        }

        return countries;
    }// GetAllCountries

    internal static void SaveCountries(RequestContext requestContext, string distinctName, Hashtable table)
    {        
        string path = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/countries.setting", distinctName));
        FileSystemUtility.EnsureDirectoryExist(path);

        string relativePath = "/.config/countries.setting";
        string name = "Countries";
        cmSite site = SiteManager.GetSiteByDistinctName(distinctName);

        Revisions.BackupIfNotExists(site, path, relativePath, name);
        
        BinaryFormatter bf = new BinaryFormatter();

        using (FileStream fs = new FileStream(path, FileMode.OpenOrCreate, FileAccess.Write, FileShare.Delete | FileShare.ReadWrite))
        {
            fs.SetLength(0L);
            bf.Serialize(fs, table);
            fs.Flush();
            fs.Close();
        }

        Revisions.Backup(site, path, relativePath, name);

        #region save "Admin lock" to template site's setting
        string templateDomainDistinctName = SiteManager.GetSiteByDistinctName(distinctName).TemplateDomainDistinctName;
        string pathTemplate = HostingEnvironment.MapPath(string.Format("~/Views/{0}/.config/countries.setting", templateDomainDistinctName));
        FileSystemUtility.EnsureDirectoryExist(pathTemplate);
        if (!string.IsNullOrWhiteSpace(templateDomainDistinctName) && !string.Equals(distinctName, templateDomainDistinctName, StringComparison.OrdinalIgnoreCase))
        {
            bf = new BinaryFormatter();
            Hashtable tableTemplate = null;
            using (FileStream fs = new FileStream(pathTemplate, FileMode.Open, FileAccess.Read, FileShare.Delete | FileShare.ReadWrite))
            {
                tableTemplate = (Hashtable)bf.Deserialize(fs);
            }

            Hashtable innerTable = null;
            Hashtable tempTable = null;
            foreach (int key in tableTemplate.Keys)
            {
                innerTable = tableTemplate[key] as Hashtable;
                tempTable = table[key] as Hashtable;
                if (innerTable != null && tempTable != null && tempTable.ContainsKey("AdminLock"))
                {
                    innerTable["AdminLock"] = tempTable["AdminLock"];
                }
            }

            cmSite siteTemplate = SiteManager.GetSiteByDistinctName(templateDomainDistinctName);
            Revisions.BackupIfNotExists(siteTemplate, pathTemplate, relativePath, name);

            bf = new BinaryFormatter();
            using (FileStream fs = new FileStream(pathTemplate, FileMode.OpenOrCreate, FileAccess.Write, FileShare.Delete | FileShare.ReadWrite))
            {
                fs.SetLength(0L);
                bf.Serialize(fs, tableTemplate);
                fs.Flush();
                fs.Close();
            }

            Revisions.Backup(siteTemplate, pathTemplate, relativePath, name);
        }
        #endregion save "Admin lock" to template site's setting
    }

    public static string[] GetAllPhonePrefix()
    {
        return new string[] {
            "+1","+1-242","+1-246","+1-264","+1-268","+1-340","+1-345","+1-441","+1-473","+1-649","+1-664","+1-670","+1-671","+1-758","+1-767","+1-784","+1-787/939","+1-809","+1-868","+1-869","+1-876","+20","+212","+213","+216","+218","+220","+221","+222","+224","+225","+226","+227","+228","+229","+230","+231","+232","+233","+234","+235","+236","+237","+238","+239","+240","+241","+242","+244","+245","+246","+248","+249","+250","+251","+252","+253","+254","+255","+256","+257","+258","+260","+261","+262","+263","+264","+265","+266","+267","+268","+269","+27","+290","+291","+297","+298","+299","+30","+31","+32","+33","+34","+350","+351","+352","+353","+354","+355","+356","+357","+358","+359","+36","+370","+371","+372","+373","+374","+375","+376","+377","+378","+380","+381","+382","+385","+386","+387","+389","+39","+39/379","+40","+41","+420","+421","+423","+43","+44","+45","+46","+47","+48","+49","+500","+501","+502","+503","+504","+505","+506","+507","+508","+509","+51","+52","+53","+54","+55","+56","+57","+58","+590","+591","+592","+593","+594","+595","+596","+597","+598","+599","+60","+61","+62","+63","+64","+65","+66","+670","+672","+673","+674","+675","+676","+677","+678","+679","+680","+681","+682","+683","+684","+686","+687","+688","+689","+690","+691","+692","+7","+81","+82","+84","+850","+852","+853","+855","+856","+86","+872","+880","+886","+90","+91","+92","+93","+94","+95","+960","+961","+962","+963","+964","+965","+966","+967","+968","+971","+972","+973","+974","+975","+976","+977","+98","+992","+993","+994","+995","+996","+998"
        };
    }

    private static List<cmRegion> GetAllRegions()
    {
        string cacheKey = "all_region_list";
        List<cmRegion> cache = HttpRuntime.Cache[cacheKey] as List<cmRegion>;
        if (cache != null)
            return cache;

        lock (typeof(cmRegion))
        {
            cache = HttpRuntime.Cache[cacheKey] as List<cmRegion>;
            if (cache != null)
                return cache;

            SqlQuery<cmRegion> query = new SqlQuery<cmRegion>();
            cache = query.SelectAll();

            HttpRuntime.Cache.Insert(cacheKey
                , cache
                , null
                , DateTime.Now.AddHours(1)
                , Cache.NoSlidingExpiration
                );
        }

        return cache;
    }

    /// <summary>
    /// Returns the country regions
    /// </summary>
    /// <param name="countryID"></param>
    /// <returns></returns>
    public static List<cmRegion> GetCountryRegions(int countryID)
    {
        return GetAllRegions().Where(r => r.CountryID == countryID).ToList();
    }

    public static bool IsFrenchNational(int countryID)
    {
        return countryID > 0 ? GetFrenchNationalIDs().Exists(c => c == countryID) : false;
    }
    
    public static List<int> GetFrenchNationalIDs()
    {
        //France:80, Reunion:181, Martinique:139, Guadeloupe:94, French Guiana:82, 
        //New Caledonia:157, French Polynesia:83, Wallis and Futuna:241,
        //French Southern Territories:84, Mayotte:142, Saint Pierre and Miquelon:206
        return new List<int> { 80, 82, 83, 84, 94, 139, 142, 157, 181, 206, 241 };
    }
}