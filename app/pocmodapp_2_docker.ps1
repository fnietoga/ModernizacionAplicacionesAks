###DOCKER TEST#####
cd C:\repos\kabelTFS\Webinars\ModernizacionAplicaciones\app

##Build API image##
cd ./content-api
docker image build -t content-api .
docker image ls

##Build WEB image##
cd ../content-web
docker image build -t content-web .
docker image ls

##Run containers##
docker container run --name api --net pocmodapp -d -p 3001:3001 -e MONGODB_CONNECTION=mongodb://mongo:27017/contentdb content-api
docker container run --name web --net pocmodapp -d -p 3000:3000 -e CONTENT_API_URL=http://api:3001 content-web

curl http://localhost:3001/speakers
curl http://localhost:3000/speakers.html


##STOP ALL##
docker container rm -f web
docker container rm -f api
docker container rm -f mongo