-- 2.1. Получение информации о сумме товаров заказанных под каждого клиента (Наименование клиента, сумма)
SELECT
    C.name AS name,
    SUM(I.price) AS price
FROM
    public.customes C
    JOIN public.orders O ON O.customer_id = C.id
    AND O.is_complete = FALSE
    JOIN public.orders_items OI ON O.id = OI.order_id
    JOIN public.items I ON OI.item_id = I.id
WHERE
    C.is_deleted = FALSE
GROUP BY
    C.name;

-- 2.2. Найти количество дочерних элементов первого уровня вложенности для категорий номенклатуры.
SELECT
    C."label",
    COUNT(C2.id)
FROM
    public.categories C
    JOIN public.categories C2 ON C.id = C2.parent_id
GROUP BY
    C."label";

-- 2.3.1. Написать текст запроса для отчета (view) «Топ-5 самых покупаемых товаров за последний месяц» (по количеству штук в заказах). В отчете должны быть: Наименование товара, Категория 1-го уровня, Общее количество проданных штук.
SELECT
    SUM(OI.quantity) AS summary,
    C2."label" AS category
FROM
    public.items I
    JOIN public.orders_items OI ON I.id = OI.item_id
    JOIN public.orders O ON O.id = OI.order_id
    JOIN public.categories C ON I.category = C.id
    JOIN public.categories C2 ON LTREE2TEXT(SUBPATH(C."path", 0, 1)) = C2.id :: TEXT
GROUP BY
    C2.id
ORDER BY
    summary DESC
LIMIT
    5;

-- 2.3.2. Проанализировать написанный в п. 2.3.1 запрос и структуру БД. Предложить варианты оптимизации этого запроса и общей схемы данных для повышения производительности системы в условиях роста данных (тысячи заказов в день).
/*
    Думаю, что для оптимизации этого запроса можно воспользоваться решением, которое Google сделал в свое время для Youtube для счетчика просмотров видео. 
    Они считают не просмотр под каждым видео, а какие видео посмотрел каждый пользователь и математическим путем высчитывают количество просмотров под видео
*/