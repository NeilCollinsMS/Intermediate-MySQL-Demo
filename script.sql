# Neil Collins MySQL Database Demo

CREATE SCHEMA IF NOT EXISTS studperformance;

USE studperformance;

# Data was loaded from CSV using Table Data Import Wizard, file name: studentsperformance.csv

RENAME TABLE studentsperformance TO performance;

SELECT * FROM performance;

# Breaking this table down into multiple tables would make it more complicated than it needs to begin
# If I were working with a more complex data set, I would generate multiple tables, generate primary keys, and link them with foreign keys
# However, that would just make the data dirtier to work with needlessly. I will attempt to find a proper data set to demonstrate joins at a later date.

ALTER TABLE performance RENAME COLUMN `race/ethnicity` TO race_eth; 
ALTER TABLE performance RENAME COLUMN `parental level of education` TO parent_edu; 
ALTER TABLE performance RENAME COLUMN `test preparation course` TO test_prep;
ALTER TABLE performance RENAME COLUMN `math score` TO math_score;
ALTER TABLE performance RENAME COLUMN `reading score` TO reading_score; 
ALTER TABLE performance RENAME COLUMN `writing score` TO writing_score;   

# Common Table Expression (CTE) Query (Queries) - What demographics scored the highest?

WITH HighScorers(gender, race_eth, parent_edu, lunch) AS
(
	SELECT gender, race_eth, parent_edu, lunch
    FROM performance
    WHERE (math_score + reading_score + writing_score) > 250
)
SELECT gender, count(gender) AS 'count' 
FROM HighScorers 
GROUP BY gender;

WITH HighScorers(gender, race_eth, parent_edu, lunch) AS
(
	SELECT gender, race_eth, parent_edu, lunch
    FROM performance
    WHERE (math_score + reading_score + writing_score) > 250
)
SELECT race_eth, count(race_eth) AS 'count' 
FROM HighScorers 
GROUP BY race_eth;

WITH HighScorers(gender, race_eth, parent_edu, lunch) AS
(
	SELECT gender, race_eth, parent_edu, lunch
    FROM performance
    WHERE (math_score + reading_score + writing_score) > 250
)
SELECT parent_edu, count(parent_edu) AS 'count' 
FROM HighScorers 
GROUP BY parent_edu
ORDER BY count(parent_edu) DESC;

WITH HighScorers(gender, race_eth, parent_edu, lunch) AS
(
	SELECT gender, race_eth, parent_edu, lunch
    FROM performance
    WHERE (math_score + reading_score + writing_score) > 250
)
SELECT lunch, count(lunch) AS 'count' 
FROM HighScorers 
GROUP BY lunch;

# Procedure: Categorize students by score tiers

delimiter //

CREATE PROCEDURE ScoreTier(INOUT math INT(3), INOUT reading INT(3), INOUT writing INT(3), OUT tier VARCHAR(15))
BEGIN
	SET math = @math;
    
    SET reading = @reading;
    
    SET writing = @writing;
    
    IF((math + reading + writing) = 300) THEN
    SET tier = 'Perfect Score';
    ELSEIF((math + reading + writing) >= 250) THEN
    SET tier = 'High Score';
    ELSEIF((math + reading + writing) >= 175) THEN
    SET tier = 'Passing Score';
    ELSEIF((math + reading + writing) < 175) THEN
    SET tier = 'Failing Score';
    END IF;
    
END//
delimiter ;

SET @math = 80;
SET @reading = 80;
SET @writing = 90;
CALL ScoreTier(@math,@reading,@writing,@tier);
SELECT @math,@reading,@writing,@tier;

# Stored Function: Calculate Total Score

DROP FUNCTION IF EXISTS ScoreCalc 

delimiter //
CREATE FUNCTION ScoreCalc(math_score INT(3), reading_score INT(3), writing_score INT(3))
RETURNS INT(3)
DETERMINISTIC
BEGIN
	DECLARE Total_Score INT(3);
    SET Total_Score = (math_score + reading_score + writing_score);
RETURN(Total_Score);
END//
delimiter ;

SELECT gender, race_eth, parent_edu, lunch, test_prep, math_score, reading_score, writing_score, ScoreCalc(math_score, reading_score, writing_score) AS 'Total Score'
FROM performance
WHERE ScoreCalc(math_score, reading_score, writing_score) >= 250
ORDER BY ScoreCalc(math_score, reading_score, writing_score) DESC;

# Stored Trigger: Maintaining data entry integrity of inserted test scores. This version just adjusts <0 to 0 and >100 to 100. 

# The second version will reject invalid inserts and return a message.

# Math Trigger 1

DROP TRIGGER IF EXISTS Math_Check;

delimiter //

CREATE TRIGGER Math_Check
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.math_score < 0) THEN SET NEW.math_score = 0;
    ELSEIF(NEW.math_score > 100) THEN SET NEW.math_score = 100;
	END IF;
END //

delimiter ;

# Reading Trigger 1

DROP TRIGGER IF EXISTS Reading_Check;

delimiter //

CREATE TRIGGER Reading_Check
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.reading_score < 0) THEN SET NEW.reading_score = 0;
    ELSEIF(NEW.reading_score > 100) THEN SET NEW.reading_score = 100;
	END IF;
