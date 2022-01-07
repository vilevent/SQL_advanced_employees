
USE employees;

-- Obtain a table containing the following three fields for all individuals 
-- whose employee number is not greater than 10040: 
	-- employee number, 
	-- the lowest department number among the departments where the employee has worked in, 
	-- assign '110022' as 'manager' to all individuals whose employee number is lower than or equal to 10020, 
	-- and '110039' to those whose number is between 10021 and 10040 inclusive. 
SELECT 
	e.emp_no, 
	MIN(de.dept_no) AS dept_no,
    IF(e.emp_no <= 10020, 110022, 110039) AS manager
FROM employees e JOIN dept_emp de
	ON e.emp_no = de.emp_no
WHERE e.emp_no <= 10040
GROUP BY e.emp_no;


-- Create a procedure that asks you to insert an employee number and that will obtain an output containing 
-- the same number, as well as the number and name of the last department the employee has worked in. 
-- Finally, call the procedure for employee number 10010. 
-- You should see that employee number 10010 has worked for department number 6 - "Quality Management". 
DROP PROCEDURE IF EXISTS get_emp_info_dept;

DELIMITER $$

CREATE PROCEDURE get_emp_info_dept (
	IN p_emp_no INT
)
BEGIN
	DECLARE latest_from_date DATE;
    
    SELECT MAX(from_date)
    INTO latest_from_date
    FROM dept_emp
    WHERE emp_no = p_emp_no;
    
    SELECT e.emp_no, d.dept_no, d.dept_name
    FROM employees e JOIN dept_emp de
		ON e.emp_no = de.emp_no
	JOIN departments d 
		ON de.dept_no = d.dept_no
	WHERE e.emp_no = p_emp_no AND de.from_date = latest_from_date;
    
END $$

DELIMITER ;

CALL get_emp_info_dept(10010);


-- How many contracts have been registered in the ‘salaries’ table with duration of more 
-- than one year and of value higher than or equal to $100,000? 
SELECT COUNT(emp_no) AS num_of_contracts
FROM salaries
WHERE salary >= 100000 AND DATEDIFF(to_date, from_date) > 365;


-- Create a trigger that checks if the hire date of a new employee is higher than the current date. 
-- If true, set this date to be the current date. Format the output appropriately (YYYY-MM-DD).
-- Extra challenge: Try to declare a new variable called 'today' which stores today's data, and then use it in your trigger!
-- After creating the trigger, execute the following code to see if it's working properly.
/*
INSERT employees VALUES ('9999040', '1970-01-31', 'John', 'Johnson', 'M', '2035-01-01');  

SELECT 
    *
FROM
    employees
ORDER BY emp_no DESC;
*/

DROP TRIGGER IF EXISTS before_insert_emp_hire_date;

DELIMITER $$

CREATE TRIGGER before_insert_emp_hire_date
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
	DECLARE today DATE;
    
    SET today = CURDATE();
    
	IF NEW.hire_date > today THEN
		SET NEW.hire_date = today;
	END IF;
END $$

DELIMITER ;


COMMIT;

INSERT employees VALUES ('9999040', '1970-01-31', 'John', 'Johnson', 'M', '2035-01-01');  

SELECT 
    *
FROM
    employees
ORDER BY emp_no DESC;

ROLLBACK;


-- Create a function that accepts an employee number and a second parameter which would be a character sequence. 
-- Evaluate if its value is 'min' or 'max', and based on that retrieve either the lowest or the highest salary.
-- If this value is a string value different from ‘min’ or ‘max’, then the output of the function should return 
-- the difference between the highest and the lowest salary.
DROP FUNCTION IF EXISTS get_emp_salary_info;

DELIMITER $$

CREATE FUNCTION get_emp_salary_info (
	p_emp_no INT,
    char_seq VARCHAR(25)
)
RETURNS INT
DETERMINISTIC
BEGIN

	DECLARE salary_calc INT;
    
    IF char_seq = 'min' THEN
		(SELECT MIN(salary)
		INTO salary_calc
		FROM salaries
		WHERE emp_no = p_emp_no);
	ELSEIF char_seq = 'max' THEN
		(SELECT MAX(salary)
		INTO salary_calc
		FROM salaries
		WHERE emp_no = p_emp_no);
	ELSE
		(SELECT MAX(salary) - MIN(salary)
		INTO salary_calc
		FROM salaries
		WHERE emp_no = p_emp_no);
	END IF;

