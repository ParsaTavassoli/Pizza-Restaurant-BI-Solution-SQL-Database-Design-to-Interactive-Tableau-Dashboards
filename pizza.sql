-- 1.Total orders
-- 2.Total sales
-- 3.Total items
-- 4.Sales by category
-- 5.Top selling items
-- 6.Orders by hour
-- 7.Sales by hour
-- 8.Orders by address
-- 9.Orders by delivery/pick up
SELECT 
    o.order_id,
    i.item_price,
    o.quantity,
    i.item_cat,
    i.item_name,
    o.created_at,
    a.delivery_address1,
    a.delivery_address2,
    a.delivery_city,
    a.delivery_zipcode,
    o.delivery
FROM
    orders o
        LEFT JOIN
    item i ON o.item_id = i.item_id
        LEFT JOIN
    address a ON o.add_id = a.add_id;

-- Calculates staff working hours per shift and estimates the labor cost based on hourly rates
SELECT 
    r.date,
    s.first_name,
    s.last_name,
    s.hourly_rate,
    sh.start_time,
    sh.end_time,
    ((HOUR(TIMEDIFF(sh.end_time, sh.start_time)) * 60) + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time)))) / 60 AS hours_in_shift,
    ((HOUR(TIMEDIFF(sh.end_time, sh.start_time)) * 60) + (MINUTE(TIMEDIFF(sh.end_time, sh.start_time)))) / 60 * s.hourly_rate AS staff_cost
FROM
    rota r
        LEFT JOIN
    staff s ON r.staff_id = s.staff_id
        LEFT JOIN
    shift sh ON r.shift_id = sh.shift_id;
    
-- We need to calculate how much inventory we're using and then identify inventory that needs reordering.
-- We also want to calculate how much each pizza costs to make based on the cost of the ingredients so we can keep an eye on pricing and P/L.
-- Here is what we need:
-- 1. Total quantity by ingredient
-- 2. Total cost of ingredients
-- 3. Calculated cost of pizza
-- 4. Percentage stock remaining by ingredient
SELECT 
    s1.item_name,
    s1.ing_name,
    s1.ing_id,
    s1.ing_weight,
    s1.ing_price,
    s1.order_quantity,
    s1.recipe_quantity,
    (s1.order_quantity * s1.recipe_quantity) AS ordered_weight,
    (s1.ing_price / s1.ing_weight) AS unit_cost,
    ((s1.order_quantity * s1.recipe_quantity) * (s1.ing_price / s1.ing_weight)) AS ingredient_cost
FROM
    (SELECT 
        o.item_id,
            i.sku,
            i.item_name,
            r.ing_id,
            ing.ing_name,
            ing.ing_weight,
            ing.ing_price,
            SUM(o.quantity) AS order_quantity,
            r.quantity AS recipe_quantity
    FROM
        orders o
    LEFT JOIN item i ON o.item_id = i.item_id
    LEFT JOIN recipe r ON i.sku = r.recipe_id
    LEFT JOIN ingredient ing ON ing.ing_id = r.ing_id
    GROUP BY o.item_id , i.sku , i.item_name , r.ing_id , r.quantity , ing.ing_name , ing.ing_weight , ing.ing_price) s1;

SELECT 
    s2.ing_name,
    s2.ordered_weight,
    ing.ing_weight,
    inv.quantity,
    ing.ing_weight * inv.quantity AS total_inv_weight
FROM
    (SELECT 
        ing_id, ing_name, SUM(ordered_weight) AS ordered_weight
    FROM
        stock1
    GROUP BY ing_name , ing_id) s2
        LEFT JOIN
    inventory inv ON inv.item_id = s2.ing_id
        LEFT JOIN
    ingredient ing ON ing.ing_id = s2.ing_id;