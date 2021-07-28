CREATE TABLE DATETIMESTAMPS (
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 10000) PRIMARY KEY,
  name VARCHAR(50),
  date_data DATE,
  time_data TIME,
  timestamp_data TIMESTAMP
)