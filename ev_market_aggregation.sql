-- 1. Count the existing chargers per zip code
WITH ChargerCounts AS (
    SELECT zip_code, COUNT(*) AS total_chargers
    FROM chargers
    GROUP BY zip_code
),

-- 2. Count the valid cinemas per zip code
CinemaCounts AS (
    SELECT zip_code, COUNT(*) AS total_cinemas
    FROM cinemas
    WHERE zip_code IS NOT NULL AND zip_code != ''
    GROUP BY zip_code
),

-- 3. Sum the total EVs per zip code
EVCounts AS (
    SELECT zip_code, SUM(Vehicles) AS total_evs
    FROM evs
    GROUP BY zip_code
)

-- 4. The Master Join and KPI Calculation
SELECT 
    e.zip_code,
    e.total_evs,
    COALESCE(ch.total_chargers, 0) AS total_chargers,
    COALESCE(ci.total_cinemas, 0) AS total_cinemas,
    -- CAST as FLOAT prevents SQLite from doing integer rounding
    CAST(e.total_evs AS FLOAT) / (COALESCE(ch.total_chargers, 0) + 1) AS opportunity_score
FROM EVCounts e
LEFT JOIN ChargerCounts ch ON e.zip_code = ch.zip_code
LEFT JOIN CinemaCounts ci ON e.zip_code = ci.zip_code
WHERE COALESCE(ci.total_cinemas, 0) > 0
ORDER BY opportunity_score DESC;