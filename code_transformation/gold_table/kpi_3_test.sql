-- avec la vue cleaned
WITH cause_long AS (
  SELECT
    f.FLIGHT_CARRIER_CODE,
    f.FLIGHT_NUMBER,
    f.LEG_SCH_DEP_AIRPORT,
    f.sch_dep_datetime,
    YEAR(f.sch_dep_datetime) AS year_dep,
    d.label_cause
  FROM vw_flights_pre_dataviz_cleaned f
  CROSS APPLY (VALUES
    (f.LEG_DELAY_LIB_1),
    (f.LEG_DELAY_LIB_2),
    (f.LEG_DELAY_LIB_3),
    (f.LEG_DELAY_LIB_4),
    (f.LEG_DELAY_LIB_5)
  ) d(label_cause)
  WHERE f.NATIONAL_FLIGHT = 1
    AND NULLIF(TRIM(d.label_cause), '') IS NOT NULL
),
-- 1) Vraies causes (≠ UNKNOWN), une seule fois par vol et par cause
real_per_flight AS (
  SELECT DISTINCT
    c.FLIGHT_CARRIER_CODE,
    c.FLIGHT_NUMBER,
    c.LEG_SCH_DEP_AIRPORT,
    c.sch_dep_datetime,
    c.year_dep,
    c.label_cause
  FROM cause_long c
  WHERE UPPER(c.label_cause) <> 'UNKNOWN'
),
real_counts AS (
  SELECT
    year_dep,
    label_cause,
    COUNT(*) AS nb_flights
  FROM real_per_flight
  GROUP BY year_dep, label_cause
),
-- 2) Vols avec uniquement des UNKNOWN → on compte 1 UNKNOWN par vol
flights_all_unknown AS (
  SELECT
    c.FLIGHT_CARRIER_CODE,
    c.FLIGHT_NUMBER,
    c.LEG_SCH_DEP_AIRPORT,
    c.sch_dep_datetime,
    c.year_dep
  FROM cause_long c
  GROUP BY
    c.FLIGHT_CARRIER_CODE, c.FLIGHT_NUMBER, c.LEG_SCH_DEP_AIRPORT, c.sch_dep_datetime, c.year_dep
  HAVING SUM(CASE WHEN UPPER(c.label_cause) <> 'UNKNOWN' THEN 1 ELSE 0 END) = 0
),
unknown_counts AS (
  SELECT
    year_dep,
    'UNKNOWN' AS label_cause,
    COUNT(*) AS nb_flights
  FROM flights_all_unknown
  GROUP BY year_dep
),
all_counts AS (
  SELECT * FROM real_counts
  UNION ALL
  SELECT * FROM unknown_counts
)
SELECT year_dep, label_cause, nb_flights
FROM (
  SELECT
    year_dep, label_cause, nb_flights,
    ROW_NUMBER() OVER (PARTITION BY year_dep ORDER BY nb_flights DESC) AS rn
  FROM all_counts
) x
WHERE rn <= 3
ORDER BY year_dep, nb_flights DESC;