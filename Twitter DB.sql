DROP DATABASE IF EXISTS twitter_db;

CREATE DATABASE twitter_db;

USE twitter_db;

DROP TABLE IF EXISTS users;

CREATE TABLE users (
	user_id INT NOT NULL AUTO_INCREMENT,
	user_handle VARCHAR(50) NOT NULL UNIQUE,
	email_address VARCHAR(50) NOT NULL UNIQUE,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100) NOT NULL,
	phonenumber CHAR(10) UNIQUE,
    follower_count INT NOT NULL DEFAULT 0,
	created_at TIMESTAMP NOT NULL DEFAULT (NOW()),
	primary key(user_id)
);

INSERT INTO users(user_handle, email_address, first_name, last_name, phonenumber)
VALUES 
('Álvaro99', 'alvaromoreno89@gmail.com', 'Alvaro', 'Moreno', '6233456742'),
('Elora_MorSev', 'elorasevilla02@hotmail.com', 'Elora', 'Moreno', '735295435'),
('Thalesillo', 'thalesnogueira@outlook.com', 'Thales', 'Hipolito', '139244689'),
('Antonio2769', 'aamorenomanzano@gmail.com', 'Antonio A.', 'Moreno', '214235322'),
('VirginiaSevilla30', 'vsevilla@hotmail.com', 'Virginia', 'Sevilla', '284172356');

DROP TABLE IF EXISTS followers;

CREATE TABLE followers (
	follower_id INT NOT NULL,
    following_id INT NOT NULL,
    FOREIGN KEY (follower_id) REFERENCES users(user_id),
    FOREIGN KEY (following_id) REFERENCES users(user_id),
    PRIMARY KEY (follower_id, following_id)
);

-- Desde la versión 8 de MySQL
-- Se pueden añadir constrains (condiciones) para hacer checks

ALTER TABLE followers 
ADD CONSTRAINT check_follower_id
CHECK (follower_id != following_id);

INSERT INTO followers (follower_id, following_id)
VALUES 
(1,2),
(2,1),
(3,1),
(4,1);

-- Consultas Sencillas
/*
SELECT follower_id, following_id FROM followers;
SELECT follower_id FROM followers WHERE following_id = 1;
SELECT COUNT(follower_id) AS followers FROM followers WHERE following_id = 1;
*/

-- Top 3 usuarios con mayor número de seguidores
/*
SELECT following_id, COUNT(follower_id) AS followers
FROM followers
GROUP BY following_id
ORDER BY followers DESC
LIMIT 3;
*/

-- Top 3 usuarios con mayor número de seguidores (con JOIN, podemos sacar más info)
/*
SELECT users.user_id, users.user_handle, users.first_name, following_id, COUNT(follower_id) AS followers
FROM followers
JOIN users ON users.user_id = followers.following_id
GROUP BY following_id
ORDER BY followers DESC
LIMIT 3;
*/

DROP TABLE IF EXISTS tweets;

CREATE TABLE tweets(
	tweet_id INT NOT NULL UNIQUE AUTO_INCREMENT,
    user_id INT NOT NULL,
    tweet_text VARCHAR(280) NOT NULL,
    num_likes INT DEFAULT 0,
    num_comments INT DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT(NOW()),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    PRIMARY KEY (tweet_id)
    );

INSERT INTO tweets(user_id, tweet_text)
VALUES
(1, 'Hola mundo'),
(3, 'Vaya verano más caluroso'),
(4, 'Me llamo Antonio y soy nuevo en Twitter'),
(2, 'He preparado un gazpacho para aplacar los rigores del verano'),
(1, 'Esto es Twitter 2?'),
(1, 'Not my cup of tea'),
(5, '¿Cómo funciona esto?'),
(2, 'Me pedirá matrimonio Thales?');
-- El resto de atributos presentes en la tabla no se insertan pues tienen valores por defecto, timestamp o autoincremental

-- ¿Cuántos tweets ha escrito un usuario?
/*
SELECT user_id, COUNT(*) AS tweet_count
FROM tweets WHERE user_id = 1;
*/
-- Esto no es lo que hace twitter cuando nos muestra cuantos tweets hemos realizado a lo largo
-- del tiempo, ya que hacer esto para millones de usuarios tendría un coste de procesamiento
-- para la API bestial. Lo que hacen en su lugar es usar TRIGGERS, que enseñaremos más adelante.

-- Obtener los usuarios con más de 2 seguidores
/*
SELECT following_id 
FROM followers 
GROUP BY following_id 
HAVING COUNT(*) > 2; 
*/

-- Sub consulta
-- Obtener los tweets de los usuarios que tienen más de 2 seguidores
/*
SELECT tweet_id, tweet_text, user_id
FROM tweets
WHERE user_id IN(
	SELECT following_id
    FROM followers
    GROUP BY following_id
    HAVING COUNT(*) > 2
 );
*/

-- DELETE
/*
DELETE FROM tweets WHERE tweet_id = 1;
DELETE FROM tweets WHERE user_id = 1;
DELETE FROM tweets WHERE tweet_text LIKE '%gazpacho%';
*/

-- UPDATE
/*
UPDATE tweets SET num_comments = num_comments + 1 WHERE tweet_id = 3;
*/

-- Reemplazar texto
/*
UPDATE tweets SET tweet_text = REPLACE(tweet_text, 'Twitter', 'Threads') 
WHERE tweet_text LIKE '%Twitter%';
*/

DROP TABLE IF EXISTS tweet_likes;

CREATE TABLE tweet_likes(
	user_id INT NOT NULL,
    tweet_id INT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (tweet_id) REFERENCES tweets(tweet_id),
    PRIMARY KEY (user_id, tweet_id)
);

-- Para que un usuario no se de like a su propio tweet hacemos la siguiente constraint
/*
ALTER TABLE tweet_likes 
ADD CONSTRAINT check_user_id
CHECK (user_id != tweets.user_id);
*/

INSERT INTO tweet_likes (user_id, tweet_id)
VALUES (1, 4), (1, 3), (2, 5), (3, 4), (4, 5), (5,2), (3, 1), (5, 4), (2, 4); 
    
-- Consulta: Obtener el número de likes por tweet
SELECT tweet_id, COUNT(*) AS like_count
FROM tweet_likes
GROUP BY tweet_id;

-- TRIGGER para follow
DROP TRIGGER IF EXISTS increase_follower_count;

DELIMITER ..
CREATE TRIGGER increase_follower_count
	AFTER INSERT ON followers
    FOR EACH ROW
    BEGIN
		UPDATE users SET follower_count = follower_count + 1
        WHERE user_id = NEW.following_id;
    END..

INSERT INTO followers (follower_id, following_id)
VALUES
(2,3),
(4,5),
(5,2),
(4,2),
(2,4);


-- TRIGGER para unfollow
DROP TRIGGER IF EXISTS decrease_follower_count;

DELIMITER ..
CREATE TRIGGER decrease_follower_count
	AFTER DELETE ON followers
    FOR EACH ROW
    BEGIN
		UPDATE users SET follower_count = follower_count - 1
        WHERE user_id = NEW.following_id;
    END..

DELETE FROM followers WHERE follower_id = 1 AND following_id = 2;
