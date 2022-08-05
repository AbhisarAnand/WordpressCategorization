USE lpbi2;
DELIMITER $$
DROP PROCEDURE IF EXISTS categorize $$
CREATE PROCEDURE categorize()


BEGIN

    DECLARE v_type VARCHAR(60) DEFAULT '';
    DECLARE v_row_loop INTEGER DEFAULT 0;
    DECLARE v_type_loop INTEGER DEFAULT 0;
    DECLARE v_author_loop INTEGER DEFAULT 0;
    DECLARE v_correct_post INTEGER DEFAULT 0;
    DECLARE v_correct_post_bool INTEGER DEFAULT 0;
    DECLARE v_author_name VARCHAR(60) DEFAULT '';
    DECLARE v_author_first_name VARCHAR(60) DEFAULT '';
    DECLARE v_author_last_name VARCHAR(60) DEFAULT '';
    DECLARE v_type_pos INTEGER DEFAULT 0;
    DECLARE v_bool INTEGER DEFAULT 0;
    DECLARE v_max_char INTEGER DEFAULT 500;
    DECLARE v_scope VARCHAR(1000) DEFAULT '';
    DECLARE v_content VARCHAR(4020) DEFAULT '';
    DECLARE v_post_id BIGINT;
    DECLARE v_post_title TEXT;
    DECLARE v_category_id BIGINT;
    DECLARE v_parent_id BIGINT DEFAULT 0;

    DECLARE content
        CURSOR FOR
        SELECT ID,
               post_title,
               CONCAT(SUBSTR(post_content, 1, v_max_char),
                      SUBSTR(post_content, length(post_content) - v_max_char, length(post_content))) AS 'Contents'
        FROM servmask_prefix_posts
        WHERE post_status = 'publish'
          AND post_type = 'post';


    DECLARE types
        CURSOR FOR
        SELECT keyword, ID FROM post_type;

    DECLARE names
        CURSOR FOR
        SELECT user_name FROM author_names;

    SELECT COUNT(*)
    INTO v_row_loop
    FROM servmask_prefix_posts
    WHERE post_status = 'publish'
      AND post_type = 'post';

    DROP TABLE IF EXISTS invalid_posts;
    CREATE TABLE invalid_posts
    (
        ID         BIGINT,
        POST_TITLE TEXT,
        CONTENT    LONGTEXT
    );

    OPEN content;
    each_row:
    LOOP
        SET v_correct_post_bool = 0;
        SELECT COUNT(*) INTO v_type_loop FROM post_type;
        FETCH content INTO v_post_id, v_post_title, v_content;
        OPEN types;
        each_type:
        LOOP
            SELECT COUNT(*) INTO v_author_loop FROM author_names;
            FETCH types INTO v_type, v_category_id;
            SET v_type_pos = LOCATE(v_type, v_content);
            IF (v_type_pos > 0) THEN
                SET v_scope = SUBSTR(v_content, v_type_pos, 500);
                OPEN names;
                each_author:
                LOOP
                    FETCH names INTO v_author_name;
                    SET v_author_first_name = SUBSTRING_INDEX(v_author_name, ' ', 1);
                    SET v_author_last_name = SUBSTRING_INDEX(SUBSTRING_INDEX(v_author_name, ' ', 2), ' ', -1);
                    SET v_bool = IF(LOCATE(v_author_first_name, v_scope) > 0 AND
                                    LOCATE(v_author_last_name, v_scope) > 0, 1, 0);
                    IF (v_bool = 1) THEN
                        /*INSERT INTO servmask_prefix_term_relationships (object_id, term_taxonomy_id, term_order)
                        SELECT ID, v_category_id, v_parent_id
                        FROM servmask_prefix_posts p
                        WHERE p.post_type = 'post'
                          AND p.ID = v_post_id;*/
                        SET v_correct_post_bool = 1;
                        SET v_correct_post = v_correct_post + 1;
                    END IF;

                    SET v_author_loop = v_author_loop - 1;

                    IF v_author_loop = 0 THEN
                        LEAVE each_author;
                    END IF;

                END LOOP each_author;
                CLOSE names;
            END IF;

            SET v_type_loop = v_type_loop - 1;

            IF v_type_loop < 1 THEN
                LEAVE each_type;
            END IF;

        END LOOP each_type;
        CLOSE types;

        SET v_row_loop = v_row_loop - 1;

        IF v_row_loop < 1 THEN
            LEAVE each_row;
        END IF;

        IF (v_correct_post_bool = 0) THEN
            INSERT INTO invalid_posts (ID, POST_TITLE, CONTENT) VALUES (v_post_id, v_post_title, v_content);
        END IF;

    END LOOP each_row;
    CLOSE content;
    SELECT v_correct_post;
    SELECT * FROM invalid_posts;
END$$
DELIMITER ;

CALL categorize();
