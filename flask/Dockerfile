FROM python:2.7
WORKDIR /home/site/wwwroot
ADD . /home/site/wwwroot/

RUN pip install --upgrade pip
RUN pip install flask gunicorn
RUN pip install --no-cache-dir -r requirements.txt
RUN python db.py
RUN python tests.py

# ssh
ENV SSH_PASSWD "root:Docker!"
RUN apt-get update \
        && apt-get install -y --no-install-recommends dialog \
        && apt-get update \
	&& apt-get install -y --no-install-recommends openssh-server \
	&& echo "$SSH_PASSWD" | chpasswd 

COPY sshd_config /etc/ssh/
	
EXPOSE 80 2222

# start flask app using Gunicorn
CMD service ssh start && gunicorn -w 4 -b :80 runserver:app