-- Import csv to my sql
SET GLOBAL local_infile = true;

	DROP TABLE IF EXISTS housing_data;
	create table housing_data (
	UniqueID INT,
	ParcelID VARCHAR(255),
	LandUse VARCHAR(255),
	PropertyAddress TEXT,
	SaleDate VARCHAR(255),
	SalePrice INT,
	LegalReference VARCHAR(255),
	SoldAsVacant VARCHAR(255),
	OwnerName VARCHAR(70),
	OwnerAddress TEXT,
	Acreage DECIMAL(5,2),
	TaxDistrict VARCHAR(255),
	LandValue INT,
	BuildingValue INT,
	TotalValue INT,
	YearBuilt YEAR,
	Bedrooms INT,
	FullBath INT,
	HalfBath INT
	);
	
	LOAD DATA LOCAL INFILE 'C:/Users/kunal/Desktop/Covid_Data/Nashville_Housing_Data.csv' INTO TABLE housing_data
	FIELDS TERMINATED BY ','
	ENCLOSED BY '"'
	LINES TERMINATED BY '\r\n'
	IGNORE 1 LINES
	(UniqueID ,ParcelID,LandUse,PropertyAddress,SaleDate,SalePrice,LegalReference,SoldAsVacant,OwnerName,OwnerAddress,Acreage,TaxDistrict,LandValue,BuildingValue,TotalValue,YearBuilt,Bedrooms,FullBath,HalfBath)
	;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------






/*
Cleaning Data in SQL Queries
*/

Looking at the table
Select *
From housing.housing_data

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format

The Sale date column was in format april 1,2013… I wanted to convert it to 2013-04-01
So the query--
	UPDATE housing_data
	SET SaleDate = DATE_FORMAT(STR_TO_DATE(SaleDate, '%M %e,%Y'), '%Y-%m-%d');
	


 --------------------------------------------------------------------------------------------------------------------------

My PropertyAddress column data type was text hence showing blanks instead of null , so I changed the blanks to null by-
	UPDATE housing.housing_data
	SET PropertyAddress = NULL
	WHERE PropertyAddress = ''
	

-- Populate Property Address data

	Select *
	From housing.housing_data
	--Where PropertyAddress is null
	order by ParcelID
	

-- Some property address have common parcel id so we used the filled property addresses and applied self join to fig out the addresses of NULL values and then updated the set with those addresses

	SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)
	FROM housing.housing_data AS a
	JOIN housing.housing_data AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
	WHERE a.PropertyAddress IS NULL;
	

	Update housing_data AS a
	JOIN housing.housing_data AS b
	ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
	SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
	WHERE a.PropertyAddress IS NULL

 So now we don’t have any null values in propertyaddress column





--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


	Select PropertyAddress
	From housing.housing_data
	
	
	SELECT SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address1, 
	(SUBSTRING_INDEX(PropertyAddress, ',', -1)) AS Address2
	FROM housing_data
			 


ALTER TABLE housing.housing_data
Add Address1 TEXT

Update housing.housing_data
SET Address1 = SUBSTRING_INDEX(PropertyAddress, ',', 1)

ALTER TABLE housing.housing_data
Add City TEXT

Update housing.housing_data
SET City = SUBSTRING_INDEX(PropertyAddress, ',', -1)




Select *
From PortfolioProject.dbo.NashvilleHousing





SELECT OwnerAddress FROM housing.housing_data
-- now splitting owner address into owaddress, owcity, owstate
-- Owner Address column has lots of blanks ~30k

SELECT SUBSTRING_INDEX(OwnerAddress, ',', 1) AS owAddress,
   SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1) AS owCity,
   SUBSTRING_INDEX(OwnerAddress, ',', -1) AS owState
   FROM housing.housing_data
   
ALTER TABLE housing.housing_data
Add (owAddress TEXT,
owCity TEXT,
owState TEXT)

UPDATE housing.housing_data
SET owAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1),
    owCity = SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2), ',', -1),
    owState = SUBSTRING_INDEX(OwnerAddress, ',', -1);




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field
	
	Update housing.housing_data
	SET SoldasVacant = 'Yes' 
	WHERE SoldasVacant = 'Y'
	
	Update housing.housing_data
	SET SoldasVacant = 'No' 
	WHERE SoldasVacant = 'N'



-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
-- first selecting the duplicate rows with cte and partitions
	WITH RowNumCTE AS(
	Select *,
		ROW_NUMBER() OVER (
		PARTITION BY ParcelID,
					 PropertyAddress,
					 SalePrice,
					 SaleDate,
					 LegalReference
					 ORDER BY
						UniqueID
						) AS row_num
	
	From housing.housing_data
	)
	Select *
	From RowNumCTE
	Where row_num > 1
-- Order by PropertyAddress
-- Now deleting the duplicate rows with Subquery 
	DELETE FROM housing.housing_data
	WHERE UniqueID IN (
	  SELECT UniqueID FROM (
	    SELECT UniqueID,
	      ROW_NUMBER() OVER (
	        PARTITION BY ParcelID,
	                     PropertyAddress,
	                     SalePrice,
	                     SaleDate,
	                     LegalReference
	        ORDER BY UniqueID
	      ) AS row_num
	    FROM housing.housing_data
	  ) AS RowNumCTE
	  WHERE row_num > 1
	);

-- For deleting the CTE cannot be used directly in a DELETE statement, so Ill have to use SUBQUERY simliar to above CTE
	


---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns


	ALTER TABLE housing.housing_data
	DROP COLUMN OwnerAddress, 
	DROP COLUMN PropertyAddress


ALTER TABLE housing.housing_data
MODIFY COLUMN owAddress TEXT AFTER OwnerName,
MODIFY COLUMN owCity TEXT AFTER owAddress,
MODIFY COLUMN owState TEXT AFTER owCity

ALTER TABLE housing.housing_data
CHANGE COLUMN Address1 PropertyAddress TEXT;
