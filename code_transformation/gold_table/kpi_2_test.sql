-- Par “retard”, on prend le positif uniquement (si un vol arrive en avance, on compte 0).
-- avec la vue cleaned
SELECT
  YEAR(sch_arr_datetime) AS year,
  AIRCRAFT_TYPE,
  AVG(CASE WHEN ARRIVAL_DELAY_MINUTES < 0 THEN 0 ELSE ARRIVAL_DELAY_MINUTES END) AS avg_arrival_delay_minutes,
  COUNT(*) AS flights_realized
FROM vw_flights_pre_dataviz_cleaned
WHERE act_arr_datetime IS NOT NULL
GROUP BY YEAR(sch_arr_datetime), AIRCRAFT_TYPE
ORDER BY year, avg_arrival_delay_minutes DESC;