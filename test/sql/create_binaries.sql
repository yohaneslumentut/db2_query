CREATE TABLE BINARIES (
  id INT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 10000) PRIMARY KEY,
  name VARCHAR(50),
  data BINARY
)