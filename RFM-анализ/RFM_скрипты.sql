WITH transactions AS (
SELECT
	card,
	COUNT(DATE(datetime)) AS frequency,
	MAX(datetime) AS last_purchase_date,
	SUM(summ_with_disc) AS monetary
FROM
	bonuscheques
WHERE
	card ~ '^[0-9]+$'
GROUP BY
	card
),
rfm AS (
SELECT
	card,
	EXTRACT(days
FROM
	DATE_TRUNC('day',
	'2022-06-09'::date) - DATE_TRUNC('day',
	last_purchase_date)) AS recency,
	frequency,
	monetary
FROM
	transactions
),
rfm_percentile AS (
SELECT
	card,
	recency,
	frequency,
	monetary,
	PERCENT_RANK() OVER (
ORDER BY
	recency) AS recency_percentile,
	PERCENT_RANK() OVER (
ORDER BY
	frequency) AS frequency_percentile,
	PERCENT_RANK() OVER (
ORDER BY
	monetary) AS monetary_percentile
FROM
	rfm),
rfm_class AS(
SELECT
	card,
	recency,
	frequency,
	monetary,
	CASE
		WHEN recency_percentile <= 0.33 THEN 1
		WHEN recency_percentile <= 0.66 THEN 2
		ELSE 3
	END AS recency_class,
	CASE
		WHEN frequency_percentile <= 0.33 THEN 3
		WHEN frequency_percentile <= 0.66 THEN 2
		ELSE 1
	END AS frequency_class,
	CASE
		WHEN monetary_percentile <= 0.33 THEN 3
		WHEN monetary_percentile <= 0.66 THEN 2
		ELSE 1
	END AS monetary_class
FROM
	rfm_percentile	
)
SELECT
	rfm,
	COUNT(DISTINCT card) AS card_count
FROM
	(
	SELECT
		card,
		recency,
		frequency,
		monetary,
		recency_class,
		frequency_class,
		monetary_class,
		CONCAT(recency_class,
		frequency_class,
		monetary_class) AS RFM
	FROM
		rfm_class
) AS rfm_counts
GROUP BY
	rfm
ORDER BY
	rfm;
