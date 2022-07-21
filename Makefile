tomcat: docker_start
	docker cp $(spring4shell_container):/usr/local/tomcat .

spring4shell_container := `docker-compose ps -q spring4shell`

docker_start:
	docker-compose up -d
