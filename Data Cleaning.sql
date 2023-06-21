/*
Data Cleaning with SQL
*/

-- 1. Populating Property Address data
-- Checking for NULL Property Address
Select PropertyAddress
From Portfolio..Housing
Where PropertyAddress is NULL


-- Checking for NULL Property Address after self-joining
Select v1.parcelID, v1.PropertyAddress, v2.parcelID, v2.PropertyAddress, ISNULL(v1.PropertyAddress, v2.PropertyAddress)
From Portfolio..Housing v1
Join Portfolio..Housing v2
    on v1.ParcelID = v2.ParcelID
    and v1.UniqueID <> v2.UniqueID
Where v1.PropertyAddress is NULL

-- Populating NULL Property Address rows
Update v1
SET PropertyAddress = ISNULL(v1.PropertyAddress, v2.PropertyAddress)
From Portfolio..Housing v1
Join Portfolio..Housing v2
    on v1.ParcelID = v2.ParcelID
    and v1.UniqueID <> v2.UniqueID
Where v1.PropertyAddress is NULL

--------------------------------------------------------------------------------------------------------------------------

-- 2. Segmenting Property and Owner Addresses into individual columns (Address, City, State)
-- Looking at Property Address
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City
From Portfolio..Housing

-- Adding Property Address and City columns to table and filling in rows
ALTER TABLE Housing
Add PropertySplitAddress Nvarchar(255);

ALTER TABLE Housing
Add PropertySplitCity Nvarchar(255);

Update Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

Update Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-- Adding Owner Address, City and State columns to table
SELECT
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From Portfolio..Housing

ALTER TABLE Housing
Add OwnerSplitAddress Nvarchar(255);

ALTER TABLE Housing
Add OwnerSplitCity Nvarchar(255);

ALTER TABLE Housing
Add OwnerSplitState Nvarchar(255);

-- Filling in rows
Update Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Update Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Update Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--------------------------------------------------------------------------------------------------------------------------

--3. Changing "Y" and "N" to "Yes" and "No" in "Sold as Vacant" field

-- Checking number of rows containing each distinct value
Select Distinct(SoldAsVacant), Count(SoldAsVacant) as VacantCount
From Portfolio..Housing
Group by SoldAsVacant
Order by 2

-- Changing "Y" and "N" to "Yes" and "No"
Select SoldAsVacant,
CASE When SoldAsVacant = 'Y' THEN 'Yes'
    When SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END
From Portfolio..Housing

Update Housing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
    When SoldAsVacant = 'N' THEN 'No'
    ELSE SoldAsVacant
    END

--------------------------------------------------------------------------------------------------------------------------

-- 4. Removing Duplicates
With RowNumCTE as
(
Select *, 
ROW_NUMBER() OVER (
Partition by ParcelID,
    PropertyAddress,
    SaleDate,
    SalePrice,
    LegalReference
    Order by UniqueID
) row_num

From Portfolio..Housing
)

DELETE
From RowNumCTE
Where row_num > 1

/*
-- Check that duplicates are removed
Select *
From RowNumCTE
Where row_num > 1
*/

--------------------------------------------------------------------------------------------------------------------------

-- 5. Deleting Unused Columns
ALTER TABLE Housing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

Select *
From Portfolio..Housing