# Debugging A Golang GraphQL Service Running in a Local K8s Cluster with Delve

[![asciicast](https://asciinema.org/a/325818.svg)](https://asciinema.org/a/325818)
### An asciicast of the general process

I ran into a situation today where I wanted to use [delve][1] to debug a
graphql service written in golang running in a pod in my local k8s development
cluster.

First I replaced the `CMD` line in the service's Dockerfile so the container
will start but not listen to the port that my ingress service expects to find
the service at.
```
# CMD gin -p 80 run main.go
CMD sleep 99999
```

Next I start all the services in my project with `skaffold dev`. I use [k9s][2]
to conveniently monitor my k8s cluster's services, deployments, pods, etc. I
can also attach to a running pod with one keypress. The equivalent can be done
with kubectl:
```sh
$ kubectl exec -it POD_NAME -- bash # assuming bash in path
```

Next I build with delve, set a breakpoint, and start the service
```sh
$ PORT=80 dlv debug main.go
```

[1]: https://github.com/go-delve/delve
[2]: https://github.com/derailed/k9s
