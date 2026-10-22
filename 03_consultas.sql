-- =====================================================================
-- Proyecto SQL: Análisis de ventas de una tienda en línea
-- Autora: Alejandra Osorio
-- Motor: MySQL 8
-- 20 preguntas de negocio y 8 retos, en 4 niveles de dificultad:
--   Nivel 1: consultas a una tabla (preguntas 1-5, retos A-B)
--   Nivel 2: JOIN (preguntas 6-10, retos C-D)
--   Nivel 3: HAVING, CASE y subconsultas (preguntas 11-15, retos E-F)
--   Nivel 4: CTE y funciones de ventana (preguntas 16-20, retos G-H)
-- =====================================================================

USE tienda_ventas;

-- Pregunta 1. ¿Cuántos clientes tenemos en cada ciudad?

SELECT ciudad,  COUNT(*) AS total_clientes
FROM clientes
GROUP BY ciudad
ORDER BY total_clientes DESC; 

-- Pregunta 2. ¿Cuáles son los 5 productos más caros? 

SELECT nombre_producto, precio_unitario
FROM productos
ORDER BY precio_unitario DESC
LIMIT 5;

-- Pregunta 3. ¿Cuántos pedidos hay en cada estado? 

SELECT estado, COUNT(*) AS total_pedidos
FROM pedidos
GROUP BY estado
ORDER BY total_pedidos DESC;

-- Pregunta 4. ¿Cuántos clientes no tienen correo registrado? 

SELECT COUNT(*) AS clientes_sin_email
FROM clientes
WHERE email IS NULL;

-- Pregunta 5. ¿Cuántos pedidos se hicieron por año y por canal? 

SELECT YEAR(fecha_pedido) AS anio, canal, COUNT(*) AS total_pedidos
FROM pedidos
GROUP BY anio, canal 
ORDER BY anio, total_pedidos DESC;

-- Reto A: ¿Cuántos productos hay en cada categoría? Usa la tabla productos y agrupa por id_categoria. 

SELECT id_categoria, COUNT(*) AS total_productos
FROM productos 
GROUP BY id_categoria
ORDER BY total_productos DESC; 

-- Reto B: ¿cuántos pedidos se pagaron con cada método de pago en 2025?

SELECT metodo_pago, COUNT(*) AS total_pedidos
FROM pedidos
WHERE YEAR(fecha_pedido) = 2025
GROUP BY metodo_pago
ORDER BY total_pedidos DESC;

-- Pregunta 6. ¿Cuántos productos hay en cada categoría, con su nombre? 

SELECT c.nombre_categoria, COUNT(*) AS total_productos
FROM productos p 
JOIN categorias c ON p.id_categoria = c.id_categoria
GROUP BY c.nombre_categoria
ORDER BY total_productos DESC;

-- Pregunta 7. ¿Cuánto vendió la tienda cada año? 

SELECT YEAR(p.fecha_pedido) AS anio,
       ROUND(SUM(d.cantidad * d.precio_unitario * (1 - d.descuento))) AS ventas
FROM pedidos p
JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
WHERE p.estado = 'Entregado'
GROUP BY anio
ORDER BY anio;

-- Pregunta 8. ¿Cuánto se vendió por categoría? 

SELECT c.nombre_categoria,
       ROUND(SUM(d.cantidad * d.precio_unitario * (1 - d.descuento))) AS ventas
FROM detalle_pedido d
JOIN pedidos p ON d.id_pedido = p.id_pedido
JOIN productos pr ON d.id_producto = pr.id_producto
JOIN categorias c ON pr.id_categoria = c.id_categoria
WHERE p.estado = 'Entregado'
GROUP BY c.nombre_categoria
ORDER BY ventas DESC;

-- Pregunta 9. ¿Quiénes son los 10 mejores clientes?

SELECT CONCAT(cl.nombre, ' ', cl.apellido) AS cliente,
       cl.ciudad,
       COUNT(DISTINCT p.id_pedido) AS pedidos,
       ROUND(SUM(d.cantidad * d.precio_unitario * (1 - d.descuento))) AS total_comprado
FROM clientes cl
JOIN pedidos p        ON cl.id_cliente = p.id_cliente
JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
WHERE p.estado = 'Entregado'
GROUP BY cl.id_cliente, cliente, cl.ciudad
ORDER BY total_comprado DESC
LIMIT 10;

-- Pregunta 10. ¿Cuántos clientes registrados nunca han comprado? 

SELECT COUNT(*) AS clientes_sin_pedidos
FROM clientes cl
LEFT JOIN pedidos p ON cl.id_cliente = p.id_cliente
WHERE p.id_pedido IS NULL;

-- Reto C: ¿Cuánto se vendió en cada ciudad? Pista: une clientes, pedidos y detalle_pedido, y agrupa por cl.ciudad


