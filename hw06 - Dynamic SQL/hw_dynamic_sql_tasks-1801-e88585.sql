/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


--напишите здесь свое решение

DECLARE @dml as NVARCHAR (MAX)
DECLARE @ColumnName AS NVARCHAR (MAX)

SELECT @ColumnName = ISNULL(@ColumnName + ',','') + QUOTENAME(CustomName) 
FROM
	 (
		SELECT DISTINCT CustomerName as CustomName
		FROM Sales.Customers 
	 )  as CustomName
SELECT @ColumnName as ColumnName

SET @dml =
	N'SELECT InvoiceMonth
	,' +@ColumnName + '
	FROM 
	( 
	SELECT CA.InvoiceMonth
	,C.CustomerName as CustomName
	,i.InvoiceID
	FROM Sales.Invoices AS i
	JOIN Sales.Customers C
 	ON I.CustomerID = C.CustomerID
	CROSS APPLY (SELECT CONVERT(NVARCHAR(16),CAST(DATEADD(mm,DATEDIFF(mm,0,i.InvoiceDate),0) AS DATE), 104) AS InvoiceMonth) AS CA
    GROUP BY CA.InvoiceMonth, i.InvoiceID, CustomerName
	  ) as b
PIVOT 
(
	   COUNT(InvoiceID)
       FOR CustomName IN (' + @ColumnName + ')
) AS pvt

ORDER BY month(InvoiceMonth), year(InvoiceMonth)'


EXEC sp_executesql @dml
