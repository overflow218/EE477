/*
Customer = {customerID, firstName, lastName, income, birthData}
Account = {accNumber, type, balance, branchNumber FK-Branch}
Owns = {customerID FK-Customer, accNumber FK-Account}
Transactions = {transNumber, accNumber FK-Account, amount}
Employee = {sin1, firstName, lastName, salary, branchNumber FK-Branch} 
Branch = {branchNumber, branchName, managerSIN FK-Employee, budget}
*/


/*
(1) Select the [first name, last name, income] of customers whose income is within 
[$50,000, $60,000] and order by income (desc), last name (asc), and then first name (asc).
*/
select firstName, lastName, income
from Customer
where income BETWEEN 50000 AND 60000
ORDER BY income DESC, lastName, firstName
LIMIT 10;
select firstName, lastName, income from Customer where income BETWEEN 50000 AND 60000 ORDER BY income DESC, lastName, firstName LIMIT 10;

/*
(2) Select the [SIN, branch name, salary, manager’s salary - salary (that is, the salary of the employee’s manager minus salary of the employee)] 
of all employees in London or Berlin, and order by descending (manager’s salary - salary).
저거 매니저 월급을 알아야하는데 이거 어케 구하노 
*/
select sin, branchName, salary, (SELECT salary from Employee where sin = managerSIN) - salary as salaryDiff
from Employee natural JOIN Branch
where branchName = 'Berlin' OR branchName = 'London'
ORDER BY salaryDiff DESC LIMIT 10;

/*
(3) Select the [first name, last name, income] of customers 
whose income is at least double the income of every customer whose last name is Butler, 
and order by last name (asc) then first name (asc).
*/
select firstName, lastName, income
from Customer
where income >= all (select income * 2 from Customer where lastName = 'Butler')
ORDER BY lastName, firstName LIMIT 10;


/*
(4) Select the [customer ID, income, account number, branch number] of customers 
with incomes greater than $80,000 who own an account at both London and Latveria branches, 
and order by customer ID (asc) then account number (asc). 
The result should contain all the account numbers of customers who meet the criteria, 
even if the account itself is not held at London or Latveria. 
For example, if a customer with an income greater than $80,000 owns accounts in London, Latveria, and New York, 
the customer meets the criteria, and the New York account must also be in the result.
*/
select Customer.customerID, income, Owns.accNumber, Account.branchNumber
from Customer natural JOIN Owns natural JOIN Account, (SELECT Customer.customerID from Customer natural JOIN Owns natural JOIN Account natural JOIN Branch where branchName = 'London' or branchName = 'Latveria' and income > 80000 GROUP BY(Customer.customerID) HAVING COUNT(DISTINCT branchName) = 2) s2 
WHERE Customer.customerID = s2.customerID
ORDER BY Customer.customerID, Owns.accNumber
LIMIT 10;

/*
(5) Select the [customer ID, type, account number, balance] of business (type BUS) and savings (type SAV) accounts 
owned by customers who own at least one business account or at least one savings account, 
and order by customer ID (asc), type (asc), and then account number (asc).
*/

-- 위랑 아래랑 동일한 결과임
select Customer.customerID, Account.type, accNumber, balance
from Customer natural JOIN Owns natural JOIN Account, (select customerID from Customer natural JOIN Owns natural JOIN Account WHERE Account.type in ('BUS', 'SAV') GROUP BY Customer.customerID) s2
WHERE Customer.customerID = s2.customerID and Account.type in ('BUS', 'SAV')
ORDER BY Customer.customerID, Account.type, accNumber
LIMIT 10;

select Customer.customerID, Account.type, accNumber, balance
from Customer natural JOIN Owns natural JOIN Account
WHERE Account.type in ('BUS', 'SAV')
ORDER BY Customer.customerID, Account.type, accNumber
LIMIT 10;

/*

(6) Select the [branch name, account number, balance] of accounts with balances greater than $100,000 
held at the branch managed by Phillip Edwards, and order by account number (asc).
*/

