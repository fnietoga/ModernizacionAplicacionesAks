###LOCAL TEST####
cd C:\repos\kabelTFS\Webinars\ModernizacionAplicaciones\app
docker network create pocmodapp

#Start mongodb container & Init db#
docker container run --name mongo --net pocmodapp -p 27017:27017 -d mongo:4.0
cd content-init
npm install
node server.js

mongosh
show dbs
use contentdb
show collections
db.speakers.find()
db.sessions.find()
quit()

#start API#
cd ../content-api
npm install
node ./server.js &
curl http://localhost:3001/speakers

#start WEB#
cd ../content-web
npm install
ng build
node ./app.js &
curl http://localhost:3000


##STOP ALL##
taskkill /f /im node.exe