# epiDeploy

## Description

This gem provides a convenient interface for creating releases and deploying using Git and Capistrano.

### Branch Notes

* You can only create a release from `main` / `master`.
* The remote repository is assumed to be named `origin`.

## Installation

At the top of your application's `Gemfile` add this line if it does not already exist:

```sh
git_source(:github) { |repo| "https://github.com/#{repo}.git" }
```

Add this line to your application's Gemfile:

```rb
gem 'epi_deploy', github: 'epigenesys/epi_deploy'
```

And then execute:

```sh
bundle install
```

## Usage

### Initial Setup

No initial setup is required as prerequisites are checked automatically before each command is run.

### Creating a release

**Creating commitless releases is now the default behaviour, and in a future version this will be the only way to make releases. It is recommended that you migrate your workflow as soon as possible to commitless releases.**

Releasing creates a Git tag in the format `YYYYmonDD-HHMM-<short_commit_hash>-v<version>`, where `<short_commit_hash>` is the first seven characters of the hash of the latest commit on the main branch, and `<version>` is one more than the `<version>` in the previous release tag. The tag is pushed to the remote repository. Releasing can only be done on the `main` or `master` branch.

```sh
ed release
```

You can revert back to creating commitful releases, by setting `EpiDeploy.create_release_commit` to `true` in your `config/epi_deploy.rb`. This raises a deprecation warning each time a release is made.

```rb
# config/epi_deploy.rb
EpiDeploy.create_release_commit = true
```

Creating commitful releases sets or bumps the version in `config/initializers/version.rb`, setting an `APP_VERSION` constant. This is read instead of the latest release tag when determining what `<version>` to use.

```rb
# config/initializers/version.rb
APP_VERSION = '2'
```

The change is committed, and pushed up. The `<short_commit_hash>` is the hash of the parent of the release commit, **not** the release commit itself.

By default, creating a release is prevented if your working tree or index is dirty, i.e. you have changes to files that are already tracked by Git, or you have staged any changes. To ignore this, you can pass the `--allow-dirty` flag when releasing

```rb
ed release --allow-dirty
```

When using commitful releases and passing `--allow-dirty` epi_deploy will first call `git reset` to unstage any staged changes before to ensure that only the change to the `version.rb` is committed.

### Deploying a release

The simplest way to deploy is at the same time as creating a commit, by passing the `--deploy` or `-d` flag with the given environment(s) after creating the release. Separate each environment with a colon.

```sh
ed release --deploy demo:production
```

Alternatively, you can release and deploy separately, by using the `deploy` command to deploy. This deploys the latest release to the given environment(s) by default. Separate each environment with a space.

```sh
ed release
ed deploy demo production
```

You can also pass the `--ref` or `-r` flag to specify which tag, commit, or branch to deploy to the given environment(s). If the flag is provided without a reference you will be prompted to choose from the latest releases.

```sh
ed deploy demo production --ref <reference>
```

### Deploy to multiple customers

If you want to deploy to multiple customers, you can set it up as following:

1. In `config/deploy`, create one config file for the environment you want to deploy to. (e.g. `production.rb`)

   In this file, include the setting for stage:

   ```rb
   set :stage, :production
   ```

   Also include any common settings across customers:

   ```rb
   set :branch, 'production'
   ```

1. In `config/deploy`, create one config file with the name in following format: `{stage}.{customer}.rb` (e.g. `production.epigenesys.rb`)

   Include the following content (remember to replace the name of the stage and customer):

   ```rb
   load File.expand_path('../production.rb', __FILE__)
   ```

   Also include any other customer specific settings:

   ```rb
   set :current_customer, 'epigenesys'
   server fetch(:server), user: fetch(:user), roles: %w{web app db}
   ```

1. Include this line in `Capfile`:

   ```rb
   require 'capistrano/epi_deploy'
   ```

Running `ed release -d production` will now deploy the latest release of the code to all customers.

You can also deploy to a specific customer by doing e.g. `ed release -d production.epigenesys`.

You can also deploy to all customers for a given environment by running e.g. `cap production deploy_all`.

### Moving to branchless deployments

**Branchless deployment will be the only option in a future version, and branchful deployments will be removed.**

Using branches for stages, i.e. demo and production branches, can clutter up your branches screen. This can be particularly awkward when running CI and keeping track of multiple active branches. To resolve this you can configure `epi_deploy` to use tags for this instead of branches.

Tags will be automatically created for each successful deployment with the format `deploy-<environment>.<stage>-<timestamp>`, for example `deploy-production.epigenesys-2024_10_03-12_20_09`, and pushed to the remote.

1. Change the line in your Gemfile to this, to ensure that you have version 2.3 or greater.

   ```rb
   gem 'epi_deploy', '>= 2.3', github: 'epigenesys/epi_deploy'
   ```

1. Update epi_deploy in your application's gems

   ```sh
   bundle update epi_deploy
   ```

1. Create a file called `config/epi_deploy.rb` if it does not already exist, with this configuration option:

   ```rb
   EpiDeploy.use_timestamped_deploy_tags = true
   ```

1. If it hasn't be added already, add this line to `Capfile`

   ```rb
   require 'capistrano/epi_deploy'
   ```

1. Commit and push your changes, then deploy to a demo site to test it is working correctly.

If you've previously used the `use_tags_for_deploy` configuration option, then this has now been removed since v2.3. If you upgrade to v2.3, then you should remove the old deployment tags manually from your local repo and remotely by doing, e.g.

```sh
git tag --delete production demo
git push origin --delete production demo
```

and remove the old `EpiDeploy.use_tags_for_deploy` from your application's `config/epi_deploy.rb` file.

You can then use the deployment branches (the default behaviour) or the new tags for deployment.