select branchName, accNumber, balance
from Account natural JOIN Branch
WHERE balance > 100000 and Account.branchNumber in (SELECT branchNumber from Employee natural JOIN Branch WHERE sin = managerSIN and firstName = 'Phillip' and lastName ='Edwards')
ORDER BY accNumber
LIMIT 10;

select branchName, accNumber, balance
from Account natural JOIN Branch
WHERE balance > 100000 and EXISTS (SELECT branchNumber from Employee natural JOIN Branch WHERE sin = managerSIN and Account.branchNumber = Branch.branchNumber and firstName = 'Phillip' and lastName ='Edwards')
ORDER BY accNumber
LIMIT 10;

/*
(7) Select the [customer ID] of customers that 
1) have an account at the New York branch, -> 뉴욕 브랜치 어카운트 쿼리하나
2) do not own an account at the London branch, -> 런던 브랜치 어카운트 쿼리하나를 2,3번 묶어서 하나 만들면 좋을듯
3) do not co-own an account with another customer who owns an account at the London branch. 
Order the result by customer ID (asc). The result should not contain duplicate customer IDs. 
Write a query satisfying all three conditions.
*/

# 뉴욕에 있는 계좌있는 사람 정보
SELECT accNumber
FROM Account natural JOIN Branch
WHERE branchName = 'New York'

# 뉴욕에 계좌있는 사람의 아이디
SELECT customerID FROM Customer natural JOIN Owns natural JOIN Account natural JOIN Branch WHERE branchName = 'New York'
#이게 런던에 계좌있는 사람의 아이디
SELECT customerID FROM Customer natural JOIN Owns natural JOIN Account natural JOIN Branch WHERE branchName = 'London'

# 런던에 계좌 가지고 있는 고객의 아이디
SELECT distinct customerID
FROM Account natural JOIN Branch natural JOIN Owns
WHERE branchName = 'LonDon'

# 런던에 계좌를 가지고 있는 사람들이 가진 전체 계좌 -> 이제 이거랑 겹치는게 있으면 안됨.
SELECT distinct accNumber
from (SELECT distinct customerID FROM Account natural JOIN Branch natural JOIN Owns WHERE branchName = 'LonDon') london,
Customer natural JOIN Owns
WHERE Customer.customerID = london.customerID

# 일단 되는거
select distinct customerId
FROM Customer natural JOIN Owns s1
where EXISTS (SELECT customerID FROM Customer natural JOIN Owns natural JOIN Account natural JOIN Branch WHERE branchName = 'New York' and s1.customerID = customerID) 
and NOT EXISTS (SELECT customerID FROM Customer natural JOIN Owns natural JOIN Account natural JOIN Branch WHERE branchName = 'London' and s1.customerID = customerID)
and NOT EXISTS (SELECT distinct accNumber from (SELECT distinct customerID FROM Account natural JOIN Branch natural JOIN Owns WHERE branchName = 'LonDon') london, Customer natural JOIN Owns WHERE Customer.customerID = london.customerID and accNumber = s1.accNumber)
LIMIT 10;

/*
(8) Select the [SIN, first name, last name, salary, branch name] of employees who earn more than $50,000. 
If an employee is a manager, show the branch name of his/her branch. 
Otherwise, insert a NULL value for the branch name (the fifth column). 
Order the result by branch name (desc) then first name (asc). 
You must use an outer join in your solution for this problem.
*/

select sin, firstName, lastName, salary, CASE 
    WHEN sin = managerSIN THEN branchName
    ELSE NULL
END as branchName
from Employee full JOIN Branch USING(branchNumber)
WHERE salary > 50000
ORDER BY branchName DESC, firstName
LIMIT 10;

/*
(9) Solve question (8) again without using any join operations. 
Here, using an implicit cross join such as FROM A, B is accepted, 
but there should be no JOIN operator in your query.
*/

