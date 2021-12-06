# Full script for rebuilding a Docker container
# https://stackoverflow.com/a/41323079

#!/bin/bash
imageName=xx:my-image
containerName=my-container

docker build -t $imageName -f Dockerfile  .

echo Delete old container...
docker rm -f $containerName

echo Run new container...
docker run -d -p 5000:5000 --name $containerName $imageName
