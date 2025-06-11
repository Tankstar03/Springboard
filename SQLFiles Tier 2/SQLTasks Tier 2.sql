/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.

This is Tier 2 of the case study, which means that there'll be less guidance for you about how to setup
your local SQLite connection in PART 2 of the case study. This will make the case study more challenging for you: 
you might need to do some digging, aand revise the Working with Relational Databases in Python chapter in the previous resource.

Otherwise, the questions in the case study are exactly the same as with Tier 1. 

PART 1: PHPMyAdmin
You will complete questions 1-9 below in the PHPMyAdmin interface. 
Log in by pasting the following URL into your browser, and
using the following Username and Password:

URL: https://sql.springboard.com/
Username: student
Password: learn_sql@springboard

The data you need is in the "country_club" database. This database
contains 3 tables:
    i) the "Bookings" table,
    ii) the "Facilities" table, and
    iii) the "Members" table.

In this case study, you'll be asked a series of questions. You can
solve them using the platform, but for the final deliverable,
paste the code for each solution into this script, and upload it
to your GitHub.

Before starting with the questions, feel free to take your time,
exploring the data, and getting acquainted with the 3 tables. */


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT *
FROM Facilities
WHERE membercost > 0.0


/* Q2: How many facilities do not charge a fee to members? */

4 facilities


/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE membercost > 0.0
AND membercost < monthlymaintenance * 0.2


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT *
FROM Facilities
WHERE facid %4 =1


/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance,
CASE
    WHEN monthlymaintenance >100 THEN "Expensive"
    ELSE "Cheap"
END AS pricing
FROM Facilities


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM Members
WHERE joindate = (
    SELECT MAX( joindate )
    FROM Members )


/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT book.memid, book.facid, fac.name, CONCAT(mem.firstname, ' ', mem.surname) AS fullname
FROM Bookings AS book
INNER JOIN Members AS mem ON book.memid = mem.memid
INNER JOIN Facilities AS fac ON book.facid = fac.facid
WHERE book.facid =0
OR book.facid =1
ORDER BY mem.surname, mem.firstname, book.facid

//The above solution returns a 403 error, potentially indicating it as a SQL injection. Removing the concat function fixes the issue. Below is the working solution:
SELECT DISTINCT book.memid, book.facid, fac.name, mem.firstname, mem.surname
FROM Bookings AS book
INNER JOIN Members AS mem ON book.memid = mem.memid
INNER JOIN Facilities AS fac ON book.facid = fac.facid
WHERE book.facid =0
OR book.facid =1
ORDER BY mem.surname, mem.firstname, book.facid


/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT fac.name, mem.firstname, mem.surname,
CASE
WHEN mem.memid =0
THEN fac.guestcost * book.slots
ELSE fac.membercost * book.slots
END AS cost
FROM Bookings AS book
INNER JOIN Facilities AS fac ON book.facid = fac.facid
INNER JOIN Members AS mem ON mem.memid = book.memid
WHERE DATE( starttime ) = '2012-09-14'
AND (

CASE
WHEN mem.memid =0
THEN fac.guestcost * book.slots > 30.0
ELSE fac.membercost * book.slots > 30.0
END
)
ORDER BY cost DESC
//As in the previous question, the CONCAT statement was omitted to prevent the same error from being flagged.


/* Q9: This time, produce the same result as in Q8, but using a subquery. */
SELECT combined.name, combined.firstname, combined.surname, combined.cost
FROM (
    SELECT book.memid, fac.facid, fac.name, mem.firstname, mem.surname,
    DATE( book.starttime ) AS date,
    IF( book.memid =0, fac.guestcost * book.slots, fac.membercost * book.slots ) AS cost
    FROM Bookings AS book
    INNER JOIN Facilities AS fac ON book.facid = fac.facid
    INNER JOIN Members AS mem ON mem.memid = book.memid
) AS combined
WHERE combined.date = '2012-09-14'
AND combined.cost > 30.0
ORDER BY combined.cost DESC

/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

        SELECT fac.name, SUM(
        CASE
            WHEN book.memid =0 THEN fac.guestcost * book.slots
            ELSE fac.membercost * book.slots
            END ) AS revenue
        FROM Facilities AS fac
        INNER JOIN Bookings AS book ON fac.facid = book.facid
        GROUP BY fac.facid
        HAVING revenue <1000
        ORDER BY revenue DESC


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

        SELECT m1.surname, m1.firstname, m2.surname, m2.firstname
        FROM Members AS m1
        LEFT JOIN Members AS m2 ON m1.recommendedby = m2.memid
        ORDER BY m1.surname, m1.firstname


/* Q12: Find the facilities with their usage by member, but not guests */

        SELECT fac.name, COUNT( * ) AS usage_count
        FROM Facilities AS fac
        INNER JOIN Bookings AS book ON book.facid = fac.facid
        WHERE book.memid <>0
        GROUP BY fac.facid


/* Q13: Find the facilities usage by month, but not guests */

        SELECT fac.name, COUNT( * ) AS usage_count, strftime('%m', starttime ) AS month
        FROM Facilities AS fac
        INNER JOIN Bookings AS book ON book.facid = fac.facid
        WHERE book.memid <>0
        GROUP BY fac.facid, strftime('%m', starttime )
        ORDER BY fac.name, month