END //

delimiter ;

# Writing Trigger 1

DROP TRIGGER IF EXISTS Writing_Check;

delimiter //

CREATE TRIGGER Writing_Check
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.writing_score < 0) THEN SET NEW.writing_score = 0;
    ELSEIF(NEW.writing_score > 100) THEN SET NEW.writing_score = 100;
	END IF;
END //

delimiter ;

# Test

INSERT INTO performance(test_prep,math_score,reading_score,writing_score) VALUES('TEST SAMPLE',-4,112,33);

SET SQL_SAFE_UPDATES = 0; # ONLY USE THIS COMMAND IF YOU COMPLETELY UNDERSTAND WHAT YOUR QUERY IS DOING.

DELETE FROM performance WHERE test_prep = 'TEST SAMPLE';

# Now, a version of these triggers that instead denies the update and provides a warning message. 

##############################

DROP TRIGGER IF EXISTS Math_Check;
DROP TRIGGER IF EXISTS Reading_Check;
DROP TRIGGER IF EXISTS Writing_Check;

# Math Trigger 2 (ALTERNATE)

DROP TRIGGER IF EXISTS Math_Check2;

delimiter //

CREATE TRIGGER Math_Check2
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.math_score < 0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID MATH INPUT';
    ELSEIF(NEW.math_score > 100) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID MATH INPUT';
	END IF;
END //

delimiter ;

# Reading Trigger 2 (ALTERNATE)

DROP TRIGGER IF EXISTS Reading_Check2;

delimiter //

CREATE TRIGGER Reading_Check2
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.reading_score < 0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID READING INPUT';
    ELSEIF(NEW.reading_score > 100) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID READING INPUT';
	END IF;
END //

delimiter ;

# Writing Trigger 2 (ALTERNATE)

DROP TRIGGER IF EXISTS Writing_Check2;

delimiter //

CREATE TRIGGER Writing_Check2
BEFORE INSERT ON performance FOR EACH ROW
BEGIN
	IF(NEW.writing_score < 0) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID WRITING INPUT';
    ELSEIF(NEW.writing_score > 100) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID WRITING INPUT';
	END IF;
END //

delimiter ;

# Test

INSERT INTO performance(test_prep,math_score,reading_score,writing_score) VALUES('TEST SAMPLE',-4,112,33);

INSERT INTO performance(test_prep,math_score,reading_score,writing_score) VALUES('TEST SAMPLE',4,112,33);

INSERT INTO performance(test_prep,math_score,reading_score,writing_score) VALUES('TEST SAMPLE',4,112,-33);

INSERT INTO performance(test_prep,math_score,reading_score,writing_score) VALUES('TEST SAMPLE CHARACTER CHARACTER CHARACTER',4,12,33);

SET SQL_SAFE_UPDATES = 0; # ONLY USE THIS COMMAND IF YOU COMPLETELY UNDERSTAND WHAT YOUR QUERY IS DOING.

DELETE FROM performance WHERE test_prep = 'TEST SAMPLE';

DELETE FROM performance WHERE test_prep = 'TEST SAMPLE CHARACTER CHARACTER CHARACTER';

##############################

SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = 'studperformance' AND table_name = 'performance';

##############################

# Window function to rank student scores, partitioned by gender to get a rank set for each gender - SKIPS RANKS AFTER A TIE

SELECT gender, race_eth, parent_edu, lunch, test_prep, math_score, reading_score, writing_score, ScoreCalc(math_score, reading_score, writing_score) AS 'Total Score',
RANK() OVER(PARTITION BY gender ORDER BY ScoreCalc(math_score, reading_score, writing_score) DESC) AS 'Rank'
FROM performance;

############################## 

# Window function to rank student scores, partitioned by gender to get a rank set for each gender  - DOES NOT SKIP RANKS

SELECT gender, race_eth, parent_edu, lunch, test_prep, math_score, reading_score, writing_score, ScoreCalc(math_score, reading_score, writing_score) AS 'Total Score',
DENSE_RANK() OVER(PARTITION BY gender ORDER BY ScoreCalc(math_score, reading_score, writing_score) DESC) AS 'Rank'
FROM performance;

##############################

# Same Window function before utilizing a row number; could potentially be a unique identifier though we'd usually use an auto_increment for that

SELECT gender, race_eth, parent_edu, lunch, test_prep, math_score, reading_score, writing_score, ScoreCalc(math_score, reading_score, writing_score) AS 'Total Score',
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY ScoreCalc(math_score, reading_score, writing_score) DESC) AS 'Row Number'
FROM performance;

##############################

# Basic subquery that pulls the demographics and values of the top 10 scoring students, regardless of gender
# I personally prefer using CTEs or Window Functions when Subqueries get more complicated, but I will generate some more complicated Subquery demos

SELECT gender, race_eth, parent_edu, lunch, test_prep, math_score, reading_score, writing_score, ScoreCalc(math_score, reading_score, writing_score) AS 'Total Score'
FROM (
SELECT *
FROM performance
ORDER BY ScoreCalc(math_score, reading_score, writing_score) DESC
LIMIT 10) Subtable

##############################
