/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

напишите здесь свое решение

DECLARE @xmlDoc XML
SELECT @xmlDoc = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\ 111\Documents\SQL COURSE\StockItems.xml'
, SINGLE_CLOB)
as data

--SELECT @xmlDoc as [xmlDoc]

DECLARE @DocHandle int
EXEC sp_xml_preparedocument @DocHandle OUTPUT, @xmlDoc

SELECT @DocHandle as DocHandle

SELECT *
FROM OPENXML (@DocHandle, 'StockItems/Item')
WITH (
	[StockItemName]			nvarchar(100)	'@Name',
	[SupplierID]			INT				'SupplierID',
	[UnitPackageID]			int				'Package/UnitPackageID',
	OuterPackageID			INT				'Package/OuterPackageID',
	[QuantityPerOuter]		INT				'Package/QuantityPerOuter',
	[TypicalWeightPerUnit]	decimal(18,2)	'Package/TypicalWeightPerUnit',
	[LeadTimeDays]			INT				'LeadTimeDays',
	[IsChillerStock]		BIT				'IsChillerStock',
	[TaxRate]				decimal(18,3)	'TaxRate',
	[UnitPrice]				decimal(18,2)	'UnitPrice'

)



DECLARE @StockItems
 TABLE (

	[StockItemName]			nvarchar(100)	,
	[SupplierID]			INT				,
	[UnitPackageID]			int				,
	OuterPackageID			INT				,
	[QuantityPerOuter]		INT				,
	[TypicalWeightPerUnit]	decimal(18,2)	,
	[LeadTimeDays]			INT				,
	[IsChillerStock]		BIT				,
	[TaxRate]				decimal(18,3)	,
	[UnitPrice]				decimal(18,2)	

)
INSERT INTO @StockItems 
SELECT *
FROM OPENXML (@DocHandle, 'StockItems/Item')
WITH (
	[StockItemName]			nvarchar(100)	'@Name',
	[SupplierID]			INT				'SupplierID',
	[UnitPackageID]			int				'Package/UnitPackageID',
	OuterPackageID			INT				'Package/OuterPackageID',
	[QuantityPerOuter]		INT				'Package/QuantityPerOuter',
	[TypicalWeightPerUnit]	decimal(18,2)	'Package/TypicalWeightPerUnit',
	[LeadTimeDays]			INT				'LeadTimeDays',
	[IsChillerStock]		BIT				'IsChillerStock',
	[TaxRate]				decimal(18,3)	'TaxRate',
	[UnitPrice]				decimal(18,2)	'UnitPrice'
)

EXEC sp_xml_removedocument @DocHandle OUTPUT

SELECT * FROM @StockItems

MERGE [Warehouse].[StockItems] as target
USING @StockItems as source
ON (target.StockItemName = source.StockItemName)

	WHEN MATCHED 
		THEN UPDATE SET target.[StockItemName] =source.[StockItemName],
						target.[SupplierID]=	source.[SupplierID],
						target.[UnitPackageID]=	source.[UnitPackageID],
						target.OuterPackageID=	source.OuterPackageID,
						target.[QuantityPerOuter]=source.[QuantityPerOuter],
						target.[TypicalWeightPerUnit]=source.[TypicalWeightPerUnit],
						target.[LeadTimeDays]=	source.[LeadTimeDays],
						target.[IsChillerStock]=source.[IsChillerStock],
						target.[TaxRate]=		source.[TaxRate],
						target.[UnitPrice] =	source.[UnitPrice],
						target.[LastEditedBy] =	1
	WHEN NOT MATCHED
		THEN INSERT ( [StockItemName],
					[SupplierID],
					[UnitPackageID],
					OuterPackageID,
					[QuantityPerOuter],
					[TypicalWeightPerUnit],
					[LeadTimeDays],
					[IsChillerStock],
					[TaxRate],
					[UnitPrice],
					[LastEditedBy])	
		VALUES (	source.[StockItemName],
					source.[SupplierID],
					source.[UnitPackageID],
					source.OuterPackageID,
					source.[QuantityPerOuter],
					source.[TypicalWeightPerUnit],
					source.[LeadTimeDays],
					source.[IsChillerStock],
					source.[TaxRate],
					source.[UnitPrice],	
					1);
		


delete from @StockItems
GO

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

напишите здесь свое решение

SELECT TOP 10 
	[StockItemName]			as  [@Name],
	[SupplierID]			as  [SupplierID],
	[UnitPackageID]			as	[Package/UnitPackageID],
	[OuterPackageID]		as	[Package/OuterPackageID],
	[QuantityPerOuter]		as	[Package/QuantityPerOuter],
	[TypicalWeightPerUnit]	as	[Package/TypicalWeightPerUnit],
	[LeadTimeDays]			as	[LeadTimeDays],
	[IsChillerStock]		as	[IsChillerStock],
	[TaxRate]				as	[TaxRate],
	[UnitPrice]				as	[UnitPrice]

FROM Warehouse.StockItems
FOR XML PATH('Item'), ROOT('StockItems')
GO


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/
SELECT StockItemID
	,StockItemName
	,JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
	,JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
	,JSON_QUERY(CustomFields, '$.Tags')as TagList
	--,CustomFields
FROM Warehouse.StockItems



/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT s.StockItemID
	,s.StockItemName
--	,s.CustomFields
	,JSON_QUERY(s.CustomFields, '$.Tags')as TagList
	,Tags.[key] 
	,Tags.Value as Tags
FROM [Warehouse].[StockItems] s
CROSS APPLY OPENJSON(CustomFields, '$.Tags') as Tags
Where Tags.Value = 'Vintage'

