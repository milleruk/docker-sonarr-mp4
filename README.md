# docker-sonarr-mp4


## Plex Updating

## Couch Updating

## Sonarr Info

### Ports
- **TCP 8989** - Web Interface

### Volumes
- **/volumes/config** - Sonarr configuration data
- **/volumes/completed** - Completed downloads from download client
- **/volumes/media** - Sonarr media folder

To update successfully, you must configure Sonarr to use the update script in ``/sonarr-update.sh``. This is configured under Settings > (show advanced) > General > Updates > change Mechanism to Script.

After updating, the update script will stop the container. If the container was run with `--restart always`, docker will automatically restart Sonarr.