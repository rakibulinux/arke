CREATE DATABASE arke_development;

CREATE CONTINUOUS QUERY "cq_5m" ON arke_development
RESAMPLE EVERY 10s FOR 10m
BEGIN
  SELECT FIRST(open) as open, MAX(high) as high, MIN(low) as low, LAST(close) as close, SUM(volume) as volume INTO "candles_5m" FROM "candles_1m" GROUP BY time(5m), market, exchange
END
