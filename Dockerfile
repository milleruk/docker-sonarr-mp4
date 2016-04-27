FROM debian:wheezy
MAINTAINER milleruk <ben@haresign.net>
#ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables
ENV HOME /root
WORKDIR /work

RUN locale-gen en_US en_US.UTF-8

# Use baseimage-dockers init system
CMD ["/sbin/my_init"]

RUN apt-get -q update --fix-missing
RUN apt-get -qy upgrade

# Supervisor
RUN apt-get -qy install supervisor

## Dependencies
RUN apt-get -qy install python-cheetah wget git autoconf automake build-essential libass-dev libfreetype6-dev 
RUN	apt-get -qy install libgpac-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev 
RUN	apt-get -qy install libx11-dev libxext-dev libxfixes-dev pkg-config texi2html zlib1g-dev yasm libx264-dev 
Run apt-get -qy install libmp3lame-dev libopus-dev unzip
RUN apt-get -qy install mono-devel

# Install FFMPEG
## Dep. libfdk-aac
RUN	git clone git://github.com/mstorsjo/fdk-aac.git fdk-aac

WORKDIR /work/fdk-aac
RUN autoreconf -fiv 
RUN	./configure --prefix="$HOME/ffmpeg_build" --disable-shared  
RUN	make  
RUN	make install  
RUN	make distclean

## FFMPEG Source
WORKDIR /work
RUN git clone https://github.com/FFmpeg/FFmpeg ffmpeg-source

WORKDIR /work/ffmpeg-source
RUN PATH="$PATH:$HOME/bin" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig" ./configure \
	  --prefix="$HOME/ffmpeg_build" \
	  --extra-cflags="-I$HOME/ffmpeg_build/include" \ 
	  --extra-ldflags="-L$HOME/ffmpeg_build/lib" \
	  --bindir="$HOME/bin" \
	  --enable-gpl \
	  --enable-libass \ 
	  --enable-libfdk-aac \
	  --enable-libfreetype \ 
	  --enable-libmp3lame \
	  --enable-libopus \
	  --enable-libtheora \
	  --enable-libvorbis \
	  --enable-libx264 \
	  --enable-nonfree  
RUN PATH="$PATH:$HOME/bin" make  
RUN	make install  
RUN	make distclean  
RUN	hash -r

WORKDIR /work

## Python Setup Tools
RUN wget https://bootstrap.pypa.io/ez_setup.py -O - | python

# Install Sonarr
	RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections \
  && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys FDA5DFFC \
  && echo "deb http://apt.sonarr.tv/ master main" | tee -a /etc/apt/sources.list \
  && apt-get update -q \
  && apt-get install -qy nzbdrone mediainfo \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN chown -R nobody:users /opt/NzbDrone \
  ; mkdir -p /volumes/config/sonarr /volumes/completed /volumes/media \
  && chown -R nobody:users /volumes

EXPOSE 8989
EXPOSE 9898
VOLUME /volumes/config
VOLUME /volumes/completed
VOLUME /volumes/media

ADD develop/start.sh /
RUN chmod +x /start.sh

ADD develop/sonarr-update.sh /sonarr-update.sh
RUN chmod 755 /sonarr-update.sh \
  && chown nobody:users /sonarr-update.sh

USER nobody
WORKDIR /opt/NzbDrone

# Install Couch Potato
RUN git clone https://github.com/RuudBurger/CouchPotatoServer.git couch-potato

## MP4 Automator
RUN git clone git://github.com/mdhiggins/sickbeard_mp4_automator.git mp4_automator
COPY autoProcess.ini /work/mp4_automator/autoProcess.ini

# Install Configs
RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /work/supervisord.conf

EXPOSE 8989
EXPOSE 5050

VOLUME ["/config", "/storage", "/incoming"]

CMD [ "-c", "/work/supervisord.conf"]
ENTRYPOINT ["/usr/bin/supervisord"]
