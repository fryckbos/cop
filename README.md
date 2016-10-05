Repository for setting up CoScale on-premise.

Installation
====

Update *conf.sh* with your installations parameters. The most important fields to fill in are the **API_URL** and **APP_URL**. These should be set to 'http://<hostname>'. For example:

    APP_URL=http://coscale.company.com
    API_URL=http://coscale.company.com
    API_SUPER_USER=super@company.com
    API_SUPER_PASSWD=mySUPERsecurePASSWORD

Pull the images from the CoScale docker registry:

    ./pull.sh

Run Coscale:

    ./run.sh


Connecting to a container
====

To get a bash shell inside a certain container you can use the connect script './connect.sh <service>', eg:

    ./connect.sh api

The connect script also has some helps to get to the log files of the services:

    ./connect.sh api log    # Shows the full log
    ./connect.sh api tail   # Tails the log
    ./connect.sh api <cmd>  # Execute <cmd> inside the container

Tearing down
====

Stop and remove all coscale containers by running

    ./stop.sh

Updating the CoScale services
====

    ./pull.sh
    ./stop.sh coscale
    ./run.sh coscale

DNS issues
====

For loadbalancing purposes the internal CoScale services also request data from api through the loadbalancer.
This only works if the API_URL is setup properly and all containers can resolve the hostname of the host.
If the containers do not pickup the correct dns configuration, dns options can be added to run.sh.
More information on the docker dns settings: https://docs.docker.com/engine/userguide/networking/default_network/configure-dns/ 

