# epiDeploy

## Description

This gem provides a convenient interface for creating releases and deploying using Git and Capistrano.

### Branch Notes

* `main` / `master` should only contain deployable code.
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
