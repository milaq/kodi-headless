[![](http://kodi.wiki/images/4/43/Side-by-side-dark-transparent.png)](https://kodi.tv/)

# Introduction
A headless, dockerized Kodi instance for a shared MySQL setup to allow having a webinterface and automatic periodic library updates without the need for a player system to be permanently on.

Kodi version: `17.1 Krypton`  
Base image: `Debian Jessie`

# Prerequisites
You need to have set up library sharing via a dedicated MySQL database beforehand by reading, understanding and executing the necessary steps in the [MySQL library sharing guide](http://kodi.wiki/view/MySQL).

WARNING - as already stated in the wiki but here once again: Every Kodi "client" must run the same version of Kodi!

Best way to set up library sharing in the container is by fully configuring your shared library, its sources and scrapers via another full GUI host (preferrably your main HTPC) and setting up the Kodi headless instance afterwards.
The server needs fully configured database access and your sources (preferrably SMB or NFS) must be reachable from the headless instance. All updating, scraping and cleaning can then be handled by the headless Kodi instance on its own without further ado.

REMINDER: If you are not using TMDB/TVDB scrapers you need to take care of installing the respective plugins in the container yourself.

# Usage

Get the latest container image:
```bash
docker pull milaq/kodi-headless:latest
```

Run the container and set necessary environment variables:
```bash
docker run -d --restart=always --name kodi-server -e KODI_DBHOST=<MY_KODI_DBHOST> -e KODI_DBUSER=<MY_KODI_DBUSER> -e KODI_DBPASS=<MY_KODI_DBPASS> milaq/kodi-headless
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

* `KODI_DBHOST` - MySQL database host address (required)
* `KODI_DBUSER` - MySQL user for Kodi (required)
* `KODI_DBPASS` - MySQL password for Kodi user (required)
* `KODI_UPDATE_INTERVAL` - How often to scan for library changes on remote sources in seconds (optional, default is 300 [5 minutes])
* `KODI_CLEAN_INTERVAL` - How often to clean up the library in seconds (optional, default is 86400 [1 day])

# Credits

Thanks goes out to linuxserver.io for creating a solid base of a dockerized Kodi version to work with.  
More thanks goes to Celedhrim for creating a clean headless patch.
