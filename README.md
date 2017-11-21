# John the Ripper Docker

This Docker image contains John the Ripper compiled with support for OpenCL.
Due to the OpenCL Support you may run it with [nvidia-docker](https://github.com/NVIDIA/nvidia-docker).

The prebuilt image is available at [Docker Hub](https://hub.docker.com/r/knsit/johntheripper/).

## Starting the container

The best way to run the cracker is like this:

```bash
nvidia-docker run --rm -ti -v /tmp/in:/in -v /tmp/out:/home/john knsit/johntheripper /in/crack.sh
```

* mount an `in` volume to pass in the password file, optionally a wordlist and a script to run
* mount an `out` volume to the home-folder to get the results
* pass the path to the mounted script as param to the entrypoint

## Script

The script to run JtR is a little bit hacky.
It's necessary (for some reason) to copy the `john.conf` file from `/etc/john` to the hidden `.john` folder in the home directory of the current user.
Otherwise JtR won't run with an error

```
fopen: $JOHN/john.conf: No such file or directory
```

Sample script:

```bash
#!/bin/bash
[[ -d ~/.john ]] || mkdir ~/.john
[[ -f ~/.john/john.conf ]] || cp /etc/john/john.conf ~/.john/
john --format=sha512crypt-opencl --wordlist=/in/wordlist /in/intranet-unshadowed
```