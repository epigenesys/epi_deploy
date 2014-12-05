# epiDeploy

## Description

This gem provides a convenient interface for creating releases and deploying using Git and Capistrano. 

### Branch Notes

* `master` should only contain deployable code.
* Each deployment environment has its own branch.
* Remote repository is assumed to be named 'origin'

## Installation

Add this line to your application's Gemfile:

    gem 'epi_deploy', github: 'epigenesys/epi_deploy'

And then execute:

    $ bundle install


## Usage

### Initial Setup
No initial setup is required as prerequisites are checked automatically before each command is run.

### Commands

This command will bump the version in config/initializers/version.rb, create a Git tag in the format YYYYmonDD-HHMM-&lt;short_commit_hash&gt;-v&lt;version&gt; and push it to the remote repository. This can only be done on the **master** branch.

```bash
$ ed release
```

Optional flag to deploy to the given environment(s) after creating the release. Shorthand -d.

```bash
$ ed release --deploy demo:production
```

Deploy the latest release to the given environment(s).

```bash
$ ed deploy demo:production
```

Optional flag to specify which tag, commit, or branch to deploy to the given environment(s). Shorthand -r. If the flag is provided without a reference you will be prompted to choose from the latest releases.

```bash
$ ed deploy demo:production --ref <reference>
```