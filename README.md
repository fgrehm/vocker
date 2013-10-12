# Vocker

An experimental plugin that introduces [Docker](http://docker.io) to [Vagrant](http://www.vagrantup.com/)
as a [provisioner](http://docs.vagrantup.com/v2/plugins/provisioners.html) and
as a command that allows you to interact with the guest machine Docker
installation. It can also be used for building other Vagrant plugins that
needs interaction with a Docker instance.


## Installation

Make sure you have Vagrant 1.2+ and run:

```
vagrant plugin install vocker
```


## Features

* Automatically installs Docker on guest machines
* Adds a command to interact with guest's Docker from the host machine
* Allows you to provision VMs with Docker images / containers from within your `Vagrantfile`
* Can be used to build other plugins (and I'm currently working on one :)


## Status

Early development. It can be useful for trying out Docker and its growing "ecosystem" but the feature set and configuration format might change rapidly.

Apart from that I've only used the plugin on the following Ubuntu 13.04 VMs:

* http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box
* http://bit.ly/vagrant-lxc-raring64-2013-07-12 (yes! LXC inception :)

_Please note that in order to use the plugin on [vagrant-lxc](https://github.com/fgrehm/vagrant-lxc)
containers you need some extra steps described below_


## Usage

Currently Vocker can be used in three different ways: as a provisioner, as a command and as a foundation for other Vagrant plugins.

### Provisioner

On the same spirit as the undocumented [CFEngine](https://github.com/mitchellh/vagrant/tree/master/plugins/provisioners/cfengine)
provisioner, this plugin will automatically [install](https://github.com/fgrehm/vocker/blob/master/lib/vocker/cap/debian/docker_install.rb)
Docker on Guest machines if you specify the provisioner on your `Vagrantfile`
like:

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = 'your-box'
  config.vm.provision :docker
end
```

_Please note that only Ubuntu / Debian guests are currently capable of automatic
Docker installation. For usage on other guests you'll need to manually install it
prior to use this plugin._

You can also use the provisioner block to specify images to be pulled and / or
containers to run:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provision :docker do |docker|
    # If you just want to pull in some base images
    docker.pull_images 'ubuntu', 'busybox'

    # Command + image
    docker.run 'echo ls -la --color', 'ubuntu'

    # Unique container name + other configs
    docker.run 'date', image: 'ubuntu', cmd: '/bin/sh -c "while true; date; do echo hello world; sleep 1; done"'

    # Base image (requires ENTRYPOINT / CMD) to be configured:
    #   * http://docs.docker.io/en/latest/use/builder/#entrypoint
    #   * http://docs.docker.io/en/latest/use/builder/#cmd
    docker.run 'user/mysql'

    # If you need to go deeper, you can pass in additional `docker run` arguments
    # Same as: docker run -v /host:/container -p 1234:3306 user/patched-mysql /usr/bin/mysql
    docker.run mysql: { additional_run_args: '-v /host:/container -p 1234:3306', image: 'user/patched-mysql', cmd: '/usr/bin/mysql'}
  end
end
```

The provisioner will also ensure that a single instance of the container is
running at a time and you can run `vagrant provision` as many times as you want
without leaving lots of unused containers behind. If you are interested on
understanding how it works, have a look at [_DockerClient#run_](https://github.com/fgrehm/vocker/blob/master/lib/vocker/docker_client.rb#L22)


### `vagrant docker` command

The command is basically a wrapper over `vagrant ssh -c` that allows you
to run `docker` commands on the guest VM:

```
Usage: vagrant docker [vm-name] COMMAND [ARGS]

COMMAND can be any of attach, build, commit, diff, events, export, history,
images, import, info, insert, inspect, kill, login, logs, port, top, ps,
pull, push, restart, rm, rmi, run, search, start, stop, tag, version, wait

    -h, --help                       Print this help
```


### _your-awesome-vagrant-plugin™_

In case you want to build a Vagrant plugin that needs to interact with Docker you
can add this plugin as a dependency and use [DockerClient](lib/vocker/docker_client.rb)
/ [DockerInstaller](lib/vocker/docker_installer.rb) classes. An example of usage
will be provided _"soon"_.


### Usage with [vagrant-lxc](https://github.com/fgrehm/vagrant-lxc)

If you are on a Linux machine, you can use vagrant-lxc to avoid messing up with
your working environment. While developing this plugin I was able to recreate
containers that were capable of using Docker without issues multiple times on
an up to date Ubuntu 13.04 host and guest.

In order to allow a vagrant-lxc container to boot nested Docker containers you'll
just need to `apt-get install apparmor-utils && aa-complain /usr/bin/lxc-start`
and add the code below to your Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  config.vm.provider :lxc do |lxc|
    lxc.customize 'aa_profile', 'unconfined'
  end

  config.vm.provision :shell, inline: %[
    if ! [ -f /etc/default/lxc ]; then
      cat <<STR > /etc/default/lxc
LXC_AUTO="true"
USE_LXC_BRIDGE="true"
LXC_BRIDGE="lxcbr0"
LXC_ADDR="10.0.253.1"
LXC_NETMASK="255.255.255.0"
LXC_NETWORK="10.0.253.0/24"
LXC_DHCP_RANGE="10.0.253.2,10.0.253.254"
LXC_DHCP_MAX="253"
LXC_SHUTDOWN_TIMEOUT=120
STR
    fi
  ]
end
```

The LXC networking configs are only required if you are on an Ubuntu host as
it automatically creates the `lxcbr0` bridge for you on the host machine and
if you don't do that the vagrant-lxc container will end up crashing as it
will collide with the host's `lxcbr0`.


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