select sin, firstName, lastName, salary, CASE 
    WHEN sin = managerSIN THEN branchName
    ELSE NULL
END as branchName
from Employee, Branch
WHERE salary > 50000 and Employee.branchNumber = Branch.branchNumber
ORDER BY branchName DESC, firstName
LIMIT 10;

/*
이거 아직 다 못했음
(10) Select the [customer ID, first name, last name, income] of customers 
who have incomes greater than $5000 
and own accounts in ALL of the branches that Helen Morgan owns accounts in, 
and order by income (desc). 
For example, if Helen owns accounts in London and Berlin, 
a customer who owns accounts in London, Berlin, and New York has to be included in the result. 
If a customer owns accounts in London and New York, the customer does not have to be in the result. 
The result should also contain Helen Morgan.
*/

SELECT *
from Customer natural JOIN Owns natural JOIN Account natural JOIN Branch
WHERE firstName = 'Helen' and lastName = 'Morgan'
order by customerID

/*
(11) Select the [SIN, first name, last name, salary] of the lowest paid employee (or em- ployees) 
of the Berlin branch, and order by sin (asc).
*/
SELECT sin, firstName, lastName, salary
from Employee natural JOIN Branch, (SELECT MIN(salary) as minSalary from Employee natural JOIN Branch GROUP BY branchName HAVING branchName = 'Berlin') as s2
WHERE branchName = 'Berlin' and salary <= s2.minSalary
ORDER BY sin

/*
(12) Select the [branch name, the difference of maximum salary and minimum salary (salary gap), average salary] 
of the employees at each branch, and order by branch name (asc).
*/
SELECT branchName, MAX(salary) - MIN(salary) as salaryGap, AVG(salary)
from Employee natural JOIN Branch 
GROUP BY branchName
ORDER BY branchName

/*
(13) Select two values: 
(1) the number of employees working at the New York branch and 
(2) the number of different last names of employees working at the New York branch. 
The result should contain two numbers in a single row. 
Name the two columns countNY and coundDIFF using the AS keyword.
*/

SELECT COUNT(sin) as countNY, COUNT(DISTINCT lastName) as countDIFF
from Employee natural JOIN Branch
WHERE branchName = 'New York'

/*
(14) Select the [sum of the employee salaries] at the Moscow branch. The result should contain a single number.
*/

SELECT sum(salary) as totalSalary
from Employee natural JOIN Branch
WHERE branchName = 'Moscow';

/*
(15) Select the [customer ID, first name, last name] of customers who own accounts 
from only four different types of branches, and order by last name (asc) then first name (asc).
*/

SELECT customerID, firstName, lastName
from Customer natural JOIN (SELECT customerID from Customer natural JOIN Owns natural JOIN Account natural JOIN Branch GROUP BY customerID HAVING COUNT(DISTINCT branchNumber) = 4) s2
ORDER BY lastName, firstName;

/*
(16) Select the [average income] of customers older than 60 
and [average income] of customers younger than 26. 
The result should contain the two numbers in a single row. 
(Hint: you can use MySQL time and date functions here):
*/
SELECT (SELECT AVG(income) from Customer WHERE TIMESTAMPDIFF(YEAR, birthData, CURRENT_DATE()) > 60) as oldManIncome, (SELECT AVG(income) from Customer WHERE TIMESTAMPDIFF(YEAR, birthData, CURRENT_DATE()) < 26) as youngManIncome;

/*

(17) Select the [customer ID, first name, last name, income, average account balance] of customers 
who have at least three accounts, 
and whose last names begin with S 
and contain an e (e.g. Steve), 
and order by customer ID (asc).
*/

SELECT customerID, firstName, lastName, income, avgBalance
from Customer natural JOIN (select customerID, AVG(balance) as avgBalance from Customer natural JOIN Owns natural JOIN Account GROUP BY customerID HAVING COUNT(accNumber) >= 3) s1
WHERE lastName like 'S%e%'
ORDER BY customerID
LIMIT 10;



