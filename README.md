# 🍜 Case Study #1: Danny's Diner 
<img src="https://user-images.githubusercontent.com/81607668/127727503-9d9e7a25-93cb-4f95-8bd0-20b87cb4b459.png" alt="Image" width="500" height="520">

## 📚 Table of Contents
- [Business Task](#business-task)
- [Entity Relationship Diagram](#entity-relationship-diagram)
- [Question and Solution](#question-and-solution)

Please note that all the information regarding the case study has been sourced from the following link: [here](https://8weeksqlchallenge.com/case-study-1/). 

***

## Business Task
Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. 

***

## Entity Relationship Diagram

![image](https://user-images.githubusercontent.com/81607668/127271130-dca9aedd-4ca9-4ed8-b6ec-1e1920dca4a8.png)

***

## Question and Solution

Please join me in executing the queries using PostgreSQL on [DB Fiddle](https://www.db-fiddle.com/f/2rM8RAnq7h5LLDTzZiRWcd/138). It would be great to work together on the questions!

Additionally, I have also published this case study on [Medium](https://katiehuangx.medium.com/8-week-sql-challenge-case-study-week-1-dannys-diner-2ba026c897ab?source=friends_link&sk=ed355696f5a70ff8b3d5a1b905e5dabe).


**1. What is the total amount each customer spent at the restaurant?**

````sql
SELECT
    customer_id,
    SUM(price) AS total_amount_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;
````

#### Answer:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

- Customer A spent $76.
- Customer B spent $74.
- Customer C spent $36.

***

**2. How many days has each customer visited the restaurant?**

````sql
SELECT
    sales.customer_id,
    COUNT(DISTINCT sales.order_date) AS days_visited
FROM dannys_diner.sales
GROUP BY sales.customer_id;
````


#### Answer:
| customer_id | visit_count |
| ----------- | ----------- |
| A           | 4          |
| B           | 6          |
| C           | 2          |

- Customer A visited 4 times.
- Customer B visited 6 times.
- Customer C visited 2 times.

***

**3. What was the first item from the menu purchased by each customer?**

````sql
WITH cte AS (
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
````


#### Answer:
| customer_id | product_name | 
| ----------- | ----------- |
| A           | curry        | 
| A           | sushi        | 
| B           | curry        | 
| C           | ramen        |

- Customer A placed an order for both curry and sushi simultaneously, making them the first items in the order.
- Customer B's first order is curry.
- Customer C's first order is ramen.

***

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

````sql
SELECT
    menu.product_name,
    COUNT(menu.product_name) AS order_count
FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY order_count DESC
LIMIT 1;
````


#### Answer:
| most_purchased | product_name | 
| ----------- | ----------- |
| 8       | ramen |


***

**5. Which item was the most popular for each customer?**

````sql
WITH item_count AS (
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
````

*Each user may have more than 1 favourite item.*

#### Answer:
| customer_id | product_name | order_count |
| ----------- | ---------- |------------  |
| A           | ramen        |  3   |
| B           | sushi        |  2   |
| B           | curry        |  2   |
| B           | ramen        |  2   |
| C           | ramen        |  3   |


***

**6. Which item was purchased first by the customer after they became a member?**

```sql
WITH joined_as_member AS (
    SELECT
        members.customer_id,
        sales.product_id,
        ROW_NUMBER() OVER(PARTITION BY members.customer_id ORDER BY sales.order_date) AS row_num
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
```

#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | ramen        |
| B           | sushi        |

- Customer A's first order as a member is ramen.
- Customer B's first order as a member is sushi.

***

**7. Which item was purchased just before the customer became a member?**

````sql
WITH purchased_prior_member AS (
    SELECT
        members.customer_id,
        sales.product_id,
        ROW_NUMBER() OVER (PARTITION BY members.customer_id ORDER BY sales.order_date DESC) AS row_rank
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
````

#### Answer:
| customer_id | product_name |
| ----------- | ---------- |
| A           | sushi        |
| B           | sushi        |

- Both customers' last order before becoming members are sushi.

***

**8. What is the total items and amount spent for each member before they became a member?**

```sql
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
```

#### Answer:
| customer_id | total_items | total_sales |
| ----------- | ---------- |----------  |
| A           | 2 |  25       |
| B           | 3 |  40       |


***

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?**

```sql
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
```

#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 860 |
| B           | 940 |
| C           | 360 |


***

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi — how many points do customer A and B have at the end of January?**

```sql
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
INNER JOIN dannys_diner.menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY points DESC;
```


#### Answer:
| customer_id | total_points | 
| ----------- | ---------- |
| A           | 1020 |
| B           | 320 |


***

## BONUS QUESTIONS

**Join All The Things**

**Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)**

```sql
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
```
 
#### Answer: 
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

**Rank All The Things**

**Danny also requires further information about the ```ranking``` of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ```ranking``` values for the records when customers are not yet part of the loyalty program.**

```sql
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
```

#### Answer: 
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL
| A           | 2021-01-01 | curry        | 15    | N      | NULL
| A           | 2021-01-07 | curry        | 15    | Y      | 1
| A           | 2021-01-10 | ramen        | 12    | Y      | 2
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| A           | 2021-01-11 | ramen        | 12    | Y      | 3
| B           | 2021-01-01 | curry        | 15    | N      | NULL
| B           | 2021-01-02 | curry        | 15    | N      | NULL
| B           | 2021-01-04 | sushi        | 10    | N      | NULL
| B           | 2021-01-11 | sushi        | 10    | Y      | 1
| B           | 2021-01-16 | ramen        | 12    | Y      | 2
| B           | 2021-02-01 | ramen        | 12    | Y      | 3
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-01 | ramen        | 12    | N      | NULL
| C           | 2021-01-07 | ramen        | 12    | N      | NULL

***
