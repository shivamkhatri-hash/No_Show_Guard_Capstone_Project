-- ============================================================================
-- Task 2.4 – Month-by-Month Trend (CTE + LAG)
-- ============================================================================
WITH monthly AS (
    SELECT
        SUBSTR(appt_date, 1, 7) AS month,
        COUNT(*) AS appointments,
        ROUND(100.0 * SUM(no_show) / COUNT(*), 1) AS no_show_pct
    FROM appointments
    GROUP BY SUBSTR(appt_date, 1, 7)
)
SELECT
    month,
    appointments,
    no_show_pct,
    ROUND(
        no_show_pct - LAG(no_show_pct) OVER (ORDER BY month),
        1
    ) AS change_pp
FROM monthly
ORDER BY month;
