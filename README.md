DockerApiProxy
==============

Proxies Docker API requests across multiple docker hosts.

DockerApiProxy has a few environment variables you can set:
`DOCKER_PROXY_INTERFACE`
`DOCKER_PROXY_PORT`

```
DOCKER_PROXY_INTERFACE=192.168.4.4 iex -S mix
```

### Creating Image (Existing)
You can create an image from local repo or remote
```bash
curl -H 'content-type: application/json' -XPOST '127.0.0.1:4000/images' -d '"fromImage": "127.0.0.1:5000/redis:latest"'
```

To start newly created image
Example params:
      `%{ "HostName": "", "Image": "redis", "ExposedPorts": %{ "22/tcp": %{}, "6379/tcp": %{} },
         "PortBindings": %{ "22/tcp": [%{ "HostIp": "192.168.4.4" }], "6379/tcp": [%{ "HostIp": "192.168.4.4" }]}}`

```bash
curl -H 'content-type: application/json' -XPOST '127.0.0.1:4000/containers' -d@json_file
```


#### TODO

- [ ] Fix `/images/build` with file (not working)
