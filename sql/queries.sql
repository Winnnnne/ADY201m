
-- Step 3: sql/queries.sql
CREATE OR REPLACE TABLE pm AS SELECT * FROM 'data/processed/pems_d4.parquet';
-- Q1: weekly speed profile by freeway and direction; Tuesday to Thursday (office days) versus Monday and Friday
SELECT Fwy, Dir, dayofweek(ts) AS dow, hour(ts) AS hr, AVG(speed) AS speed FROM pm GROUP BY 1, 2, 3, 4 ORDER BY 1, 2, 3, 4;
-- Q2: congestion share (speed below 45 mph) per station, top 20; rain effect
SELECT station, Fwy, AVG((speed < 45)::INT) AS congested_share FROM pm GROUP BY 1, 2 ORDER BY 3 DESC LIMIT 20;
SELECT (prcp > 0) AS rain, AVG((speed < 45)::INT) AS congested_share FROM pm WHERE hour(ts) BETWEEN 7 AND 9 GROUP BY 1;
-- Q3: features and targets 15, 30, 60 minutes ahead
CREATE OR REPLACE TABLE feat AS
SELECT station, Fwy, ts, speed, total_flow, occupancy, Lanes, temp, prcp, hour(ts) AS hr, dayofweek(ts) AS dow,
       LAG(speed, 1) OVER w AS s_lag1, LAG(speed, 4) OVER w AS s_lag4, LAG(speed, 96) OVER w AS s_lag1d, LAG(speed, 672) OVER w AS s_lag1w, AVG(speed) OVER (w ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS s_ma1h,
       LAG(total_flow, 1) OVER w AS f_lag1, LEAD(speed, 1) OVER w AS y_15m, LEAD(speed, 2) OVER w AS y_30m, LEAD(speed, 4) OVER w AS y_60m
FROM pm WINDOW w AS (PARTITION BY station ORDER BY ts);
SELECT COUNT(*) AS n, COUNT(y_60m) AS n60 FROM feat;
