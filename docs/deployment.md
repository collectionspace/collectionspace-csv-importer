# Deployment

Options for deployment:

## Heroku

[Heroku](#) provides a very convenient way to deploy the application.

The free tier is slow, but a minimal production configuration could be:

- App
- Postgres
- Redis

Which is ~$90pm, and requires no server management.

__Steps:__

Install Heroku CLI, login and create the app:

```bash
# STAGING (cheap tier only ~$14pm, or free for personal accounts)
heroku create --team $team --remote staging
heroku apps --team collectionspace # to get $app
heroku addons:create heroku-postgresql:hobby-dev --version 12 --remote staging -a $app
heroku addons:create heroku-redis:hobby-dev --version 6 --remote staging -a $app

# PROD (app[25], db[50], redis[15] ~$90pm)
heroku create --team $team --remote production
heroku apps --team collectionspace # to get $app
heroku addons:create heroku-postgresql:standard-0 --version 12 --remote production -a $app
heroku addons:create heroku-redis:premium-0 --version 6 --remote production -a $app
```

Add the environment variables not set by Heroku:

```bash
# STAGING
heroku config:set VAR=VALUE --remote staging -a $app

# PRODUCTION
heroku config:set VAR=VALUE --remote production -a $app
```

Before moving on check that the infrastructure has been created.

Deploy:

```bash
git push staging $branch
git push production $branch
```

For initial setup after the first Heroku push:

```bash
heroku rake db:seed --remote staging -a $app
heroku ps:scale web=1 worker=1 --remote staging -a $app

heroku rake db:seed --remote production -a $app
heroku ps:type standard-1x --remote production -a $app
heroku ps:scale web=1 worker=1 --remote production -a $app
```

__DNS:__

```
heroku certs:auto:enable --remote staging
heroku certs:auto:enable --remote production

heroku domains:add importerdev.collectionspace.org --remote staging
heroku domains:add importer.collectionspace.org --remote production
```

__Storage:__

For remote deployments [AWS S3 storage](#) is strongly recommended. Create a
bucket per environment. For example:

- `collectionspace-csv-importer-production`
- `collectionspace-csv-importer-staging`

Ensure no public access is allowed. Add a policy to each bucket:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "bucket_access",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:user/collectionspace-csv-importer"
            },
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::collectionspace-csv-importer-${environment}"
        },
        {
            "Sid": "bucket_actions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:user/collectionspace-csv-importer"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::collectionspace-csv-importer-${environment}/*"
        }
    ]
}
```

Create the IAM user and use the generated API credentials to configure the `AWS_*`
environment variables:

- AWS_ACCESS_KEY_ID
- AWS_BUCKET
- AWS_REGION
- AWS_SECRET_ACCESS_KEY

Optional: store the key and secret using [SSM](#).

## Commands

### Adding remotes to pre-existing apps

After a fresh download / clone:

```bash
heroku git:remote -a $app -r staging
heroku git:remote -a $app -r production
git remote -v # confirm remote setup as expected
```

### Accessing the Rails console

```bash
heroku run rails console --remote staging
heroku run rails console --remote production
```

### Connecting to a database

```bash
sudo apt-get install postgresql-client-common postgresql-client-12
heroku pg:psql --remote staging
```

### Resetting the staging database

```bash
heroku pg:reset DATABASE --remote staging --confirm $app
echo "FLUSHALL" | heroku redis:cli --remote staging --confirm $app
git push -f staging $branch:master
heroku run rake db:seed --remote staging
```

### Restoring a database locally

```bash
heroku apps --team collectionspace
PGHOST=127.0.0.1 PGUSER=postgres PGPASSWORD=postgres dropdb importer_development
PGHOST=127.0.0.1 PGUSER=postgres PGPASSWORD=postgres heroku pg:pull \
    DATABASE_URL importer_development -a $app
```
