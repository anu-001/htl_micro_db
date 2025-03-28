-- 1. Which customer segments are driving our revenue and booking patterns?

WITH
    CustomerSegmentPerformance
    AS
    (
        SELECT
            ct.name AS CustomerSegment,
            COUNT(DISTINCT rb.rooms_booking_id) AS TotalBookings,
            ROUND(SUM(p.total_amount), 2) AS TotalRevenue,
            ROUND(AVG(p.total_amount), 2) AS AverageBookingValue,
            ROUND(SUM(p.total_discount), 2) AS TotalDiscounts,
            ROUND(COUNT(DISTINCT rb.rooms_booking_id) * 100.0 / 
              (SELECT COUNT(*)
            FROM rooms_bookings), 2) AS BookingSharePercentage
        FROM
            rooms_bookings rb
            JOIN
            customers c ON rb.customer_id = c.customer_id
            JOIN
            customer_types ct ON c.customer_type_id = ct.customer_type_id
            JOIN
            payments p ON rb.rooms_booking_id = p.rooms_booking_id
        GROUP BY 
        ct.name
        ORDER BY 
        TotalRevenue DESC
    )
SELECT
    CustomerSegment,
    TotalBookings,
    TotalRevenue,
    AverageBookingValue,
    TotalDiscounts,
    BookingSharePercentage,
    ROUND(TotalDiscounts / TotalRevenue * 100, 2) AS DiscountRatePercentage
FROM
    CustomerSegmentPerformance;

-- 2. Which room types and buildings are most profitable?

WITH
    RoomPerformanceAnalysis
    AS
    (
        SELECT
            b.name AS BuildingName,
            rt.name AS RoomType,
            COUNT(DISTINCT rb.rooms_booking_id) AS BookingCount,
            ROUND(SUM(p.total_amount), 2) AS TotalRevenue,
            ROUND(AVG(r.rate_per_night), 2) AS AverageRoomRate,
            ROUND(COUNT(DISTINCT rb.rooms_booking_id) * 100.0 / 
              (SELECT COUNT(*)
            FROM rooms_bookings), 2) AS BookingSharePercentage,
            ROUND(COUNT(DISTINCT rb.rooms_booking_id) * 100.0 / 
              (SELECT COUNT(*)
            FROM rooms), 2) AS OccupancyRatePercentage
        FROM
            rooms rm
            JOIN
            buildings b ON rm.building_id = b.building_id
            JOIN
            room_types rt ON rm.room_type_id = rt.room_type_id
            JOIN
            rooms_bookings rb ON rm.room_id = rb.room_id
            JOIN
            rates r ON rt.room_type_id = r.room_type_id
            JOIN
            payments p ON rb.rooms_booking_id = p.rooms_booking_id
        GROUP BY 
        b.name, rt.name
    )
SELECT
    BuildingName,
    RoomType,
    BookingCount,
    TotalRevenue,
    AverageRoomRate,
    BookingSharePercentage,
    OccupancyRatePercentage,
    ROUND(TotalRevenue / BookingCount, 2) AS AverageRevenuePerBooking
FROM
    RoomPerformanceAnalysis
ORDER BY 
    TotalRevenue DESC
LIMIT 10;

-- 3. How do bookings and revenue vary across different periods?

WITH BookingTrends
AS
(
    SELECT
    YEAR(rb.expected_check_in) AS BookingYear,
    MONTH(rb.expected_check_in) AS BookingMonth,
    COUNT(DISTINCT rb.rooms_booking_id) AS MonthlyBookings,
    ROUND(SUM(p.total_amount), 2) AS MonthlyRevenue,
    ROUND(AVG(p.total_amount), 2) AS AverageBookingValue,
    ROUND(AVG(DATEDIFF(rb.expected_check_out, rb.expected_check_in)), 2) AS AverageStayDuration
FROM
    rooms_bookings rb
    JOIN
    payments p ON rb.rooms_booking_id = p.rooms_booking_id
GROUP BY 
        YEAR(rb.expected_check_in), 
        MONTH(rb.expected_check_in)
)
,
SeasonalTotals AS
(
    SELECT
    SUM(MonthlyRevenue) AS TotalAnnualRevenue
FROM
    BookingTrends
)
SELECT
    bt.BookingYear,
    bt.BookingMonth,
    bt.MonthlyBookings,
    bt.MonthlyRevenue,
    bt.AverageBookingValue,
    bt.AverageStayDuration,
    ROUND(bt.MonthlyRevenue * 100.0 / st.TotalAnnualRevenue, 2) AS RevenueSharePercentage,
    CASE 
        WHEN bt.BookingMonth IN (12, 1, 2) THEN 'Winter'
        WHEN bt.BookingMonth IN (3, 4, 5) THEN 'Spring'
        WHEN bt.BookingMonth IN (6, 7, 8) THEN 'Summer'
        WHEN bt.BookingMonth IN (9, 10, 11) THEN 'Autumn'
    END AS Season
FROM
    BookingTrends bt
CROSS JOIN 
    SeasonalTotals st
ORDER BY 
    bt.BookingYear, 
    bt.BookingMonth;

-- 4.  What is the impact of different payment statuses on our financial performance?

