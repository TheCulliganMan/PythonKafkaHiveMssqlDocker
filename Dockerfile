FROM python:3.6.4

# App Setup
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

# Env Setup
ENV PYTHONPATH=$PYTHONPATH:/usr/src/app
ENV PYTHONPATH=/usr/src/app/src:$PYTHONPATH
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# DEBIAN DEPS
RUN apt-get update && apt-get install -y libevent-dev python-dev build-essential \
    libgdal-dev python-gdal software-properties-common build-essential freetds-dev \
    libsasl2-dev gcc sasl2-bin libsasl2-2 libsasl2-dev libsasl2-modules  freetds-common \
    freetds-bin freetds-dev libprotobuf-dev libprotoc-dev wget

# ODBC INSTALL.  (apt-get and system utilities + adding custom MS repository + install SQL Server drivers and tools)
RUN apt-get update && apt-get install -y \
    curl apt-transport-https debconf-utils \
    && rm -rf /var/lib/apt/lists/*
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/debian/8/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 unixodbc-dev

# PYTHON GDAL + SHAPELY INSTALL
ENV CPLUS_INCLUDE_PATH /usr/include/gdal
ENV C_INCLUDE_PATH /usr/include/gdal
# Python Package installs to match gdal version
RUN pip install GDAL==$(gdal-config --version | awk -F'[.]' '{print $1"."$2}')
RUN pip install shapely --no-binary shapely

# Install the Confluent OSS Platform, librdkafka and the confluent-kafka Python package
RUN wget -qO - http://packages.confluent.io/deb/3.3/archive.key | apt-key add -
RUN add-apt-repository "deb [arch=amd64] http://packages.confluent.io/deb/3.3 stable main"
RUN apt-get update && apt-get install -y confluent-platform-2.11 librdkafka-dev

# Other Python Requirements
COPY src/requirements.txt .
RUN pip install -r requirements.txt
