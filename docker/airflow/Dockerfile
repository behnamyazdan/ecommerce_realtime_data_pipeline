FROM apache/airflow:2.7.1-python3.10
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         build-essential \
         jq \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Install Python packages required for your DAGs
RUN pip install --no-cache-dir pendulum==2.1.2 faker geopy

# Set environment variables from the .env file
ENV REDIS_HOST=${REDIS_HOST}
ENV REDIS_PASSWORD=${REDIS_PASSWORD}
ENV REDIS_PORT=${REDIS_PORT}
ENV REDIS_DB=${REDIS_DB}