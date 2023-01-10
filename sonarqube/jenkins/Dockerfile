FROM python:alpine3.17

WORKDIR /usr/src

# ① Install some dependencies
RUN apt-get update \
    && apt-get install -y libsasl2-dev python-dev libldap2-dev libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# ② Copy the setup script
COPY setup.py .

# ③ Make sure some dummy files are present for the setup script
RUN touch README.md
RUN mkdir scripts && touch scripts/ghcli

# ④ Install the project dependencies to run the tests
RUN python -m pip install -e ".[test]"

# ⑤ Copy the source code
COPY . .

# ⑥ Volume when container is used as volume container
VOLUME /usr/src
