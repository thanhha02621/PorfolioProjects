

SELECT TOP 10 * FROM payment_transaction
SELECT TOP 10 * FROM payment_scenario
SELECT TOP 10 * FROM payment_status

--Step 1: Calculate RFM metrics
/* - Recency: Difference between each customer's last payment date and '2019-12-31'
   - Frequency: Number of successful payment days of each customer
   - Monetary: Total charged amount of each customer */

WITH joined_table AS (
SELECT  txn.*
FROM payment_transaction txn
LEFT JOIN payment_status sta 
    ON txn.status_id = sta.status_id
WHERE status_description = 'Success'
)
, rfm_user AS (
SELECT customer_id
    , DATEDIFF(day, MAX(transaction_time), '2019-12-31' ) AS recency
    , COUNT(DISTINCT DAY(transaction_time)) AS frequency
    , SUM(charged_amount) AS monetary
FROM joined_table
GROUP BY customer_id --698 rows -> 689 khách hàng
)
, rfm_rank AS (
SELECT *
    , PERCENT_RANK() OVER (ORDER BY recency ASC) AS r_rank
    , PERCENT_RANK() OVER (ORDER BY frequency DESC) AS f_rank
    , PERCENT_RANK() OVER (ORDER BY monetary DESC) AS m_rank
FROM rfm_user 
)
, rfm_score AS (
SELECT * 
    , CASE 
        WHEN r_rank > 0.75 then 4
        WHEN r_rank > 0.5 then 3
        WHEN r_rank > 0.25 then 2
        ELSE 1
    END AS r_score
    , CASE 
        WHEN f_rank > 0.75 then 4
        WHEN f_rank > 0.5 then 3
        WHEN f_rank > 0.25 then 2
        ELSE 1
    END AS f_score
    , CASE 
        WHEN m_rank > 0.75 then 4
        WHEN m_rank > 0.5 then 3
        WHEN m_rank > 0.25 then 2
        ELSE 1
    END AS m_score
FROM rfm_rank
)
, final_score AS(
SELECT * 
    , CONCAT(r_score, f_score, m_score) AS rfm_score
FROM rfm_score
)
, group_score AS (
SELECT customer_id, rfm_score
FROM final_score
)
, segment_table AS (
SELECT *
    , CASE 
        WHEN rfm_score = 111 THEN 'Best Customers'
        WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customers'
        WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers'
        WHEN rfm_score LIKE '21[1-4]' THEN 'Almost Lost'
        WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
        WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders'
        WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers'
        WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating'
        WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists'
    ELSE 'unknown'
    END AS segment
FROM group_score
)
SELECT segment
    , COUNT(DISTINCT customer_id) AS number_customers
FROM segment_table
GROUP BY segment
ORDER BY number_customers DESC
    