RETURN salary_calc;	
    
END $$

DELIMITER ;

-- Apply this function to employee number 11356, for all three scenarios. 
-- Then, apply this function to all employees, finding the lowest and highest salary.
SELECT 
	get_emp_salary_info(11356, 'min') AS min_salary,
    get_emp_salary_info(11356, 'max') AS max_salary;
    
SELECT get_emp_salary_info(11356, 'what to write') AS salary_diff;

SELECT 
	emp_no, 
    get_emp_salary_info(emp_no, 'min') AS min_salary, 
    get_emp_salary_info(emp_no, 'max') AS max_salary
FROM employees;


-- Select all records from the employees table of people whose last name is either
-- 'Farris', 'Kulisch', 'Speckmann', or 'Munoz'.
-- Then, create an index on the last_name column of that table. Check if it has sped up the 
-- search of the same SELECT statement, in terms of the number of rows examined.
SELECT e.*, s.salary, s.from_date, s.to_date
FROM employees e JOIN salaries s
	ON e.emp_no = s.emp_no
WHERE last_name IN ('Farris', 'Kulisch', 'Speckmann', 'Munoz'); 

-- Explain_Select_1
EXPLAIN SELECT e.*, s.salary, s.from_date, s.to_date
FROM employees e JOIN salaries s
	ON e.emp_no = s.emp_no
WHERE last_name IN ('Farris', 'Kulisch', 'Speckmann', 'Munoz');

-- DROP INDEX idx_last_name_employees ON employees;

-- Non-clustered index (pointer to the data)
CREATE INDEX idx_last_name_employees ON employees(last_name);

SELECT e.*, s.salary, s.from_date, s.to_date
FROM employees e JOIN salaries s
	ON e.emp_no = s.emp_no
WHERE last_name IN ('Farris', 'Kulisch', 'Speckmann', 'Munoz');

-- Explain_Select_2
EXPLAIN SELECT e.*, s.salary, s.from_date, s.to_date
FROM employees e JOIN salaries s
	ON e.emp_no = s.emp_no
WHERE last_name IN ('Farris', 'Kulisch', 'Speckmann', 'Munoz');


-- Combine the information (employee number, name, salary, from date, to date) for employees in the salary ranges 
-- [45000, 60000] and [90000, 110000] into a single result set, using UNION or UNION ALL. Try to optimize the performance.
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


-- Extract a dataset containing the following information about the managers: employee number, 
-- first name, and last name. Add two columns at the end – one showing the difference between 
-- the maximum and minimum salary of that employee, and another one saying whether this salary 
-- raise was higher than $30,000, in between $20,000 and $30,000, or lower than $20,000.
SELECT 
	dm.emp_no,
    e.first_name,
    e.last_name,
    MAX(s.salary) - MIN(s.salary) AS salary_raise,
    CASE
		WHEN MAX(s.salary) - MIN(s.salary) > 30000 THEN 'Salary raise was higher than $30,000'
        WHEN MAX(s.salary) - MIN(s.salary) BETWEEN 20000 AND 30000 THEN 'Salary raise was between $20,000 and $30,000'
		ELSE 'Salary raise was lower than $20,000'
	END AS salary_raise_desc
FROM employees e JOIN dept_manager dm
	ON e.emp_no = dm.emp_no
JOIN salaries s
	ON dm.emp_no = s.emp_no
GROUP BY dm.emp_no, e.first_name, e.last_name;


-- Extract the employee number, first name, and last name of the first 1000 employees, 
-- and add a fourth column, called 'emp_status' saying 'Is still employed' if the 
-- employee is still working in the company, or 'Not an employee anymore' if they aren’t.
-- To date of '9999-01-01' signifies that the employee is still working for the company.
SELECT
	e.emp_no,
    e.first_name,
    e.last_name,
    IF(MAX(de.to_date) = '9999-01-01', 'Is still employed', 'Not an employee anymore') AS emp_status
FROM employees e JOIN dept_emp de
	ON e.emp_no = de.emp_no
WHERE e.emp_no <= 11000
GROUP BY e.emp_no;

    