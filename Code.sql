-- Create tables 
-- Here we create the detailed table
DROP TABLE IF EXISTS Sales_location_Detailed;
CREATE TABLE IF NOT EXISTS Sales_location_Detailed (
    detail_id SERIAL PRIMARY KEY,
    location VARCHAR(255),
    payment_id integer,
    rental_id integer,
    payment_date timestamp,
    inventory_id integer,
    genre VARCHAR(255),
    title TEXT,
    Sale numeric
);

-- We now have created the table with its columns necessary to view the information in detail
-- With this the detailed section of the Business report is created

-- To view the table 
SELECT * FROM Sales_location_Detailed;

-- NOW TO CREATE THE SUMMARY TABLE OF THE SALES BY LOCATION

CREATE TABLE IF NOT EXISTS Sales_Location_Summary (
    summary_ID SERIAL PRIMARY KEY,
    location VARCHAR(255),
    Sales numeric
);

-- Now the empty table has been created
-- WE can now view the empty table
SELECT * FROM Sales_Location_Summary;

-- NOW WE INSERT DATA INTO THE SALES BY LOCATION DETAILED TABLE 

INSERT INTO Sales_Location_Detailed (
    location, -- THIS IS A COMBINATION OF CITY AND COUNTRY TABLE
    payment_id, -- This is the Payment Table
    rental_id, -- This is from the rental table
    payment_date, -- This is from the Payment Table
    inventory_id, -- This is from the Rental Table
    genre, -- This is from the Category Table
    title, -- This is from the Film Table
    Sale -- This is from the Rental Table
)
SELECT 
city.city||', '||country.country AS city_address,
payment.payment_id,
payment.rental_id,
CAST(payment.payment_date as DATE),
rental.inventory_id,
category.name AS Genre,
film.title,
CAST(payment.amount AS MONEY)
FROM payment
INNER JOIN rental ON rental.rental_id = payment.rental_id
INNER JOIN inventory ON rental.inventory_id= inventory.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
INNER JOIN staff ON payment.staff_id = staff.staff_id
INNER JOIN store ON payment.staff_id = store.manager_staff_id
INNER JOIN address ON store.address_id=address.address_id
INNER JOIN city ON city.city_id =address.city_id
INNER JOIN country ON city.country_id = country.country_id
GROUP BY category.name, payment.payment_id, rental.inventory_id, city.city, country.country, film.title
ORDER BY city_address DESC;

-- This information is a combination from Rental, Inventory, Film, Film_Category, Category, Staff, Store, City and Country Table
-- With this a combined view information is retrieved and added into the table

-- NOW WE CAN VIEW THE Sales_location_Detailed table WITH THE DATA ADDED

SELECT * FROM Sales_location_Detailed;


-- NOW CREATING A FUNCTION THAT WOULD UPDATE THE DATA IN THE Sales_Summary table
CREATE FUNCTION summary_data_refresh()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM Sales_Location_Summary;
INSERT INTO Sales_Location_Summary (
    location,
    Sales
)
SELECT
city.city||', '||country.country AS city_address,
CAST(SUM(payment.amount) as money)
FROM payment
INNER JOIN staff
ON payment.staff_id = staff.staff_id
INNER JOIN store
ON payment.staff_id = store.manager_staff_id
INNER JOIN address
ON store.address_id=address.address_id
INNER JOIN city
ON city.city_id =address.city_id
INNER JOIN country
ON city.country_id = country.country_id
GROUP by payment.staff_id, staff.staff_id,address.address_id, city.city,country.country_id
ORDER BY city_address, SUM(payment.amount);
RETURN NEW;
END
$$;

----------------------------------------------------------------
-- WE NOW CREATE THE TRIGGER FUNCTION 
CREATE TRIGGER refreshing_data
AFTER INSERT ON Sales_location_Detailed
FOR EACH STATEMENT
EXECUTE PROCEDURE summary_data_refresh();

-- PROCEDURE NEEDS TO BE CREATED TO REFRESH THE DETAILED TABLE AND THUS ALSO REFRESHING THE SUMMARY TABLE

CREATE PROCEDURE refresh_data()
LANGUAGE plpgsql
AS $$
BEGIN
-- We need to renew the data so first we empty the existing data in the table
DELETE FROM sales_location_detailed; 
 -- WE HAVE TO RE-DO THE DATA INSERTS INTO THE DETAILED TABLE TO HAVE THE DETA PRESENTED IN THE SUMMARY TABLE
INSERT INTO Sales_Location_Detailed (
    location, -- THIS IS A COMBINATION OF CITY AND COUNTRY TABLE
    payment_id, -- This is the Payment Table
    rental_id, -- This is from the rental table
    payment_date, -- This is from the Payment Table
    inventory_id, -- This is from the Rental Table
    genre, -- This is from the Category Table
    title, -- This is from the Film Table
    Sale -- This is from the Rental Table
)
SELECT 
city.city||', '||country.country AS city_address,
payment.payment_id,
payment.rental_id,
CAST(payment.payment_date as DATE),
rental.inventory_id,
category.name AS Genre,
film.title,
CAST(payment.amount AS MONEY)
FROM payment
INNER JOIN rental ON rental.rental_id = payment.rental_id
INNER JOIN inventory ON rental.inventory_id= inventory.inventory_id
INNER JOIN film ON inventory.film_id = film.film_id
INNER JOIN film_category ON film_category.film_id = film.film_id
INNER JOIN category ON category.category_id = film_category.category_id
INNER JOIN staff ON payment.staff_id = staff.staff_id
INNER JOIN store ON payment.staff_id = store.manager_staff_id
INNER JOIN address ON store.address_id=address.address_id
INNER JOIN city ON city.city_id =address.city_id
INNER JOIN country ON city.country_id = country.country_id
GROUP BY category.name, payment.payment_id, rental.inventory_id, city.city, country.country, film.title
ORDER BY city_address DESC;

END$$;


-- THIS PROCEDURE WILL THEN LEAD TO THE DATA BEING PRESENTED 
