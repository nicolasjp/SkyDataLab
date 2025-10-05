USE flights_discovery;

SELECT
    COD_CIE_IAT_2CA as airline_code,
    LIB_CIE_FRA as cie_label_fr,
    LIB_CIE_ANG as cie_label_en,
    DAT_DEB_VLD as start_validity_period,
    DAT_FIN_VLD as end_validity_period
FROM
    OPENROWSET(
        BULK 'REF_AIRLINES.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    ) AS [result]


-- Check doublons
SELECT
    COD_CIE_IAT_2CA, DAT_DEB_VLD, DAT_FIN_VLD, count(*) as record
FROM
    OPENROWSET(
        BULK 'REF_AIRLINES.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    ) AS [result]
GROUP BY COD_CIE_IAT_2CA, DAT_DEB_VLD, DAT_FIN_VLD
ORDER BY record DESC;

-- Création de la vue
CREATE OR ALTER VIEW airlines_View AS
SELECT
    COD_CIE_IAT_2CA,
    LIB_CIE_FRA,
    LIB_CIE_ANG,
    DAT_DEB_VLD,
    DAT_FIN_VLD
FROM
    OPENROWSET(
        BULK 'REF_AIRLINES.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    )
    WITH (
        COD_CIE_IAT_2CA VARCHAR(10) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        LIB_CIE_FRA VARCHAR(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        LIB_CIE_ANG VARCHAR(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        DAT_DEB_VLD VARCHAR(20) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        DAT_FIN_VLD VARCHAR(20) COLLATE Latin1_General_100_CI_AS_SC_UTF8
    ) AS [result];

-- select * 
-- from airlines_View
-- WHERE COD_CIE_IAT_2CA = 'AF'


-- select * 
-- from airlines_View
-- ORDER BY DAT_DEB_VLD DESC