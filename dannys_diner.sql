CREATE SCHEMA dannys_diner; 
USE dannys_diner;

CREATE TABLE sales ( 
	customer_id VARCHAR(1), 
    order_date DATE, 
    product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
  
CREATE TABLE menu (
	product_id INTEGER, 
    product_name VARCHAR(5), 
    price INTEGER 
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
 
CREATE TABLE members ( 
	customer_id VARCHAR(1), 
    join_date DATE 
);

INSERT INTO members 
	(customer_id, join_date) 
VALUES 
	('A', '2021-01-07'),
    ('B', '2021-01-09');

SELECT * FROM sales; 
SELECT * FROM menu;
SELECT * FROM members;

-- ----------------- CASE STUDY QUESTIONS ---------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant ?
SELECT
    customer_id,
    SUM(price) AS total_amount_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant? 

SELECT
    sales.customer_id,
    COUNT(DISTINCT sales.order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY sales.customer_id;


-- 3. What was the first item from the menu purchased by each customer?
WITH cte AS
(
    SELECT
        sales.customer_id,
        menu.product_name,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) AS row_num
    FROM dannys_diner.sales
    JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
)
SELECT
    customer_id,
    product_name
FROM cte
WHERE row_num = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT
    menu.product_name,
    COUNT(menu.product_name) AS order_count
FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY order_count DESC
LIMIT 1;


-- 5. Which item was the most popular for each customer?
WITH item_count AS
    (
    SELECT
        sales.customer_id,
        menu.product_name,
        COUNT(*) AS order_count,
        DENSE_RANK() OVER(PARTITION BY sales.customer_id ORDER BY COUNT(*) DESC) AS rn
    FROM dannys_diner.sales
    JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
    GROUP BY sales.customer_id, menu.product_name
    )
SELECT
    customer_id,
    product_name
FROM item_count
WHERE rn = 1;


-- 6. Which item was purchased first by the customer before they became a member?

WITH joined_as_member AS (
    SELECT
        members.customer_id,
        sales.product_id,
        ROW_NUMBER() OVER(
            PARTITION BY  members.customer_id
            ORDER BY sales.order_date) AS row_num
    FROM dannys_diner.members
    INNER JOIN dannys_diner.sales
        ON members.customer_id = sales.customer_id
        AND sales.order_date > members.join_date
)

SELECT
    customer_id,
    product_name
FROM joined_as_member
INNER JOIN dannys_diner.menu
    ON joined_as_member.product_id = menu.product_id
WHERE row_num = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH purchased_prior_member AS (
    SELECT
        members.customer_id,
        sales.product_id,
        ROW_NUMBER() OVER (
            PARTITION BY members.customer_id
            ORDER BY sales.order_date DESC) AS row_rank
    FROM dannys_diner.members
    INNER JOIN dannys_diner.sales
        ON members.customer_id = sales.customer_id
        AND sales.order_date < members.join_date
)
SELECT
    p_member.customer_id,
    menu.product_name
FROM purchased_prior_member AS p_member
INNER JOIN dannys_diner.menu
    ON p_member.product_id = menu.product_id
WHERE row_rank = 1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
    sales.customer_id,
    COUNT(sales.product_id) AS total_item,
    SUM(menu.price) AS total_sales
FROM dannys_diner.sales
INNER JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
    AND sales.order_date < members.join_date
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has 2x points multiplier - how many points would each customer have?
WITH point_cte AS (
    SELECT
        menu.product_id,
        CASE
            WHEN menu.product_id = 1 THEN price * 20
            ELSE price * 10
        END AS points
    FROM dannys_diner.menu
)
SELECT
    sales.customer_id,
    SUM(point_cte.points) AS total_points
FROM dannys_diner.sales
INNER JOIN point_cte
    ON sales.product_id = point_cte.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
-- - how many points do customer A and B have at the end of January?

WITH dates_cte AS (
    SELECT
        customer_id,
        join_date,
        DATE_ADD(join_date, INTERVAL 6 DAY) AS valid_date,
        LAST_DAY('2021-01-31') AS last_date
    FROM dannys_diner.members
)
SELECT
    sales.customer_id,
    SUM(
        CASE
            WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
            WHEN sales.order_date BETWEEN dates_cte.join_date AND dates_cte.valid_date THEN 2 * 10 * menu.price
            ELSE 10 * menu.price
        END
    ) AS points
FROM dannys_diner.sales
INNER JOIN dates_cte
    ON sales.customer_id = dates_cte.customer_id
    AND dates_cte.join_date <= sales.order_date
    AND sales.order_date <= dates_cte.last_date
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY points DESC;


-- -------------------------- BONUS QUESTIONS ----------------------------------------------------------------------

-- Join All Things
-- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)

SELECT
    sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
        WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END AS member_status
FROM dannys_diner.sales
LEFT JOIN dannys_diner.members
    ON sales.customer_id = members.customer_id
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
ORDER BY members.customer_id, sales.order_date;


-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking
-- for non-members purchase so he expects null ranking values for the records when customers are not yet part of the loyalty program

WITH customer_data AS (
    SELECT
        sales.customer_id,
        sales.order_date,
        menu.product_name,
        menu.price,
        CASE
            WHEN members.join_date > sales.order_date THEN 'N'
            WHEN members.join_date <= sales.order_date THEN 'Y'
            ELSE 'N'
        END AS member_status
    FROM dannys_diner.sales
    LEFT JOIN dannys_diner.members
        ON sales.customer_id = members.customer_id
    INNER JOIN dannys_diner.menu
        ON sales.product_id = menu.product_id
)

SELECT
    *,
    CASE
        WHEN member_status = 'N' THEN NULL
        ELSE RANK () OVER(
            PARTITION BY customer_id, member_status
            ORDER BY order_date
            )
    END AS ranking
FROM customer_data;