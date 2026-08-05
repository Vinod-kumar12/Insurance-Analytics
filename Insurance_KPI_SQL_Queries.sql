
-- 1. Total number of customers
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM customer_information;


-- 2. Total number of policies issued
SELECT COUNT(DISTINCT policy_id) AS total_policies
FROM policy_details;


-- 3. Total claim amount generated from all policies
SELECT SUM(claim_amount) AS total_claim_amount
FROM claims;


-- 4. Average coverage amount per policy
SELECT AVG(coverage_amount) AS avg_coverage_amount
FROM policy_details;


-- 5. Average premium amount collected per policy
SELECT AVG(premium_amount) AS avg_premium_amount
FROM policy_details;


-- 6. Percentage of policies currently active
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END)
        / COUNT(*), 2
    ) AS pct_active_policies
FROM policy_details;


-- 7. Count of policies by status: Active / Lapsed / Terminated
SELECT status, COUNT(*) AS policy_count
FROM policy_details
GROUP BY status
ORDER BY policy_count DESC;


-- 8. Policy status with the highest number of policies
SELECT status, COUNT(*) AS policy_count
FROM policy_details
GROUP BY status
ORDER BY policy_count DESC
LIMIT 1;


-- 9. Ratio between active and inactive policies
SELECT
    SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END) AS active_count,
    SUM(CASE WHEN status <> 'Active' THEN 1 ELSE 0 END) AS inactive_count,
    ROUND(
        1.0 * SUM(CASE WHEN status = 'Active' THEN 1 ELSE 0 END)
        / NULLIF(SUM(CASE WHEN status <> 'Active' THEN 1 ELSE 0 END), 0)
    , 2) AS active_to_inactive_ratio
FROM policy_details;


-- 10. Age group with the highest number of policies
WITH age_groups AS (
    SELECT
        p.policy_id,
        CASE
            WHEN c.age < 25 THEN '18-24'
            WHEN c.age < 35 THEN '25-34'
            WHEN c.age < 45 THEN '35-44'
            WHEN c.age < 55 THEN '45-54'
            WHEN c.age < 65 THEN '55-64'
            ELSE '65+'
        END AS age_group
    FROM policy_details p
    JOIN customer_information c ON p.customer_id = c.customer_id
)
SELECT age_group, COUNT(*) AS policy_count
FROM age_groups
GROUP BY age_group
ORDER BY policy_count DESC
LIMIT 1;


-- 11. Top 3 age groups by policy count
WITH age_groups AS (
    SELECT
        p.policy_id,
        CASE
            WHEN c.age < 25 THEN '18-24'
            WHEN c.age < 35 THEN '25-34'
            WHEN c.age < 45 THEN '35-44'
            WHEN c.age < 55 THEN '45-54'
            WHEN c.age < 65 THEN '55-64'
            ELSE '65+'
        END AS age_group
    FROM policy_details p
    JOIN customer_information c ON p.customer_id = c.customer_id
)
SELECT age_group, COUNT(*) AS policy_count
FROM age_groups
GROUP BY age_group
ORDER BY policy_count DESC
LIMIT 3;


-- 12. Gender with the highest policy participation
SELECT c.gender, COUNT(p.policy_id) AS policy_count
FROM policy_details p
JOIN customer_information c ON p.customer_id = c.customer_id
GROUP BY c.gender
ORDER BY policy_count DESC
LIMIT 1;


-- 13. Difference between male and female policy counts
SELECT
    SUM(CASE WHEN c.gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN c.gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN c.gender = 'Male' THEN 1 ELSE 0 END)
      - SUM(CASE WHEN c.gender = 'Female' THEN 1 ELSE 0 END) AS male_female_diff
FROM policy_details p
JOIN customer_information c ON p.customer_id = c.customer_id;


-- 14. Policy type with the maximum number of policies
SELECT policy_type, COUNT(*) AS policy_count
FROM policy_details
GROUP BY policy_type
ORDER BY policy_count DESC
LIMIT 1;


