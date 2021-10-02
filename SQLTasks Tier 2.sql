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

SELECT name, membercost
FROM Facilities
WHERE membercost > 0

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(*)
FROM Facilities
WHERE membercost = 0

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance
FROM Facilities
WHERE (membercost < (.2 * monthlymaintenance)) AND membercost > 0


/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
FROM Facilities
WHERE name LIKE '%2'

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name,
	   monthlymaintenance,
CASE WHEN monthlymaintenance > 100 THEN 'expensive'
	ELSE 'cheap' END as costindex
FROM Facilities


/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname, MAX(joindate) AS most_recent
FROM `Members` 

/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT(CONCAT_WS(m.firstname, m.surname, f.name)) AS Member_Facility
FROM Bookings as b
LEFT JOIN Members as m
ON b.memid = m.memid
LEFT JOIN Facilities as f
ON b.facid = f.facid
WHERE b.facid = 0 or b.facid = 1
ORDER BY m.surname DESC, m.firstname

/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT 
	(CASE WHEN b.memid = 0 THEN  CONCAT_WS('GUEST', ' ', f.name)
     ELSE CONCAT_WS(m.firstname, m.surname, f.name) 
     END) AS Member_Facility,

	(CASE WHEN m.memid = 0 THEN f.guestcost * slots
          ELSE f.membercost * slots END) AS Cost
FROM Bookings as b
LEFT JOIN Members as m
ON b.memid = m.memid
LEFT JOIN Facilities as f
ON b.facid = f.facid
WHERE starttime LIKE '2012-09-14%'
AND 30 < (CASE WHEN m.memid = 0 THEN f.guestcost * slots
          ELSE f.membercost * slots END)
ORDER BY Cost desc

/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT
CONCAT( firstname, " ", surname ) AS cust_name,
name AS facility,
cost
FROM

(SELECT
m.firstname,
m.surname,
f.name,
b.starttime,
CASE WHEN firstname = 'GUEST' THEN guestcost * slots ELSE membercost * slots END AS cost
FROM Members m
INNER JOIN Bookings b
ON m.memid = b.memid
INNER JOIN Facilities f
ON b.facid = f.facid) AS inner_table

WHERE starttime LIKE '%2012-09-14%'
AND cost > 30
ORDER BY cost DESC;



/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  

QUESTIONS:

/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

/*### Had a chat with an on demand mentor they suggested that I didn't need to copy the python that enabled
these calls, just copy the sql that worked so... I did. */

SELECT
name,
revenue
FROM
(SELECT f.name AS name,
SUM(CASE WHEN b.memid = 0 THEN guestcost * slots ELSE membercost * slots END) AS revenue

FROM Facilities AS f
LEFT JOIN Bookings as b
ON f.facid =b.facid
GROUP BY b.facid) AS RevTable
WHERE revenue < 1000
ORDER BY revenue DESC

/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT
DISTINCT(m.memid),
m.firstname, 
m.surname,
m.recommendedby,
m2.firstname AS recomender

FROM Members as m
INNER JOIN Members as m2
ON m.recommendedby = m2.memid

WHERE m.memid > 0 
AND m.recommendedby > 0
ORDER BY m.memid

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT
name,
totaluse
FROM
(SELECT f.name AS name,
SUM(CASE WHEN b.memid = 0 THEN 0 ELSE 1 END) AS totaluse
FROM Facilities AS f
LEFT JOIN Bookings as b
ON f.facid =b.facid
GROUP BY b.facid) AS usetable

ORDER BY totaluse DESC

/* Q13: Find the facilities usage by month, but not guests */

SELECT
name,
totaluse,
STRFTIME('%Y-%m', starttime)
FROM
(SELECT f.name AS name,
 b.starttime,
SUM(CASE WHEN b.memid = 0 THEN 0 ELSE 1 END) AS totaluse
FROM Facilities AS f
LEFT JOIN Bookings as b
ON f.facid =b.facid
GROUP BY b.facid, STRFTIME('%Y-%m', starttime)
) AS usetable

ORDER BY totaluse DESC