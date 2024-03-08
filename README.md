# ProcessMaker 4.9.2 Core Docker Instance

This docker-compose setup allows you to quickly start up an instance of ProcessMaker4 Core to test with.

This build has no enterprise packages.

## Requirements
- Docker Engine >= 3.2
  - For Mac and Windows Users, we recommend [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - For other installation options: [Install Instructions](https://docs.docker.com/engine/install/)
  
- Docker Compose >= 1.2
  - If using Docker Desktop, Compose is already included
  - For all others: [Install Instructions](https://docs.docker.com/compose/install/)

## Running an instance

1. Clone or download this repo

1. Modify the .env file *(optional)*

   | Variable | Description |
   | --- | --- |
   | PM_VERSION | The version to install from dockerhub. Must match one of the tags at https://hub.docker.com/r/processmaker/pm4-core/tags or [build it locally](#building-the-application-image-locally)|
   | PM_APP_URL | The base URL that's accessible from outside the container. This will usually be `http://localhost` but you can change it if you customize your hosts file and add `extra_hosts` to the docker-compose.yml |
   | PM_APP_PORT | Choose a different port if 8080 is in use on your host |
   | PM_BROADCASTER_PORT | Choose a different port for the Socket.io server if 6001 is in use on your host |
   | PM_DOCKER_SOCK | Location of your docker socket file. See [note](#bind-mounting-the-docker-socket) |

1. Run `docker-compose up`

   This will pull the image if it doesn't exist. It's >2 gigabytes so it could take some time.

   If this is the first time running, it will run the install script and seed the database.
   This part usually takes a few minutes but if script executor images need to be downloaded and built it will take a few extra minutes.

   The instance should now be available at http://localhost:8080 (or where ever you configured it in the .env file)

   Username: **admin** Password: **admin123**

   `ctrl+c` will gracefully stop all containers but will not remove them so changes will persist.

   If you need a clean environment or made changes to config files, you can reinstall with
   ```
   docker-compose down -v
   docker-compose up
   ```

## Building the application image locally
```
docker build -t processmaker:base74 -f Dockerfile.php74 .

docker compose build
```

## Bind-mounting the docker socket
The instance uses the host's docker server by bind-mounting your docker sock file.
This allows for smaller images and better performance than using dind (docker in docker).
See [this post](http://jpetazzo.github.io/2015/09/03/do-not-use-docker-in-docker-for-ci/) for more info.
The host socket file is usually at /var/run/docker.sock but can be changed in the .env file
