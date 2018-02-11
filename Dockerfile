FROM ubuntu:xenial

RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install curl
RUN apt-get -y install python-pip
RUN apt-get -y install libssl-dev
RUN apt-get -y install libffi-dev
RUN pip install awscli boto3 certbot
RUN apt-get -y install jq

VOLUME /app
WORKDIR /app

ENTRYPOINT ["./scripts/main.sh"]
CMD []
