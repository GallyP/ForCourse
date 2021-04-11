/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

--TODO: напишите здесь свое решение
SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%'
OR StockItemName like 'Animal%'



/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

--TODO: напишите здесь свое решение
SELECT S.SupplierID, S.SupplierName
FROM Purchasing.Suppliers S
LEFT JOIN Purchasing.PurchaseOrders P
ON S.SupplierID = P.SupplierID
Where [P.PurchaseOrderID] is null






/*
3. Заказы (Orders) 
с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
 !!!и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

-- TODO: напишите здесь свое решение


SELECT S.OrderID
      ,CONVERT (nvarchar(16), S.OrderDate, 104) as OrderDate
	  ,O.UnitPrice
	  ,O.Quantity
	  ,DATENAME(month, OrderDate) As NameMonth
	  ,DATEPART(quarter,OrderDate) AS [Quarter]
	  , CASE 
		WHEN DATEPART(month, Orderdate) BETWEEN 1 and 4 THEN 'First'
		WHEN DATEPART(month, Orderdate) BETWEEN 5 and 8 THEN 'Second'
		ELSE 'Third'
		END as PartYear
	  ,CustomerName
FROM Sales.Orders S
    	JOIN Sales.OrderLines O
		ON S.OrderID = O.OrderID
		JOIN Sales.Customers C
		ON S.CustomerID = C.CustomerID
WHERE UnitPrice > 100.00
OR (O.Quantity > 20
AND O.PickingCompletedWhen is NOT NULL)
Order by UnitPrice, PartYear, OrderDate

OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

--TODO: напишите здесь свое решение
SELECT D.DeliveryMethodName   -- метод доставки
	 , P.ExpectedDeliveryDate -- дата доставки
	 , PL.FullName            -- Имя контактного лица
	 , S.SupplierName         -- Имя поставщика
FROM Purchasing.Suppliers S
JOIN Purchasing.PurchaseOrders P
ON S.SupplierID = P.SupplierID
JOIN Application.DeliveryMethods D
ON P.DeliveryMethodID = D.DeliveryMethodID
JOIN Application.People PL
ON P.ContactPersonID = PL.PersonID
WHERE ExpectedDeliveryDate BETWEEN '2013-01-01' and '2013-01-31'
AND   (D.DeliveryMethodName = 'Air Freight'
	OR D.DeliveryMethodName = 'Refrigerated Air Freight')
AND P.IsOrderFinalized !=0
order by ExpectedDeliveryDate


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

--TODO: напишите здесь свое решение
SELECT TOP 10 O.OrderID      --Заказ
			 ,C.CustomerName --Покупатель
			 ,P.FullName     --Имя покупателя
FROM Sales.Orders O
JOIN Application.People P
ON O.SalespersonPersonID = P.PersonID
JOIN Sales.Customers C
ON O.CustomerID = C.CustomerID
Order by OrderDate desc


/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

--TODO: напишите здесь свое решение
SELECT O.CustomerID
	  ,C.CustomerName
	  ,C.PhoneNumber
FROM Warehouse.StockItems SI
JOIN Sales.OrderLines OL
ON SI.StockItemID = OL.StockItemID
JOIN Sales.Orders O
ON OL.OrderID = O.OrderID
JOIN Sales.Customers C
ON O.CustomerID = C.CustomerID
Where StockItemName = 'Chocolate frogs 250g'



/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение
	   
Select DISTINCT 
			  DATEPART(month,InvoiceDate) as [Month]
			 ,DATEPART(yy,InvoiceDate) as [Year]
			 ,SUM(L.ExtendedPrice) OVER (PARTITION BY    DATEPART(mm,InvoiceDate))as SumSale
														--,DATEPART(yy,InvoiceDate))as SumSale
			 ,AVG(L.ExtendedPrice) OVER (PARTITION BY    DATEPART(mm,InvoiceDate)) as AvgSale
														--,DATEPART(yy,InvoiceDate))as AvgSale

	  FROM   Sales.Invoices I
	  JOIN Sales.InvoiceLines L    -- ИД Товара и Цена за товар
	  ON I.InvoiceID= L.InvoiceID 

Group by I.InvoiceDate,L.ExtendedPrice
Having (I.InvoiceDate) BETWEEN '2013-01-01' and '2013-01-31'



/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение

	SELECT  DISTINCT 
			   DATEPART(mm,InvoiceDate) as [Month]
			   ,DATEPART(yy,InvoiceDate) as [Year]
			   ,SUM(L.ExtendedPrice) OVER (PARTITION BY    DATEPART(mm,InvoiceDate)) as SumScale
														 -- ,DATEPART(yy,InvoiceDate)) as SumSale (
	   	FROM Sales.Invoices I
				JOIN Sales.InvoiceLines L    -- ИД Товара и Цена за товар
				ON I.InvoiceID= L.InvoiceID 

		Group by I.InvoiceDate,L.ExtendedPrice
		HAVING (SUM(L.ExtendedPrice))>10000
			AND DATEPART(yy,InvoiceDate) = '2013'
			AND DATEPART(mm,InvoiceDate) = '11'
		Order by DATEPART(yy,InvoiceDate) 
			    ,DATEPART(mm,InvoiceDate) 

/*
9. Вывести сумму продаж, 
дату первой продажи
и количество проданного по месяцам, 
по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* +Год продажи
* +Месяц продажи
* +Наименование товара
* +Сумма продаж
* +Дата первой продажи
* +Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

--TODO: напишите здесь свое решение

			SELECT MIN(I.InvoiceDate) OVER (PARTITION BY S.StockItemName) FirstSale
				  ,DATEPART(yy,InvoiceDate) as [Year]
				  ,DATEPART(mm,InvoiceDate) as [Month]
				  ,S.StockItemName
				  ,SUM(COUNT(Quantity)) OVER (PARTITION BY S.StockItemName
														  ,DATEPART(mm,InvoiceDate)
														  ,DATEPART(yy,InvoiceDate))as AllQuantity
				  ,SUM(COUNT(Quantity)) OVER (PARTITION BY S.StockItemName
														  ,DATEPART(mm,InvoiceDate)
														  ,DATEPART(yy,InvoiceDate))*L.UnitPrice as Sales
				  ,L.UnitPrice
				  
			FROM Sales.Invoices I
							JOIN Sales.InvoiceLines L    -- ИД Товара и Цена за товар
							ON I.InvoiceID= L.InvoiceID 
							JOIN Warehouse.StockItems S  -- Название айтема 
							ON L.StockItemID = S.StockItemID
			Group by DATEPART(yy,InvoiceDate)
					,DATEPART(mm,InvoiceDate)
					,S.StockItemName
					,L.UnitPrice
					,i.InvoiceDate	
			Order by S.StockItemName,DATEPART(yy,InvoiceDate),DATEPART(mm,InvoiceDate)
			


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/


