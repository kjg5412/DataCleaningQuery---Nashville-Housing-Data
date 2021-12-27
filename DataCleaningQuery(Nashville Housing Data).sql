-- 1. Standardize Date Format
-- I want to Change Column Order in a Table. but it's not possible. 
-- This task is not supported using Transact-SQL statements.
-- The method to solve this issue is You can change the order of columns in Table Designer in SQL Server by using SQL Server Management Studio.

select cast(SaleDate as Date) as New_date 
from Housing

ALTER TABLE Housing
Add New_date Date

UPDATE Housing SET New_date = cast(SaleDate as Date)

Select top 5 * from Housing

---------------------------------------------------------

-- 2. Populate Property Address Data
-- PropertyAddress column has null values

Select ParcelId, PropertyAddress, OwnerAddress from Housing
where PropertyAddress is null
order by ParcelId

-- PropertyAddress value is same if parcelld value is same?
with q2 as
(
select a.ParcelID, a.PropertyAddress, 
b.ParcelID as ParcelID2,
b.PropertyAddress as PropertyAddress2 from Housing a
Join Housing b on a.ParcelID = b.ParcelID
and a.[UniqueID ] != b.[UniqueID ]
)

select *, isnull(PropertyAddress, PropertyAddress2) from q2
where PropertyAddress is null

-- Update null value
UPDATE a
SET PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from Housing a
Join Housing b on a.ParcelID = b.ParcelID
and a.[UniqueID ] != b.[UniqueID ]
where a.PropertyAddress is null

-- confirm if null value exist
select * from Housing
where propertyAddress is null

---------------------------------------------------------

-- Breaking Out Address into Indivisual Columns (Address, City, State)
-- charindex(',', PropertyAddress) -- how to find location of comma
select 
substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as address,
substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, 1000) as city
from housing

ALTER TABLE Housing
Add address Nvarchar(255)

UPDATE Housing 
SET address = substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE Housing
Add city Nvarchar(255)

UPDATE Housing
Set city = substring(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, 1000)

UPDATE Housing
Set city = trim(city)

Select top 3 * from Housing

select 
parsename(replace(OwnerAddress, ',', '.'), 1) as state_owner,
parsename(replace(OwnerAddress, ',', '.'), 2) as city_owner,
parsename(replace(OwnerAddress, ',', '.'), 3) as address_owner
from Housing

ALTER TABLE Housing
add state_owner NVARCHAR(255),
city_owner NVARCHAR(255),
address_owner NVARCHAR(255);

UPDATE Housing
Set 
state_owner = parsename(replace(OwnerAddress, ',', '.'), 1),
city_owner = parsename(replace(OwnerAddress, ',', '.'), 2),
address_owner = parsename(replace(OwnerAddress, ',', '.'), 3)

Select top 100 * from Housing
order by state_owner desc

---------------------------------------------------------
-- change Y and N to yes and No in "sold as vacant" field
-- Using Case
select distinct(SoldAsVacant), count(SoldAsVacant)
from Housing
group by SoldAsVacant
order by 2

select SoldAsVacant,
case when SoldAsVacant = 'Y' Then 'Yes'
when SoldAsVacant = 'N' Then 'No'
else SoldAsVacant
end SoldAsVacantUpdated
from Housing

UPDATE Housing
set
SoldAsVacant =
case when SoldAsVacant = 'Y' Then 'Yes'
when SoldAsVacant = 'N' Then 'No'
else SoldAsVacant
End

---------------------------------------------------------

-- Remove Duplicates -> 104 rows
-- CTE Function
with duplicate as(
Select *,
ROW_NUMBER() over (PARTITION BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
								ORDER BY UniqueID
								) row_num
from housing)
select * from duplicate
where row_num > 1
order by UniqueID

with duplicate as(
Select *,
ROW_NUMBER() over (PARTITION BY ParcelID,
								PropertyAddress,
								SalePrice,
								SaleDate,
								LegalReference
								ORDER BY UniqueID
								) row_num
from housing)
DELETE from duplicate
where row_num > 1

---------------------------------------------------------
-- Delete Unused Columns

ALTER TABLE Housing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate

select * from Housing