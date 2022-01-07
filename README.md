# MySQL, Employees DB
> Exercises from Udemy's "SQL - MySQL for Data Analytics and Business Intelligence" course

### Script for creating tables and inserting data for employees database
The source is from this [repository](https://github.com/ofenloch/mysql-employees). The course condensed the relevant DDL and DML statements for each of the tables in one file: `employees.sql`

### Database schema from MySQL Workbench
![employees_schema](https://user-images.githubusercontent.com/96803412/148616452-8fe9a04f-70a2-49f5-8e78-a123eef2158f.png)


### SQL topics covered by the exercises in `SQL_MoreTopics.sql`
- IF function
- DATEDIFF function
- UNION ALL
- IF-THEN-ELSEIF-ELSE statement
- CASE statement
- Stored procedures
- User-defined functions
- Non-clustered indexes
- Triggers

### Query performance optimization
#### Exercise: 
> Select all records from the employees table of people whose last name is either 'Farris', 'Kulisch', 'Speckmann', or 'Munoz'.

```sql
SELECT e.*, s.salary, s.from_date, s.to_date
FROM employees e JOIN salaries s
  ON e.emp_no = s.emp_no
WHERE last_name IN ('Farris', 'Kulisch', 'Speckmann', 'Munoz'); 
```
Let's assume the business often needs to fetch rows based on **last name**.

![InkedCapture_LI](https://user-images.githubusercontent.com/96803412/148617594-865833e3-4705-42f0-a50b-ef8c9942b2dc.jpg)
- It is important to note that no index was used when running the query. We also see that there was a **full table scan** for the query's WHERE clause condition. 302,705 rows were examined during the query execution. 
- A full table scan is a **performance hit** that would be more noticeable when we are dealing with millions of records. Thus, we should optimize the query by adding a **non-clustered index**.

#### Execution plan:

![explain](https://user-images.githubusercontent.com/96803412/148619663-9501e6e7-f5b0-4045-ad68-790e48db85cf.png)

#### Creating the non-clustered index for the `employees` table:
```sql
CREATE INDEX idx_last_name_employees ON employees(last_name);
```

Now, with `idx_last_name_employees` added to the database, let's view the Query Statistics when running the same query.

![InkedCapture2_LI](https://user-images.githubusercontent.com/96803412/148618856-c7f1c40e-28eb-4e7c-9d51-7f84645af248.jpg)
- As we can see, the number of rows examined by the query drastically decreased to 3,494. **That is a 98.8% decrease!**
- We also should note that our index was used during query execution, which explains why there is no longer a full table scan.
- If there were millions of records, we would clearly start to witness **faster data retrieval** when running queries that use last name for filtering records.

#### Execution plan:

![explain2](https://user-images.githubusercontent.com/96803412/148619701-ca5024f4-de28-4cb0-9888-796c93bdb94e.png)


#### Another exercise: 
> Combine the information (employee number, name, salary, from date, to date) for employees in the salary ranges [45000, 60000] and [90000, 110000] into a single result set, using UNION or UNION ALL.

```sql
SELECT 
  e.emp_no,
  CONCAT(e.first_name, ' ', e.last_name) AS full_name,
  s.salary,
  s.from_date, 
  s.to_date
FROM employees e JOIN salaries s
  ON e.emp_no = s.emp_no
WHERE s.salary BETWEEN 45000 AND 60000
UNION ALL
SELECT 
  e.emp_no,
  CONCAT(e.first_name, ' ', e.last_name) AS full_name,
  s.salary,
  s.from_date, 
  s.to_date
FROM employees e JOIN salaries s
  ON e.emp_no = s.emp_no
WHERE s.salary BETWEEN 90000 AND 110000;
```

- In this case, we know that the given salary ranges are **mutually exclusive**. Since we know that there will not be duplicates in the final result set, we can optimize the query performance by choosing to use **UNION ALL**. 
- It would be a performance hit to use UNION here as it requires scanning the entire result set for duplicate rows and removing them (*if they exist*).
