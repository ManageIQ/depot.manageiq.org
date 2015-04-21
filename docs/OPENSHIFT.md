# Getting set up on OpenShift

To configure a new instance of our app on OpenShift:

1. Make sure you have the [RHC CLI](https://developers.openshift.com/en/getting-started-osx.html) installed.
2. Create a new application using the Ruby on Rails 4 template in OpenShift, under the correct domain.
3. Create the application with a Postgres cartridge.
4. Add the [third-party redis cartridge](https://github.com/smarterclayton/openshift-redis-cart).
5. Add OpenShift's git repo for your new app to the existing app, and merge the two together however you're comfortable doing so.
6. While running on openshift, env variables are set with the [RHC CLI](https://developers.openshift.com/en/getting-started-overview.html). Make sure env vars are set before deploying the application.
7. When things are all merges and all tests are passing, push to the new OpenShift instance with git push <remote name> <branch name>. Openshift will build and deploy the new code, run DB migrations, etc (based on settings in the .openshift configuration directory).