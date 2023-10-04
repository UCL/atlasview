# Provisioning the self-hosted runner

This directory contains the scripts and configuration files to provision the self-hosted runner.

The `playbook.yml` Ansible playbook

1. Installs [Docker](https://docker.com) and its dependencies,
2. Sets up SSH keys to allow access to the [private atlasview repo](https://github.com/UCL/atlasview)
3. Sets up the necessary directory structure for `atlasview`
4. Installs a [self-hosted GitHub Actions runner](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners)
    to run the [docker-build workflow](../.github/workflows/docker-build.yml)

## Set GitHub access token

Adding the SSH keys and setting up the self-hosted GHA runner requires a GitHub personal access
token with at least the following scopes:

- `repo`
- `admin:public_key`
- `user`
- `admin:gpg_key`

First create the `.env_ansible` file by copying the template:

```sh
cp .env_ansible.example .env_ansible
```

Then, create a new [GitHub personal access token](https://docs.github.com/en/github/authenticating-to-github/creating-a-personal-access-token)
with the required scopes and add it to the `.env_ansible` file, which should now have at least the
following line:

```sh
export GITHUB_PAT=ghp_*********************
```

The `.env_ansible` file is ignored by git, so it won't be committed to the repo.

## Set up the `atlasview-data` directory and `.env` file

Before running the playbook, make sure to set up the `atlasview-data` directory and `.env` file as
explained in the [main README](../README.md#clone-and-set-up-directories).

The playbook will copy the `atlasview-data` directory `.env` file to the remote server, so any
changes will be caried over. To update the data files, you can edit or add files on your local
copy of `atlasview-data` and run the playbook again (see next section).

## Run the Ansible playbook

We provide a helper script `provision.sh`, which sources `.env_ansible` to ensure the necessary
environment variables are loaded, and then runs the Ansible playbook:

```sh
./provision.sh
```

### Seting up the `Remark42` engine

As part of the `atlasview` role, the Ansible playbook will set up the `Remark42` comment engine.

The Remark42 code is a submodule in the repository. We download the source code and patch it, ready
for Docker to build. Our patches remove the logout links, because the R Shiny app handles
credentials and login/logout.

To apply the patches manually, run the following commands:

```sh
# Set up the Remark42 engine
cd atlasview
git submodule init
git submodule update
cd remark42/remark42
git apply ../*.patch
```

## Managing hosts

The `hosts.yml` file contains the list of hosts to provision. To add a new host, edit this file with
the necessary details and run the playbook again. See the
[Ansible documentation](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html) for
more inofrmation.

## Development

We provide a `Vagrantfile` to set up a local VM for development.
You can spin up the VM and provision it with the Ansible playbook using the following commands:

```sh
vagrant up
./provision.sh --limit devel
```

**Note**: the `Vagrantfile` is configured to use an ARM-based VM, so it will only work on machines
with that architecture. If you want to use an x86 VM, you can edit the `Vagrantfile` and change the
`config.vm.box` value:

```Vagrantfile
config.vm.box = "bento/ubuntu-22.04"
```
