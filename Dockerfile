FROM node

# install java 8
#
RUN if grep -q Debian /etc/os-release && grep -q jessie /etc/os-release; then \
    echo "deb http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && echo "deb-src http://http.us.debian.org/debian/ jessie-backports main" | sudo tee -a /etc/apt/sources.list \
    && sudo apt-get update; sudo apt-get install -y -t jessie-backports openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; elif grep -q Ubuntu /etc/os-release && grep -q Trusty /etc/os-release; then \
    echo "deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" | sudo tee -a /etc/apt/sources.list \
    && echo "deb-src http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main" |  tee -a /etc/apt/sources.list \
    &&  apt-key adv --keyserver keyserver.ubuntu.com --recv-key DA1A4A13543B466853BAF164EB9B1D8886F44E2A \
    &&  apt-get update;  apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; else \
     apt-get update;  apt-get install -y openjdk-8-jre openjdk-8-jre-headless openjdk-8-jdk openjdk-8-jdk-headless \
  ; fi


# install chrome
RUN curl --silent --show-error --location --fail --retry 3 --output /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
      && ( dpkg -i /tmp/google-chrome-stable_current_amd64.deb ||  apt-get -fy install)  \
      && rm -rf /tmp/google-chrome-stable_current_amd64.deb \
      &&  sed -i 's|HERE/chrome"|HERE/chrome" --disable-setuid-sandbox --no-sandbox|g' \
           "/opt/google/chrome/google-chrome" \
      && google-chrome --version


RUN apt-get install unzip

# Install Chrome WebDriver
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

# install libgconf-2-4 manually since chrome no longer pulls it in automatically
RUN  apt-get install -y libgconf-2-4

# start xvfb automatically
ENV DISPLAY :99
RUN printf '#!/bin/sh\nXvfb :99 -screen 0 1280x1024x24 &\nexec "$@"\n' > /tmp/entrypoint \
  && chmod +x /tmp/entrypoint \
        && mv /tmp/entrypoint /docker-entrypoint.sh

# ensure that the build agent doesn't override the entrypoint
LABEL com.codefresh.preserve-entrypoint=true

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/bin/sh"]