SELECT c.ciudad,
       ROUND(SUM(d.cantidad * d.precio_unitario * (1 - d.descuento))) AS ventas
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN detalle_pedido d ON d.id_pedido = p.id_pedido
WHERE p.estado = 'Entregado'
GROUP BY c.ciudad
ORDER BY ventas DESC;

-- Reto D: ¿qué productos nunca se han vendido? --

SELECT p.nombre_producto
FROM productos p
LEFT JOIN detalle_pedido d ON p.id_producto = d.id_producto
WHERE d.id_producto IS NULL;

-- Pregunta 11. ¿Qué clientes tienen 25 pedidos entregados o más? 
 
SELECT CONCAT(c.nombre, ' ', c.apellido) AS cliente,
       COUNT(*) AS pedidos
FROM clientes c
JOIN pedidos p ON c.id_cliente = p.id_cliente
WHERE p.estado = 'Entregado'
GROUP BY c.id_cliente, cliente
HAVING COUNT(*) >= 25
ORDER BY pedidos DESC;

-- Pregunta 12. ¿Qué productos cuestan más que el precio promedio? 

SELECT nombre_producto, precio_unitario
FROM productos
WHERE precio_unitario > (SELECT AVG(precio_unitario) FROM productos)
ORDER BY precio_unitario DESC;

-- Pregunta 13. ¿Qué canal tiene la mayor tasa de cancelaciones y devoluciones? 

SELECT canal,
       COUNT(*) AS total_pedidos,
       SUM(CASE WHEN estado IN ('Cancelado', 'Devuelto') THEN 1 ELSE 0 END) AS cancelados_devueltos,
       ROUND(100 * SUM(CASE WHEN estado IN ('Cancelado', 'Devuelto') THEN 1 ELSE 0 END) / COUNT(*), 1) AS tasa_pct
FROM pedidos
GROUP BY canal
ORDER BY tasa_pct DESC;

-- Pregunta 14. ¿Cuál es el valor promedio de un pedido (ticket promedio) por año? 

SELECT anio, ROUND(AVG(valor_pedido)) AS ticket_promedio
FROM (
    SELECT p.id_pedido,
           YEAR(p.fecha_pedido) AS anio,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS valor_pedido
    FROM pedidos p
    JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
    WHERE p.estado = 'Entregado'
    GROUP BY p.id_pedido, anio
) t
GROUP BY anio;

-- Pregunta 15. Segmentación de clientes: VIP, Frecuente y Ocasional 

SELECT CASE
           WHEN total_comprado >= 5000000 THEN 'VIP'
           WHEN total_comprado >= 1000000 THEN 'Frecuente'
           ELSE 'Ocasional'
       END AS segmento,
       COUNT(*) AS clientes,
       ROUND(SUM(total_comprado)) AS ventas
FROM (
    SELECT c.id_cliente,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS total_comprado
    FROM clientes c
    JOIN pedidos p        ON c.id_cliente = p.id_cliente
    JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
    WHERE p.estado = 'Entregado'
    GROUP BY c.id_cliente
) t
GROUP BY segmento
ORDER BY ventas DESC;

-- Reto E: ¿Qué categorías vendieron más de 200 millones?

SELECT c.nombre_categoria,
       ROUND(SUM(d.cantidad * d.precio_unitario * (1 - d.descuento))) AS ventas
FROM detalle_pedido d
JOIN pedidos p     ON d.id_pedido = p.id_pedido
JOIN productos pr  ON d.id_producto = pr.id_producto
JOIN categorias c  ON pr.id_categoria = c.id_categoria
WHERE p.estado = 'Entregado'
GROUP BY c.nombre_categoria
HAVING ventas > 200000000
ORDER BY ventas DESC;

-- Reto F: Productos por rango de precio

SELECT 
    CASE
        WHEN precio_unitario < 100000 THEN 'Económico'
        WHEN precio_unitario < 250000 THEN 'Medio'
        ELSE 'Premium'
    END AS rango_precio,
    COUNT(*) AS total_productos
FROM
    productos
GROUP BY rango_precio
ORDER BY total_productos DESC;

-- Pregunta 16. ¿Cuánto crecieron las ventas frente al mes anterior? 

WITH ventas_mes AS (
    SELECT DATE_FORMAT(p.fecha_pedido, '%Y-%m') AS mes,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS ventas
    FROM pedidos p
    JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
    WHERE p.estado = 'Entregado'
    GROUP BY mes
),
con_anterior AS (
    SELECT mes, ventas,
           LAG(ventas) OVER (ORDER BY mes) AS ventas_mes_anterior
    FROM ventas_mes
)
SELECT mes,
       ROUND(ventas) AS ventas,
       ROUND(ventas_mes_anterior) AS mes_anterior,
       ROUND(100 * (ventas - ventas_mes_anterior) / ventas_mes_anterior, 1) AS crecimiento_pct
FROM con_anterior
ORDER BY mes;

-- Pregunta 17. ¿Cuáles son los 3 productos más vendidos de cada categoría? 

