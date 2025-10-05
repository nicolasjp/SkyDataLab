-- avec la vue cleaned
SELECT
  YEAR(sch_dep_datetime)              AS year,
  COUNT(*)                            AS flights_realized,
  SUM(ON_TIME_DEPARTURE)              AS flights_on_time,
  100.0 * SUM(ON_TIME_DEPARTURE) / COUNT(*) AS pct_on_time_departure
FROM vw_flights_pre_dataviz_cleaned
WHERE act_dep_datetime IS NOT NULL      -- réalisé
GROUP BY YEAR(sch_dep_datetime)
ORDER BY year;