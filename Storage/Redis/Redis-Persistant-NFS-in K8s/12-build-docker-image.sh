docker build -t apps-redis:1.0.0 -f DockerFile .
docker images

docker tag apps-redis:1.0.0 ajanthaneng/apps-redis:1.0.0
docker push ajanthaneng/apps-redis:1.0.0