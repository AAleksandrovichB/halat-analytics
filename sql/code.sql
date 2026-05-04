-- техническая таблица для импорта данных о продажах
CREATE TABLE row_sales (
    sku TEXT
   ,product_name TEXT
   ,ssize TEXT
   ,color TEXT
   ,category TEXT
   ,subcategory TEXT
   ,gender TEXT
   ,quantity_row TEXT
   ,revenue_row TEXT
);
-- техническая таблица для импорта данных о себестоимости 
CREATE TABLE row_cost_price  (
    sku TEXT
   ,product_name TEXT
   ,characteristic TEXT
   ,color TEXT
   ,category TEXT
   ,subcategory TEXT
   ,gender TEXT
   ,unit_cost_row TEXT
);
-- приводим таблицу 'Продажи' к чистовому варианту
CREATE TABLE sales AS   
SELECT
    sku 
   ,product_name 
   ,ssize 
   ,color 
   ,category 
   ,subcategory 
   ,gender 
   ,CAST(quantity_row AS DECIMAL (10, 2)) AS quantity    -- меняем формат c текстового на числовой
   ,CAST(revenue_row AS DECIMAL (10, 2)) AS revenue      -- меняем формат c текстового на числовой
FROM row_sales
;
-- приводим таблицу 'себестоимости' к чистовому варианту
CREATE TABLE cost_price AS   
SELECT
    sku 
   ,product_name 
   ,characteristic 
   ,color 
   ,category 
   ,subcategory 
   ,gender 
   ,CAST(unit_cost_row AS DECIMAL (10, 2)) AS unit_cost
FROM row_cost_price
;
-- удаляем техническую таблицу 'продажи' таблицы
DROP TABLE row_sales
;
-- удаляем техническую таблицу 'себестоимости' таблицы
DROP TABLE row_cost_price
;
/* задание_1. указать артикула по убыванию прибыли за период - использовать сводную таблицу (всего два столбца).
   рассчитываем чистую маржинальность (contribution_margin) по каждому товару.
   формула: выручка - себестоимости - комиссия (15%) - логистика/комиссия (34%).*/
SELECT
    s.sku
   ,SUM(
       (s.revenue - cp.unit_cost * s.quantity)
       - (s.revenue * 0.15)
       - (s.revenue * 0.34)
    ) AS contribution_margin
FROM sales AS s
JOIN cost_price AS cp
    ON s.sku = cp.sku
   AND s.ssize = cp.characteristic
GROUP BY s.sku                        
ORDER BY contribution_margin DESC
;
/* задание_2. провести АВС анализ по махровым халатам */
-- подготавливаем основу(скелет)
WITH intermediate_table_1 AS (
SELECT
    s.sku
   ,SUM(s.revenue) AS total_revenue
   ,SUM(c.unit_cost * s.quantity) AS total_cost
   ,SUM(s.quantity) AS quantity
   ,SUM(
       (s.revenue - c.unit_cost * s.quantity)
       - (s.revenue * 0.15)
       - (s.revenue * 0.34) ) AS contribution_margin
FROM sales AS s
JOIN cost_price AS c ON s.sku = c.sku
					AND s.ssize = c.characteristic
WHERE s.category = 'Халат махровый'
GROUP BY s.sku
),

-- добавляем рентабельность и долю артикула в общей прибыли 
     intermediate_table_2 AS (
SELECT
    sku
   ,quantity
   ,total_revenue
   ,total_cost
   ,contribution_margin
   ,ROUND((contribution_margin / total_revenue * 100.0), 2) AS cm_ratio_pct
   ,ROUND(contribution_margin  / SUM(contribution_margin) OVER () * 100.0, 2) AS cm_share
FROM intermediate_table_1
),

--  добавляем накопительную долю прибыли, сортируем по убыванию прибыли
    intermediate_table_3 AS (
SELECT
    sku
   ,quantity
   ,total_revenue
   ,total_cost
   ,contribution_margin
   ,cm_ratio_pct
   ,cm_share
   ,SUM(cm_share) OVER (ORDER BY contribution_margin DESC) AS cm_cumulative
FROM intermediate_table_2
)

-- присваиваем abc rank
SELECT 
    sku
   ,quantity
   ,total_revenue
   ,total_cost
   ,contribution_margin
   ,cm_ratio_pct
   ,cm_share
   ,cm_cumulative
   ,CASE
   	WHEN cm_cumulative <= 80 THEN 'A'
   	WHEN cm_cumulative <= 95 THEN 'B'
   	ELSE 'C'
   END AS abc_rank
FROM intermediate_table_3
ORDER BY contribution_margin DESC
;







