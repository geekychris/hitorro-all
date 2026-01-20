

## Installing postgres

```sh
docker run -d \                          
  --name postgres \
  --restart unless-stopped \
  -e POSTGRES_USER=chris \
  -e POSTGRES_PASSWORD='change_me' \
  -e POSTGRES_DB=appdb \
  -p 5432:5432 \
  -v /home/chris/data/postgres:/var/lib/postgresql/data \
  postgres:16 
```
## Installing MINIO

``` sh 
docker run -d \
-p 9000:9000 \
-p 9001:9001 \
--name minio \
-e "MINIO_ROOT_USER=admin" \
-e "MINIO_ROOT_PASSWORD=mypassword" \
-v /home/chris/data/minio:/data \
quay.io/minio/minio server /data --console-address ":9001"
```

```` sh
docker run -d \
-p 9000:9000 \
-p 9001:9001 \
--name minio \
-e "MINIO_ROOT_USER=admin" \
-e "MINIO_ROOT_PASSWORD=mypassword" \
-v /Users/chris/data/s3:/data \
quay.io/minio/minio server /data --console-address ":9001"
```

```shell

docker run -d \
-p 6379:6379 \
--name redis-server \
-v /home/chris/data/redis:/data redis redis-server \
--appendonly yes
```


```shell
docker run --name mysql-server \
-p 3306:3306 \
-e MYSQL_ROOT_PASSWORD=password \
-v /home/chris/data/mysql:/var/lib/mysql \
-d mysql:latest
```

```mysql
-- Create the database
CREATE DATABASE htcms
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_general_ci;

-- Create the user (external access from host machine)
-- Note: Use '%' instead of 'localhost' when connecting from outside the Docker container
CREATE USER 'htcms'@'%'
  IDENTIFIED BY 'htcms';

-- Grant full privileges on the htcms database
GRANT ALL PRIVILEGES ON htcms.* TO 'htcms'@'%';

-- Apply privileges
FLUSH PRIVILEGES;

```