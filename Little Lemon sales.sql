use LittleLemonDB;
-- TASK 1
# Create a virtual table called OrdersView that focuses on OrderID, Quantity and Cost columns 
# within the Orders table for all orders with a quantity greater than 2
SELECT OrderID, OrderQuantity, TotalCost
FROM Orders
WHERE OrderQuantity > 2;

-- TASK 2
# Information from four tables on all customers with orders that cost more than $150
SELECT Customers.CusID, Customers.CusName, 
	   Orders.OrderID, Orders.TotalCost,
       Menu.MenuName, MenuItems.CourseName, MenuItems.StarterName
FROM MenuItems JOIN Menu USING (ItemID)
JOIN Orders USING (MenuID)
JOIN Customers USING (CusID)
WHERE Orders.TotalCost > 150
ORDER BY Orders.TotalCost;

-- TASK 3
# Menu items for which more than 2 orders have been placed
SELECT MenuName
FROM Menu
WHERE MenuID = ANY (SELECT MenuID
					FROM Orders
					GROUP BY MenuID
					HAVING COUNT(OrderID) > 2);
                    
-- TASK 4
# Create a procedure that displays the maximum ordered quantity in the Orders table
DROP PROCEDURE IF EXISTS GetMaxQuantity;
DELIMITER //
CREATE PROCEDURE GetMaxQuantity() 
BEGIN
    SELECT MAX(o.menucount) AS "Max Quantity in Order"
	FROM (SELECT COUNT(MenuID) AS menucount 
	FROM Orders
	GROUP BY OrderID) o;
END//
DELIMITER ;

-- TASK 5
# Create a prepared statement called GetOrderDetail:
# Input argument is the CustomerID value, from a variable. 
# Return the order id, the quantity and the order cost from the Orders table. 
PREPARE GetOrderDetail FROM 'SELECT OrderID, OrderQuantity, TotalCost FROM Orders WHERE CusID = ?';
SET @id = 1;
EXECUTE GetOrderDetail USING @id;

-- TASK 6
# Create a stored procedure called CancelOrder to delete an order record based on the user input of the order id.
DROP PROCEDURE IF EXISTS CancelOrder;
DELIMITER //
CREATE PROCEDURE CancelOrder(orderid INT) 
BEGIN
    DECLARE orderExistence INT;

	-- Check if the order exists in the database
	SELECT COUNT(*) INTO orderExistence FROM Orders WHERE OrderID = orderid;

	-- If the order exists, delete it
	IF orderExistence > 0 THEN
    -- First delete related records from OrderDeliveryStatuses table
    DELETE FROM OrderDeliStat WHERE OrderID = orderid;

    -- Then delete the order from the Orders table
    DELETE FROM Orders WHERE OrderID = orderid;

    SELECT CONCAT('Booking ', orderid, ' is cancelled') AS 'Confirmation';
  ELSE
    SELECT CONCAT('Booking ', orderid, ' does not exist') AS 'Confirmation';
  END IF;
END//
DELIMITER ;

-- TASK 7
# Populate the Bookings table
INSERT INTO Bookings(BookingID, BookingDate, TableNo, CusID) VALUES
(1, "2022-10-10", 5, 1),
(2, "2022-11-12", 3, 3),
(3, "2022-10-11", 2, 2),
(4, "2022-10-13", 2, 1);

SELECT BookingID, BookingDate, TableNo, CusID
FROM Bookings;

-- TASK 8
# Create a stored procedure called CheckBooking to check whether a table in the restaurant is already booked.
# Two input parameters in the form of booking date and table number. 
# You can also create a variable in the procedure to check the status of each table.
DROP PROCEDURE IF EXISTS CheckBooking;
DELIMITER //
CREATE PROCEDURE CheckBooking(booking_date DATE, table_number INT) 
BEGIN
    DECLARE table_status VARCHAR(50);

    SELECT COUNT(*) INTO @table_count
    FROM Bookings
    WHERE BookingDate = booking_date AND TableNo = table_number;

    IF (@table_count > 0) THEN
        SET table_status = CONCAT('Table ', table_number, ' is already booked');
    ELSE
        SET table_status = 'Table is available.';
    END IF;

    SELECT table_status AS 'Booking Status';
END//
DELIMITER ;

-- TASK 9 
# Create a new procedure called AddValidBooking to verify a booking, and decline any reservations for tables that are already booked under another name. 
# Since integrity is not optional, Little Lemon need to ensure that every booking attempt includes these verification and decline steps. 
DROP PROCEDURE IF EXISTS AddValidBooking;
DELIMITER //
CREATE PROCEDURE AddValidBooking(booking_date DATE, table_number INT, cus_id INT) 
BEGIN
    START TRANSACTION;
    CALL CheckBooking(booking_date, table_number);
    IF ('Booking Status' = 'Table is available') THEN
		ROLLBACK;
		SELECT CONCAT('Table ', table_number, ' is already booked - booking cancelled') AS 'Booking status';
    ELSE
		INSERT INTO Bookings(BookingDate, TableNo, CusID) VALUES(booking_date, table_number, cus_id);
		COMMIT;
		SELECT 'Booking completed' AS 'Booking status';
    END IF;
END//
DELIMITER ;

-- TASK 10
# Create a new procedure called AddBooking to add a new table booking record
DROP PROCEDURE IF EXISTS AddBooking;
DELIMITER //
CREATE PROCEDURE AddBooking(booking_id INT, cus_id INT, booking_date DATE, table_number INT) 
BEGIN
	INSERT INTO Bookings(BookingID, BookingDate, TableNo, CusID) VALUES(booking_id, booking_date, table_number, cus_id);
	SELECT 'New booking added' AS 'Confirmation';
END//
DELIMITER ;

-- TASK 11
# Create a new procedure called UpdateBooking that they can use to update existing bookings in the booking table.
# Two input parameters: booking id and booking date. 
# Must also include an UPDATE statement inside the procedure.
DROP PROCEDURE IF EXISTS UpdateBooking;
DELIMITER //
CREATE PROCEDURE UpdateBooking(booking_id INT, booking_date DATE) 
BEGIN
	UPDATE Bookings
    SET BookingDate = booking_date
    WHERE BookingID = booking_id;

END//
DELIMITER ;

-- TASK 12
# Create a new procedure called CancelBooking that they can use to cancel or remove a booking.
# Input parameter: booking id. 
# You must also write a DELETE statement inside the procedure. 
DROP PROCEDURE IF EXISTS CancelBooking;
DELIMITER //
CREATE PROCEDURE CancelBooking(booking_id INT) 
BEGIN
	DELETE FROM Bookings
    WHERE BookingID = booking_id;

    SELECT CONCAT('Booking ', booking_id, ' cancelled') AS 'Confirmation';
END//
DELIMITER ;