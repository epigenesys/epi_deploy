# EpiDeploy

This gem provides wrappers for common tasks in the epiGenesys git branching / deployment strategy.

## Installation

Add this line to your application's Gemfile:

    gem 'epi_deploy', github: 'epigenesys/epi_deploy'

And then execute:

    $ bundle


## Usage

####rake git:setup
Run this task at the start to check your repository is set up correctly and create the necessary branches if they don’t exist.

####rake git:demo:release || rake git:qa:release
When you’re ready to deploy a release to environment from master run this task. You will be asked if you want to create a new tag or use an existing one. The major version number will be bumped, the commit tagged and merged into the branch (and pushed to origin). Optional deployment.

####rake git:production:release
When you’re ready to deploy to production run this task. You will be prompted to choose which version (tag) to merge into the production branch and optionally deploy.

####rake git:start_hotfix_for[<demo|production>]
This will create a hotfix branch from the live branch specified and bump the version ready for you to implement the fix.

####rake git:apply_hotfix
This will merge your hotfix into the appropriate live branch and optionally deploy. You should then manually merge the hotfix into deploy and master if necessary and delete the hotfix branch. 
Note: you must be in the hotfix branch you wish to apply before running this task.
