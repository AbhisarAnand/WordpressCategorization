USE lpbi2;
DROP TABLE IF EXISTS post_type;
CREATE TABLE post_type
(
    keyword varchar(60),
    ID    BIGINT
);

INSERT INTO post_type (keyword, ID)
VALUES ('Author', 0);
INSERT INTO post_type (keyword, ID)
VALUES ('Writ', 0);
INSERT INTO post_type (keyword, ID)
VALUES ('Editor', 0);
INSERT INTO post_type (keyword, ID)
VALUES ('Curat', 0);
INSERT INTO post_type (keyword, ID)
VALUES ('Report', 0);

commit;
