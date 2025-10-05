-- 1) Création de la table pré-dataviz (en fait une vue, car Synapse Serverless ne stocke pas)
CREATE OR ALTER VIEW vw_flights_pre_dataviz AS
WITH flights_enriched AS (
    SELECT
        f.FLIGHT_CARRIER_CODE,
        f.FLIGHT_NUMBER,
        f.LEG_SCH_DEP_AIRPORT,
        f.LEG_SCH_DEP_DATE_UTC,
        f.LEG_SCH_DEP_TIME_UTC,
        f.LEG_ACT_DEP_DATE_UTC,
        f.LEG_ACT_DEP_TIME_UTC,
        f.LEG_SCH_ARR_AIRPORT,
        f.LEG_SCH_ARR_DATE_UTC,
        f.LEG_SCH_ARR_TIME_UTC,
        f.LEG_ACT_ARR_DATE_UTC,
        f.LEG_ACT_ARR_TIME_UTC,
        f.LEG_DELAY_CODE_1,
        f.LEG_DELAY_CODE_2,
        f.LEG_DELAY_CODE_3,
        f.LEG_DELAY_CODE_4,
        f.LEG_DELAY_CODE_5,
        TRY_CONVERT(date, f.LEG_SCH_DEP_DATE_UTC, 103) AS sch_dep_date_convert,

        -- Horaires complets en DATETIME
        TRY_CONVERT(DATETIME, f.LEG_SCH_DEP_DATE_UTC + ' ' + f.LEG_SCH_DEP_TIME_UTC, 103) AS sch_dep_datetime,
        TRY_CONVERT(DATETIME, f.LEG_ACT_DEP_DATE_UTC + ' ' + f.LEG_ACT_DEP_TIME_UTC, 103) AS act_dep_datetime,
        TRY_CONVERT(DATETIME, f.LEG_SCH_ARR_DATE_UTC + ' ' + f.LEG_SCH_ARR_TIME_UTC, 103) AS sch_arr_datetime,
        TRY_CONVERT(DATETIME, f.LEG_ACT_ARR_DATE_UTC + ' ' + f.LEG_ACT_ARR_TIME_UTC, 103) AS act_arr_datetime,

        -- Colonnes calculées
        CASE
            WHEN f.LEG_ACT_DEP_DATE_UTC = '?' OR f.LEG_ACT_DEP_TIME_UTC = '?'
              OR f.LEG_ACT_ARR_DATE_UTC = '?' OR f.LEG_ACT_ARR_TIME_UTC = '?' THEN 0 -- annulé
            WHEN TRY_CONVERT(datetime, f.LEG_ACT_DEP_DATE_UTC + ' ' + f.LEG_ACT_DEP_TIME_UTC, 103) IS NULL
              OR TRY_CONVERT(datetime, f.LEG_SCH_DEP_DATE_UTC + ' ' + f.LEG_SCH_DEP_TIME_UTC, 103) IS NULL THEN 0
            WHEN TRY_CONVERT(datetime, f.LEG_ACT_DEP_DATE_UTC + ' ' + f.LEG_ACT_DEP_TIME_UTC, 103)
               <= TRY_CONVERT(datetime, f.LEG_SCH_DEP_DATE_UTC + ' ' + f.LEG_SCH_DEP_TIME_UTC, 103)
            THEN 1 ELSE 0
        END AS ON_TIME_DEPARTURE,

        CASE
            WHEN TRY_CONVERT(datetime, f.LEG_SCH_ARR_DATE_UTC + ' ' + f.LEG_SCH_ARR_TIME_UTC, 103) IS NOT NULL
             AND TRY_CONVERT(datetime, f.LEG_ACT_ARR_DATE_UTC + ' ' + f.LEG_ACT_ARR_TIME_UTC, 103) IS NOT NULL
            THEN DATEDIFF(
                    MINUTE,
                    TRY_CONVERT(datetime, f.LEG_SCH_ARR_DATE_UTC + ' ' + f.LEG_SCH_ARR_TIME_UTC, 103),
                    TRY_CONVERT(datetime, f.LEG_ACT_ARR_DATE_UTC + ' ' + f.LEG_ACT_ARR_TIME_UTC, 103)
                 )
        END AS ARRIVAL_DELAY_MINUTES
    FROM
        flights_View f -- vue nettoyée des vols
),
flights_with_aircraft AS (
    SELECT
        fe.*,
        a.AIRCRAFT_TYPE
    FROM flights_enriched fe
    LEFT JOIN aircraft_View a
        ON fe.FLIGHT_CARRIER_CODE = a.FLIGHT_CARRIER_CODE
       AND fe.FLIGHT_NUMBER = a.FLIGHT_NUMBER
),
flights_with_geo AS (
    SELECT
        fa.*,
        dep_country.COUNTRY_NAME AS COUNTRY_DEP,
        arr_country.COUNTRY_NAME AS COUNTRY_ARR,
        CASE WHEN dep_country.COUNTRY_NAME = arr_country.COUNTRY_NAME THEN 1 ELSE 0 END AS NATIONAL_FLIGHT
    FROM flights_with_aircraft fa
    LEFT JOIN airport_View dep_country
        ON fa.LEG_SCH_DEP_AIRPORT = dep_country.AIRPORT_CODE
    LEFT JOIN airport_View arr_country
        ON fa.LEG_SCH_ARR_AIRPORT = arr_country.AIRPORT_CODE
),
flights_with_airline AS (
    SELECT
        fg.*,
        al.LIB_CIE_FRA AS AIRLINE_NAME_FR,
        al.LIB_CIE_ANG AS AIRLINE_NAME_EN
    FROM flights_with_geo fg
    LEFT JOIN airlines_View al
      ON fg.FLIGHT_CARRIER_CODE = al.COD_CIE_IAT_2CA
     AND fg.sch_dep_date_convert
         BETWEEN ISNULL(TRY_CONVERT(date, al.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
         AND ISNULL(TRY_CONVERT(date, al.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
),
norm AS (
    SELECT
        fa.*,
        CASE WHEN TRIM(fa.LEG_DELAY_CODE_1) IN ('?', '') OR fa.LEG_DELAY_CODE_1 IS NULL THEN '##'
                ELSE TRIM(fa.LEG_DELAY_CODE_1) END AS NORM_DELAY_CODE_1,
        CASE WHEN TRIM(fa.LEG_DELAY_CODE_2) IN ('?', '') OR fa.LEG_DELAY_CODE_2 IS NULL THEN '##'
                ELSE TRIM(fa.LEG_DELAY_CODE_2) END AS NORM_DELAY_CODE_2,
        CASE WHEN TRIM(fa.LEG_DELAY_CODE_3) IN ('?', '') OR fa.LEG_DELAY_CODE_3 IS NULL THEN '##'
                ELSE TRIM(fa.LEG_DELAY_CODE_3) END AS NORM_DELAY_CODE_3,
        CASE WHEN TRIM(fa.LEG_DELAY_CODE_4) IN ('?', '') OR fa.LEG_DELAY_CODE_4 IS NULL THEN '##'
                ELSE TRIM(fa.LEG_DELAY_CODE_4) END AS NORM_DELAY_CODE_4,
        CASE WHEN TRIM(fa.LEG_DELAY_CODE_5) IN ('?', '') OR fa.LEG_DELAY_CODE_5 IS NULL THEN '##'
                ELSE TRIM(fa.LEG_DELAY_CODE_5) END AS NORM_DELAY_CODE_5
    FROM flights_with_airline fa
),
flights_with_delay_labels AS (
    SELECT
        n.*,
        d1.LIB_CSE_DLY_FRA AS LEG_DELAY_LIB_1,
        d2.LIB_CSE_DLY_FRA AS LEG_DELAY_LIB_2,
        d3.LIB_CSE_DLY_FRA AS LEG_DELAY_LIB_3,
        d4.LIB_CSE_DLY_FRA AS LEG_DELAY_LIB_4,
        d5.LIB_CSE_DLY_FRA AS LEG_DELAY_LIB_5
    FROM norm n
    -- on joint 5 fois le référentiel (par code) avec prise en compte des périodes de validité
    LEFT JOIN ref_Delay_View d1
      ON (CASE WHEN n.NORM_DELAY_CODE_1='##' THEN -1 ELSE TRY_CONVERT(int, n.NORM_DELAY_CODE_1) END)
       = (CASE WHEN d1.NUM_CSE_DLY='##' THEN -1 ELSE TRY_CONVERT(int, d1.NUM_CSE_DLY) END)
      AND n.sch_dep_date_convert
        BETWEEN ISNULL(TRY_CONVERT(date, d1.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
        AND ISNULL(TRY_CONVERT(date, d1.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
    LEFT JOIN ref_Delay_View d2
      ON (CASE WHEN n.NORM_DELAY_CODE_2='##' THEN -1 ELSE TRY_CONVERT(int, n.NORM_DELAY_CODE_2) END)
       = (CASE WHEN d2.NUM_CSE_DLY='##' THEN -1 ELSE TRY_CONVERT(int, d2.NUM_CSE_DLY) END)
      AND n.sch_dep_date_convert
        BETWEEN ISNULL(TRY_CONVERT(date, d2.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
        AND ISNULL(TRY_CONVERT(date, d2.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
    LEFT JOIN ref_Delay_View d3
      ON (CASE WHEN n.NORM_DELAY_CODE_3='##' THEN -1 ELSE TRY_CONVERT(int, n.NORM_DELAY_CODE_3) END)
       = (CASE WHEN d3.NUM_CSE_DLY='##' THEN -1 ELSE TRY_CONVERT(int, d3.NUM_CSE_DLY) END)
      AND n.sch_dep_date_convert
        BETWEEN ISNULL(TRY_CONVERT(date, d3.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
        AND ISNULL(TRY_CONVERT(date, d3.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
    LEFT JOIN ref_Delay_View d4
      ON (CASE WHEN n.NORM_DELAY_CODE_4='##' THEN -1 ELSE TRY_CONVERT(int, n.NORM_DELAY_CODE_4) END)
       = (CASE WHEN d4.NUM_CSE_DLY='##' THEN -1 ELSE TRY_CONVERT(int, d4.NUM_CSE_DLY) END)
      AND n.sch_dep_date_convert
        BETWEEN ISNULL(TRY_CONVERT(date, d4.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
        AND ISNULL(TRY_CONVERT(date, d4.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
    LEFT JOIN ref_Delay_View d5
      ON (CASE WHEN n.NORM_DELAY_CODE_5='##' THEN -1 ELSE TRY_CONVERT(int, n.NORM_DELAY_CODE_5) END)
       = (CASE WHEN d5.NUM_CSE_DLY='##' THEN -1 ELSE TRY_CONVERT(int, d5.NUM_CSE_DLY) END)
      AND n.sch_dep_date_convert
        BETWEEN ISNULL(TRY_CONVERT(date, d5.DAT_DEB_VLD, 103), CAST('1900-01-01' AS date))
        AND ISNULL(TRY_CONVERT(date, d5.DAT_FIN_VLD, 103), CAST('9999-12-31' AS date))
)
SELECT *
FROM flights_with_delay_labels;


-- Select top 10 *
-- from vw_flights_pre_dataviz
-- WHERE FLIGHT_CARRIER_CODE = 'AF' AND FLIGHT_NUMBER = '0063' AND LEG_SCH_DEP_AIRPORT = 'EWR' AND LEG_SCH_DEP_DATE_UTC = '01/02/2023'

-- Select top 10 *
-- from vw_flights_pre_dataviz
-- WHERE LEG_DELAY_LIB_1 is not null

-- SELECT *
-- from vw_flights_pre_dataviz
-- WHERE AIRCRAFT_TYPE = '33X' and ARRIVAL_DELAY_MINUTES > '100'

-- SELECT count(*)
-- from vw_flights_pre_dataviz
-- WHERE act_dep_datetime IS NOT NULL AND ON_TIME_DEPARTURE = 1 

-- SELECT *
-- from vw_flights_pre_dataviz
-- WHERE ARRIVAL_DELAY_MINUTES is null


-- 2) Création de la table pré-dataviz cleaned
CREATE OR ALTER VIEW vw_flights_pre_dataviz_cleaned AS
SELECT FLIGHT_CARRIER_CODE,
    FLIGHT_NUMBER,
    LEG_SCH_DEP_AIRPORT,
    sch_dep_date_convert,
    YEAR(sch_dep_date_convert) AS Year,
    FORMAT(sch_dep_date_convert, 'yyyy-MM') AS YearMonth,
    sch_dep_datetime,
    act_dep_datetime,
    sch_arr_datetime,
    act_arr_datetime,
    ON_TIME_DEPARTURE,
    ARRIVAL_DELAY_MINUTES,
    AIRCRAFT_TYPE,
    COUNTRY_DEP,
    COUNTRY_ARR,
    NATIONAL_FLIGHT,
    AIRLINE_NAME_FR,
    AIRLINE_NAME_EN,
    LEG_DELAY_LIB_1,
    LEG_DELAY_LIB_2,
    LEG_DELAY_LIB_3,
    LEG_DELAY_LIB_4,
    LEG_DELAY_LIB_5
FROM vw_flights_pre_dataviz

-- SELECT TOP 10 *
-- FROM vw_flights_pre_dataviz_cleaned

-- SELECT *
-- FROM vw_flights_pre_dataviz_cleaned


-- EXEC sp_describe_first_result_set N'
-- SELECT TOP 10 *
-- FROM vw_flights_pre_dataviz_cleaned'

-- SELECT *
-- FROM vw_flights_pre_dataviz
-- WHERE FLIGHT_CARRIER_CODE = 'AF' AND FLIGHT_NUMBER = '7717' AND LEG_SCH_DEP_AIRPORT = 'BIQ' AND sch_dep_date_convert = '2023-08-19'


