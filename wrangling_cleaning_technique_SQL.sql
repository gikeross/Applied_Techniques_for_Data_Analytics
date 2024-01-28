/*
cleaning data in SQL queries
*/
-- --------------------------------------------------CONVERT---------------------------------------------------------------------------
-- Standardize Date Format
select saledate , convert(saledate, date) 
from ptf_project.housing;

-- ---------------------------------------------JOIN & UPDATE + SET-------------------------------------------------------------------
-- populate Property address data

select * from ptf_project.housing
where PropertyAddress is null
order by ParcelID; -- spotted some null values


select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ifnull(a.PropertyAddress, b.PropertyAddress) as PropertyAddressUpdated
from ptf_project.housing a 
join ptf_project.housing b
	on a.ParcelID = b.ParcelID
    and a.INDEX <> b.index
where a.PropertyAddress is null; -- inner join dataset in order to fill using same data with different index

-- updating dataset using the previous query 
update ptf_project.housing a 
inner join ptf_project.housing as b
	on a.ParcelID = b.ParcelID
    and a.INDEX <> b.index
set a.PropertyAddress = ifnull(a.PropertyAddress, b.PropertyAddress);

-- -------------------------------------------- SUBSTRING - ALTER TABLE + ADD - UPDATE + SET-------------------------------------------

-- break out address in individual columns (address, city, state)

select 
SUBSTRING_INDEX(propertyaddress, ',', 1) as address, -- removing city from the string by locating the coma and taking all aargument before it 
SUBSTRING_INDEX(propertyaddress, ',', -1) as city
from ptf_project.housing
group by 1,2
order by 2;

alter table ptf_project.housing 
add PropertySPlitAddress nvarchar(255); -- creating new column to store mydata

update ptf_project.housing 
set PropertySPlitAddress = SUBSTRING_INDEX(propertyaddress, ',', 1); -- populating my column with address clean data

alter table ptf_project.housing 
add PropertySPlitCity nvarchar(255); -- creating new column to store mydata

update ptf_project.housing 
set PropertySPlitCity = SUBSTRING_INDEX(propertyaddress, ',',-1); -- populating my column with city clean data

select * from ptf_project.housing; -- checking if additions were effective

select SUBSTRING_INDEX(OwnerAddress, ',', 1) as name_o,
SUBSTRING_INDEX(SUBSTRING_INDEX(OwnerAddress, ',', 2),',', -1) as name_city,
SUBSTRING_INDEX(OwnerAddress, ',', -1) as city_code
from ptf_project.housing;
-- table could be updated using the same technique used here above alter table + add -->update+set for each column we want to add


-- -------------------------------------------------STORED PROCEDURES----------------------------------------------------------------------------
-- Create a 'Stored Procedure' based on SalePrice w/ IN paramether
use ptf_project;
DELIMITER $$
create procedure get_SalePrice (in SalePrice int)
begin 
select * from housing
where houding.SalePrice = SalePrice;
end $$
DELIMITER ; 
-- assignign to the procedure the paramether SalesPrice to filter the table
call get_SalePrice(32000);

-- get total of sold/vacannt
-- Create a 'Stored Procedure' based on SalePrice w/ OUTGIVER paramether
DELIMITER $$
create procedure count_SoldVacant (out SoldAsVacant int)
begin 
select count(*) into SoldAsVacant from housing
where SoldAsVacant regexp 'N';
end $$
DELIMITER ; 

call count_SoldVacant(@SoldAsVacant);
select @SoldAsVacant as countsoldvac;

-- --------------------------------------------------WRANGLING COLUMN----------------------------------------------------------------------------------

select distinct(SoldAsVacant), count(SoldAsVacant) -- spotting Y and N + yes and No
from ptf_project.housing
group by 1
order by 2;

select SoldAsVacant,
	case when SoldAsVacant like 'Y' then 'Yes'
		when SoldAsVacant like 'N' then 'No' else SoldAsVacant end as correction
from ptf_project.housing;

use ptf_project;
update ptf_project.housing 
set SoldAsVacant = case when SoldAsVacant like 'Y' then 'Yes'
						when SoldAsVacant like 'N' then 'No' else SoldAsVacant end;
                        
-- --------------------------------------------------REMOVING DUPLICATES----------------------------------------------------------------
#this practice is better perfomed in python not impacting SQL

with RowNumCTE as(
select *,
	row_number() OVER ( 
				partition by ParcelID, propertyAddress, SalePrice, SaleDate, LegalReference
						) as row_numb
from ptf_project.housing
order by ParcelID
)
DELETE
from RowNumCTE
where row_numb >1;
-- order by propertyAddress;

select * from ptf_project.housing;