WITH
    PaymentStatusAnalysis
    AS
    (
        SELECT
            ps.name AS PaymentStatus,
            COUNT(DISTINCT p.payment_id) AS TransactionCount,
            ROUND(SUM(p.total_amount), 2) AS TotalRevenue,
            ROUND(AVG(p.total_amount), 2) AS AverageTransactionValue,
            ROUND(SUM(p.total_discount), 2) AS TotalDiscounts,
            ROUND(COUNT(DISTINCT p.payment_id) * 100.0 / 
              (SELECT COUNT(*)
            FROM payments), 2) AS TransactionSharePercentage
        FROM
            payments p
            JOIN
            payment_statuses ps ON p.payment_status_id = ps.payment_status_id
        GROUP BY 
        ps.name
    )
SELECT
    PaymentStatus,
    TransactionCount,
    TotalRevenue,
    AverageTransactionValue,
    TotalDiscounts,
    TransactionSharePercentage,
    ROUND(TotalDiscounts / TotalRevenue * 100, 2) AS DiscountRatePercentage
FROM
    PaymentStatusAnalysis
ORDER BY 
    TotalRevenue DESC;

-- 5. How effective are we at retaining and upselling to customers?

WITH
    CustomerRetentionAnalysis
    AS
    (
        SELECT
            c.customer_id,
            c.first_name,
            c.last_name,
            ct.name AS CustomerType,
            COUNT(DISTINCT rb.rooms_booking_id) AS TotalBookings,
            ROUND(SUM(p.total_amount), 2) AS TotalSpend,
            ROUND(AVG(p.total_amount), 2) AS AverageBookingValue,
            MIN(rb.expected_check_in) AS FirstBookingDate,
            MAX(rb.expected_check_in) AS LastBookingDate,
            DATEDIFF(MAX(rb.expected_check_in), MIN(rb.expected_check_in)) AS CustomerTenure
        FROM
            customers c
            JOIN
            customer_types ct ON c.customer_type_id = ct.customer_type_id
            JOIN
            rooms_bookings rb ON c.customer_id = rb.customer_id
            JOIN
            payments p ON rb.rooms_booking_id = p.rooms_booking_id
        GROUP BY 
        c.customer_id, c.first_name, c.last_name, ct.name
    )
SELECT
    CustomerType,
    COUNT(DISTINCT customer_id) AS UniqueCustomers,
    ROUND(AVG(TotalBookings), 2) AS AvgBookingsPerCustomer,
    ROUND(AVG(TotalSpend), 2) AS AvgTotalSpendPerCustomer,
    ROUND(AVG(AverageBookingValue), 2) AS AvgBookingValue,
    ROUND(AVG(CustomerTenure), 2) AS AvgCustomerTenure
FROM
    CustomerRetentionAnalysis
GROUP BY 
    CustomerType
ORDER BY 
    AvgTotalSpendPerCustomer DESC;


-- 6. What is our untapped booking potential and market penetration?
-- What is our untapped booking potential and market penetration?

WITH
    RoomAvailabilityAnalysis
    AS
    (
        SELECT
            b.name AS BuildingName,
            rt.name AS RoomType,
            COUNT(DISTINCT r.room_id) AS TotalRooms,
            COUNT(DISTINCT rb.rooms_booking_id) AS BookedRooms,
            ROUND(
            COUNT(DISTINCT rb.rooms_booking_id) * 100.0 / 
            NULLIF(COUNT(DISTINCT r.room_id), 0), 
        2) AS OccupancyRate,
            ROUND(AVG(rate.rate_per_night), 2) AS AverageRoomRate,
            ROUND(SUM(COALESCE(p.total_amount, 0)), 2) AS TotalRevenue
        FROM
            rooms r
            JOIN
            buildings b ON r.building_id = b.building_id
            JOIN
            room_types rt ON r.room_type_id = rt.room_type_id
            JOIN
            rates rate ON rt.room_type_id = rate.room_type_id
            LEFT JOIN
            rooms_bookings rb ON r.room_id = rb.room_id
            LEFT JOIN
            payments p ON rb.rooms_booking_id = p.rooms_booking_id
        GROUP BY 
        b.name, rt.name, rate.rate_per_night
    )
SELECT
    BuildingName,
    RoomType,
    TotalRooms,
    BookedRooms,
    OccupancyRate,
    AverageRoomRate,
    TotalRevenue,
    ROUND(
        (100 - OccupancyRate) * TotalRooms * AverageRoomRate / 100, 
    2) AS PotentialUnrealisedRevenue,
    CASE 
        WHEN OccupancyRate < 30 THEN 'Low Occupancy - Urgent Action Required'
        WHEN OccupancyRate BETWEEN 30 AND 50 THEN 'Below Average Occupancy - Improvement Needed'
        WHEN OccupancyRate BETWEEN 50 AND 70 THEN 'Moderate Occupancy - Good Performance'
        WHEN OccupancyRate BETWEEN 70 AND 85 THEN 'High Occupancy - Optimized Utilization'
        ELSE 'Extremely High Occupancy - Consider Expansion'
    END AS OccupancyInsights,
    ROUND(
        (BookedRooms * 100.0) / NULLIF(TotalRooms, 0),
    2) AS MarketPenetrationRate
FROM
    RoomAvailabilityAnalysis
ORDER BY 
    PotentialUnrealisedRevenue DESC;
