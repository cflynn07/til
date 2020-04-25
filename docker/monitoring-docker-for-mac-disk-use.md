# Monitoring Docker for Mac Disk Usage

I ran into an problem while trying to deploy a project onto my local K8s
cluster (included with Docker for Mac) with skaffold. The node was stuck in a
"pending" state. turns out the problem was my system had filled the allocated
disk space.

### Using kubectl to inspect the node (my laptop)
`kubectl` reveals the node had a disk-pressure taint, time clean some stuff up.
```
$ kubectl describe node docker-desktop
Name:               docker-desktop
...
Taints:             node.kubernetes.io/disk-pressure:NoSchedule
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Sat, 25 Apr 2020 13:40:32 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     True    Sat, 25 Apr 2020 13:40:32 +0800   Sat, 25 Apr 2020 13:39:31 +0800   KubeletHasDiskPressure       kubelet has disk pressure
  PIDPressure      False   Sat, 25 Apr 2020 13:40:32 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Sat, 25 Apr 2020 13:40:32 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletReady                 kubelet is posting ready status
...
```

### Checking the size of the disk image file on my file system
`du` reveals the image is pretty much at it's maximum allocatable size of 60G
```
$ du -d 0 -h /Users/casey/Library/Containers/com.docker.docker/Data/vms/0
 59G	/Users/casey/Library/Containers/com.docker.docker/Data/vms/0
```

### Cleaning up with `docker system prune`
5 minutes later and I've freed up plenty of disk to keep working
```
$ du -d 0 -h /Users/casey/Library/Containers/com.docker.docker/Data/vms/0
 18G	/Users/casey/Library/Containers/com.docker.docker/Data/vms/0
```

### Inspecting the node (my laptop) again
`kubectl` reveals the `DiskPressure` condition has changed to `false`
```
Name:               docker-desktop
...
Taints:             <none>
Unschedulable:      false
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Sat, 25 Apr 2020 14:14:48 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Sat, 25 Apr 2020 14:14:48 +0800   Sat, 25 Apr 2020 13:57:05 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Sat, 25 Apr 2020 14:14:48 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Sat, 25 Apr 2020 14:14:48 +0800   Fri, 24 Apr 2020 07:17:26 +0800   KubeletReady                 kubelet is posting ready status
...
Events:
  Type     Reason                   Age                   From                        Message
  ----     ------                   ----                  ----                        -------
...
  Normal   NodeHasNoDiskPressure    18m (x31 over 36m)    kubelet, docker-desktop     Node docker-desktop status is now: NodeHasNoDiskPressure
```
