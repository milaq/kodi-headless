[![](http://kodi.wiki/images/4/43/Side-by-side-dark-transparent.png)](https://kodi.tv/)

# Introduction
A headless, dockerized Kodi instance for a shared MySQL setup to allow having a webinterface and automatic periodic library updates without the need for a player system to be permanently on.

# Tags

| Tagname              | Branch      | Kodi version | Base distro          |
|----------------------|-------------|--------------|----------------------|
| `latest`             | leia        | 18           | Debian Stretch       |
| `leia`               | leia        | 18           | Debian Stretch       |
| `krypton`            | krypton     | 17           | Debian Stretch       |

**Attention**: The Information found below may differ between branches/tags. Make sure you inspect the readme for the respective tag.

__You are currently viewing the readme for the branch: `leia`__

# Prerequisites
You need to have set up library sharing via a dedicated MySQL database beforehand by reading, understanding and executing the necessary steps in the [MySQL library sharing guide](http://kodi.wiki/view/MySQL).

WARNING - as already stated in the wiki but here once again: Every client must run the same version of Kodi!

Best way to set up library sharing in the container is by fully configuring your shared library, its sources and scrapers via another GUI host (e.g. your HTPC) and setting up the Kodi headless instance afterwards.
The server needs fully configured database access and your sources (SMB or NFS) must be reachable from the headless instance.
All updating, scraping and cleaning can then be handled automatically by the headless Kodi instance on its own.

REMINDER: If you are not using the default scrapers you need to take care of installing and enabling the respective plugins in the container yourself.

# Usage

Get the container image:
```bash
docker pull milaq/kodi-headless:leia
```

Run the container and set necessary environment variables:
```bash
docker run -d --restart=always --log-opt max-size=50M --name kodi-headless -e KODI_DBHOST=<MY_KODI_DBHOST> -e KODI_DBUSER=<MY_KODI_DBUSER> -e KODI_DBPASS=<MY_KODI_DBPASS> milaq/kodi-headless:leia
```

If you want to map the webinterface ports natively then also append:
```bash
-p 8080:8080 -p 9090:9090
```

If eventserver access is also required outside of the container:
```bash
-p 9777:9777
```

Container environment variables:

* `KODI_DBHOST` - MySQL database host address
* `KODI_DBUSER` - MySQL user for Kodi
* `KODI_DBPASS` - MySQL password for Kodi user
* `KODI_DBPORT` - MySQL remote port (default: `3306`)
* `KODI_DBPREFIX_VIDEOS` - MySQL database prefix for the video database
* `KODI_DBPREFIX_MUSIC` - MySQL database prefix for the music database
* `KODI_UPDATE_INTERVAL_ADDONS` - How often to update addons in seconds (default: 21600 [6 hours])
* `KODI_UPDATE_INTERVAL` - How often to scan for video/music library changes on remote sources in seconds (`0` to disable, default: 300 [5 minutes])
* `KODI_UPDATE_INTERVAL_VIDEOS` - How often to scan for video library changes on remote sources in seconds (`0` to disable, default: `KODI_UPDATE_INTERVAL`)
* `KODI_UPDATE_INTERVAL_MUSIC` - How often to scan for music library changes on remote sources in seconds (`0` to disable, default: `KODI_UPDATE_INTERVAL`)
* `KODI_CLEAN_INTERVAL` - How often to clean up the video/music library in seconds (requires sources.xml to be present, `0` to disable, default: disabled)
* `KODI_CLEAN_INTERVAL_VIDEOS` - How often to clean up the video library in seconds (`0` to disable, default: `KODI_CLEAN_INTERVAL`)
* `KODI_CLEAN_INTERVAL_MUSIC` - How often to clean up the music library in seconds (`0` to disable, default: `KODI_CLEAN_INTERVAL`)

Deprecated:

* `KODI_CLEAN` - Whether to clean up the library periodically [`true`/`false`] (deprecated, use `KODI_CLEAN_INTERVAL`)

_Experimental_: You may also mount your own copy of `advancedsettings.xml` if you like to. The container startup will then skip any of the database configuration variables (KODI_DB*) and just use the supplied copy.

## Automatic library cleaning

If you want to enable automatic library cleaning you HAVE to create an appropriate `sources.xml` and `passwords.xml` (or grab a copies from your HTPC)
```bash
/config/userdata/sources.xml
/config/userdata/passwords.xml
```
inside the container volume directly or reference a copy on the docker host, e.g.:
```bash
-v /path/to/sources.xml:/config/userdata/sources.xml
-v /path/to/passwords.xml:/config/userdata/passwords.xml
```
and enable library cleaning via the respective flag, e.g.:
```bash
-e KODI_CLEAN_INTERVAL=86400
```

__WARNING__: A misconfigured sources.xml or passwords.xml can lead to the Kodi instance not finding any of your media which will result in emtpying your database. Make a backup of your database and/or be double sure before enabling this feature!

__NOTE__: If you don't utilize network shares which require authentication you may also supply a skeleton `passwords.xml`:
```bash
<passwords>
</passwords>
```

# Credits

Thanks goes out to linuxserver.io for creating a solid base of a dockerized Kodi version to work with.
More thanks goes to Celedhrim for creating the initial headless patch and sinopsysHK for the new headless patch since Leia.
