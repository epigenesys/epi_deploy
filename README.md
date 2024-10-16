# epiDeploy

## Description

This gem provides a convenient interface for creating releases and deploying using Git and Capistrano.

### Branch Notes

* `main` / `master` should only contain deployable code.
* Each deployment environment has its own branch.
* Remote repository is assumed to be named 'origin'

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
$ bundle install
```

## Usage

### Initial Setup
No initial setup is required as prerequisites are checked automatically before each command is run.

### Commands

This command will bump the version in config/initializers/version.rb, create a Git tag in the format YYYYmonDD-HHMM-&lt;short_commit_hash&gt;-v&lt;version&gt; and push it to the remote repository. This can only be done on the **main** or **master** branch.

```bash
$ ed release
```

Optional flag to deploy to the given environment(s) after creating the release. Shorthand -d.

```bash
$ ed release --deploy demo:production
```

Deploy the latest release to the given environment(s).

```bash
$ ed deploy demo production
```

Optional flag to specify which tag, commit, or branch to deploy to the given environment(s). Shorthand -r. If the flag is provided without a reference you will be prompted to choose from the latest releases.

```bash
$ ed deploy demo production --ref <reference>
```

### Deploy to multiple customers

If you want to deploy to multiple customers, you can set it up as following:

1. In `config/deploy`, create one config file for the environment you want to deploy to. (e.g. `production.rb`)

  * In this file, include the setting for stage:

    ```
    set :stage, :production
    ```

    Also include any common settings across customers:

    ```
    set :branch, 'production'
    ```

2. In `config/deploy`, create one config file with the name in following format: `{stage}.{customer}.rb` (e.g. `production.epigenesys.rb`)

  * Include the following content (remember to replace the name of the stage and customer):

    ```
    load File.expand_path('../production.rb', __FILE__)
    ```

  * Also include any other customer specific settings:

    ```
    set :current_customer, 'epigenesys'
    server fetch(:server), user: fetch(:user), roles: %w{web app db}
    ```

3. Include this line in `Capfile`:

  ```
  require 'capistrano/epi_deploy'
  ```

Running `ed release -d production` will now deploy the latest release of the code to all customers.

You can also deploy to a specific customer by doing e.g. `ed release -d production.epigenesys`.

You can also deploy to all customers for a given environment by running e.g. `cap production deploy_all`.

# Moving to tags for stages

Using branches for stages, i.e. demo and production branches, can clutter up your branches screen. This can be particularly awkward when running CI and keeping track of multiple active branches. To resolve this you can optionally configure epi_deploy to use tags for this instead of branches.

Tags will be automatically created for each successful deployment with the format `environment.stage-timestamp`, for example `production.epigenesys-2024_10_03-12_20_09`, and pushed to the remote.

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