-- 15. Policy type with the minimum number of policies
SELECT policy_type, COUNT(*) AS policy_count
FROM policy_details
GROUP BY policy_type
ORDER BY policy_count ASC
LIMIT 1;


-- 16. Compare Auto and Health policy counts
SELECT policy_type, COUNT(*) AS policy_count
FROM policy_details
WHERE policy_type IN ('Auto', 'Health')
GROUP BY policy_type
ORDER BY policy_count DESC;


-- 17. Total number of policies across all policy types
SELECT policy_type, COUNT(*) AS policy_count
FROM policy_details
GROUP BY policy_type
ORDER BY policy_count DESC;
-- Grand total check:
SELECT COUNT(*) AS total_policies_all_types
FROM policy_details;


-- 18. Average premium growth rate over all years
WITH yearly_premium AS (
    SELECT
        EXTRACT(YEAR FROM policy_start_date) AS policy_year,
        SUM(premium_amount) AS total_premium
    FROM policy_details
    GROUP BY EXTRACT(YEAR FROM policy_start_date)
),
growth AS (
    SELECT
        policy_year,
        total_premium,
        LAG(total_premium) OVER (ORDER BY policy_year) AS prev_year_premium,
        (total_premium - LAG(total_premium) OVER (ORDER BY policy_year))
            / NULLIF(LAG(total_premium) OVER (ORDER BY policy_year), 0) AS growth_rate
    FROM yearly_premium
)
SELECT ROUND(AVG(growth_rate) * 100, 2) AS avg_premium_growth_rate_pct
FROM growth
WHERE growth_rate IS NOT NULL;


-- 19. Premium growth trend increasing or decreasing over time
-- (run this and look at the trend of growth_rate/total_premium year over year)
WITH yearly_premium AS (
    SELECT
        EXTRACT(YEAR FROM policy_start_date) AS policy_year,
        SUM(premium_amount) AS total_premium
    FROM policy_details
    GROUP BY EXTRACT(YEAR FROM policy_start_date)
)
SELECT
    policy_year,
    total_premium,
    LAG(total_premium) OVER (ORDER BY policy_year) AS prev_year_premium,
    ROUND(
        100.0 * (total_premium - LAG(total_premium) OVER (ORDER BY policy_year))
        / NULLIF(LAG(total_premium) OVER (ORDER BY policy_year), 0)
    , 2) AS growth_rate_pct
FROM yearly_premium
ORDER BY policy_year;


-- 20. Difference between highest and lowest premium growth rates
WITH yearly_premium AS (
    SELECT
        EXTRACT(YEAR FROM policy_start_date) AS policy_year,
        SUM(premium_amount) AS total_premium
    FROM policy_details
    GROUP BY EXTRACT(YEAR FROM policy_start_date)
),
growth AS (
    SELECT
        policy_year,
        (total_premium - LAG(total_premium) OVER (ORDER BY policy_year))
            / NULLIF(LAG(total_premium) OVER (ORDER BY policy_year), 0) AS growth_rate
    FROM yearly_premium
)
SELECT
    ROUND(MAX(growth_rate) * 100, 2) AS max_growth_rate_pct,
    ROUND(MIN(growth_rate) * 100, 2) AS min_growth_rate_pct,
    ROUND((MAX(growth_rate) - MIN(growth_rate)) * 100, 2) AS growth_rate_range_pct
FROM growth
WHERE growth_rate IS NOT NULL;


-- 21. Yearly trend of policies ending from 2016 to 2034
SELECT
    EXTRACT(YEAR FROM policy_end_date) AS end_year,
    COUNT(*) AS policies_ending
FROM policy_details
WHERE EXTRACT(YEAR FROM policy_end_date) BETWEEN 2016 AND 2034
GROUP BY EXTRACT(YEAR FROM policy_end_date)
ORDER BY end_year;
