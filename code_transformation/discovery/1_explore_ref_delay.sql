CREATE DATABASE flights_discovery;
USE flights_discovery;

CREATE EXTERNAL DATA SOURCE flights_data
WITH(
    LOCATION = 'https://{storage_account}.dfs.core.windows.net/flights_data/'
)

SELECT
    *
FROM
    OPENROWSET(
        BULK 'REF_DELAY.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    ) AS [result]


-- Check taille stockage des champs
EXEC sp_describe_first_result_set N'SELECT
    *
FROM
    OPENROWSET(
        BULK ''REF_DELAY.csv'',
        DATA_SOURCE = ''flights_data'',
        FORMAT = ''CSV'',
        PARSER_VERSION = ''2.0'',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = '';''
    ) AS [result]'


-- Check doublons
SELECT
    NUM_CSE_DLY, DAT_DEB_VLD, DAT_FIN_VLD, count(*) as record
FROM
    OPENROWSET(
        BULK 'REF_DELAY.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    ) AS [result]
GROUP BY NUM_CSE_DLY, DAT_DEB_VLD, DAT_FIN_VLD;


-- Création de la vue
CREATE OR ALTER VIEW ref_Delay_View AS
SELECT
    NUM_CSE_DLY,  -- on tente de caster après lecture
    COD_CSE_DLY,
    LIB_CSE_DLY_FRA,
    LIB_CSE_DLY_ANG,
    COD_CLA_DLY,
    DAT_DEB_VLD,
    DAT_FIN_VLD
FROM
    OPENROWSET(
        BULK 'REF_DELAY.csv',
        DATA_SOURCE = 'flights_data',
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        HEADER_ROW = TRUE,
        FIELDTERMINATOR = ';'
    )
    WITH (
        NUM_CSE_DLY VARCHAR(10) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        COD_CSE_DLY VARCHAR(10) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        LIB_CSE_DLY_FRA VARCHAR(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        LIB_CSE_DLY_ANG VARCHAR(200) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        COD_CLA_DLY VARCHAR(10) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        DAT_DEB_VLD VARCHAR(20) COLLATE Latin1_General_100_CI_AS_SC_UTF8,
        DAT_FIN_VLD VARCHAR(20) COLLATE Latin1_General_100_CI_AS_SC_UTF8
    ) AS [result];


-- select * 
-- from ref_Delay_View
-- order by NUM_CSE_DLY 

-- SELECT * FROM ref_Delay_View WHERE NUM_CSE_DLY IS NULL;