WITH ventas_producto AS (
    SELECT c.nombre_categoria,
           pr.nombre_producto,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS ventas
    FROM detalle_pedido d
    JOIN pedidos p     ON d.id_pedido = p.id_pedido
    JOIN productos pr  ON d.id_producto = pr.id_producto
    JOIN categorias c  ON pr.id_categoria = c.id_categoria
    WHERE p.estado = 'Entregado'
    GROUP BY c.nombre_categoria, pr.nombre_producto
),
ranking AS (
    SELECT *,
           RANK() OVER (PARTITION BY nombre_categoria ORDER BY ventas DESC) AS puesto
    FROM ventas_producto
)
SELECT nombre_categoria, puesto, nombre_producto, ROUND(ventas) AS ventas
FROM ranking
WHERE puesto <= 3
ORDER BY nombre_categoria, puesto;

-- Pregunta 18. ¿Qué porcentaje de las ventas aporta cada categoría? 

WITH ventas_categoria AS (
    SELECT c.nombre_categoria,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS ventas
    FROM detalle_pedido d
    JOIN pedidos p     ON d.id_pedido = p.id_pedido
    JOIN productos pr  ON d.id_producto = pr.id_producto
    JOIN categorias c  ON pr.id_categoria = c.id_categoria
    WHERE p.estado = 'Entregado'
    GROUP BY c.nombre_categoria
)
SELECT nombre_categoria,
       ROUND(ventas) AS ventas,
       ROUND(100 * ventas / SUM(ventas) OVER (), 1) AS participacion_pct
FROM ventas_categoria
ORDER BY ventas DESC;

-- Pregunta 19. ¿Cuánto se lleva vendido acumulado en 2025, mes a mes? 

WITH ventas_mes AS (
    SELECT MONTH(p.fecha_pedido) AS mes,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS ventas
    FROM pedidos p
    JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
    WHERE p.estado = 'Entregado'
      AND YEAR(p.fecha_pedido) = 2025
    GROUP BY mes
)
SELECT mes,
       ROUND(ventas) AS ventas_mes,
       ROUND(SUM(ventas) OVER (ORDER BY mes)) AS acumulado
FROM ventas_mes
ORDER BY mes;

-- Pregunta 20. ¿Cada cuántos días vuelve a comprar un cliente? 

WITH compras AS (
    SELECT id_cliente,
           fecha_pedido,
           LAG(fecha_pedido) OVER (PARTITION BY id_cliente ORDER BY fecha_pedido) AS compra_anterior
    FROM pedidos
    WHERE estado = 'Entregado'
)
SELECT ROUND(AVG(DATEDIFF(fecha_pedido, compra_anterior)), 1) AS dias_promedio_entre_compras
FROM compras
WHERE compra_anterior IS NOT NULL;

-- Reto G: el mejor cliente de cada ciudad 

WITH ventas_cliente AS (
    SELECT c.ciudad,
           CONCAT(c.nombre, ' ', c.apellido) AS cliente,
           SUM(d.cantidad * d.precio_unitario * (1 - d.descuento)) AS total_comprado
    FROM clientes c
    JOIN pedidos p        ON c.id_cliente = p.id_cliente
    JOIN detalle_pedido d ON p.id_pedido = d.id_pedido
    WHERE p.estado = 'Entregado'
    GROUP BY c.ciudad, c.id_cliente, cliente
),
ranking AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ciudad ORDER BY total_comprado DESC) AS puesto
    FROM ventas_cliente
)
SELECT ciudad, cliente, ROUND(total_comprado) AS total_comprado
FROM ranking
WHERE puesto = 1
ORDER BY total_comprado DESC;

-- Reto H: crecimiento de cada categoría de 2024 a 2025 

WITH ventas_anio AS (
    SELECT c.nombre_categoria,
           SUM(CASE WHEN YEAR(p.fecha_pedido) = 2024
                    THEN d.cantidad * d.precio_unitario * (1 - d.descuento)
                    ELSE 0 END) AS ventas_2024,
           SUM(CASE WHEN YEAR(p.fecha_pedido) = 2025
                    THEN d.cantidad * d.precio_unitario * (1 - d.descuento)
                    ELSE 0 END) AS ventas_2025
    FROM detalle_pedido d
    JOIN pedidos p     ON d.id_pedido = p.id_pedido
    JOIN productos pr  ON d.id_producto = pr.id_producto
    JOIN categorias c  ON pr.id_categoria = c.id_categoria
    WHERE p.estado = 'Entregado'
    GROUP BY c.nombre_categoria
)

SELECT nombre_categoria,
       ROUND(ventas_2024) AS ventas_2024,
       ROUND(ventas_2025) AS ventas_2025,
       ROUND(100 * (ventas_2025 - ventas_2024) / ventas_2024, 1) AS crecimiento_pct
FROM ventas_anio
ORDER BY crecimiento_pct DESC;
