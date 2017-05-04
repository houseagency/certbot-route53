FROM ubuntu:xenial

RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y install curl
RUN apt-get -y install python-pip
RUN apt-get -y install libssl-dev
RUN apt-get -y install libffi-dev
RUN pip install awscli boto3 certbot

VOLUME /app
WORKDIR /app

CMD ["./certbot-route53.sh"]
