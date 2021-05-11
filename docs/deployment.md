# Deployment

Options for deployment:

## Heroku

[Heroku](#) provides a very convenient way to deploy the application.

The free tier is slow, but a minimal production configuration could be:

- App
- Postgres
- Redis

Which is ~$90pm, and requires no server management.

## Storage

For remote deployments [AWS S3 storage](#) is strongly recommended. Create a
bucket per environment. For example:

- `csvspace-production`
- `csvspace-staging`

Ensure no public access is allowed. Add a policy to each bucket:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "bucket_access",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:user/csvspace"
            },
            "Action": [
                "s3:GetBucketLocation",
                "s3:ListBucket"
            ],
            "Resource": "arn:aws:s3:::csvspace-${environment}"
        },
        {
            "Sid": "bucket_actions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${account_id}:user/csvspace"
            },
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::csvspace-${environment}/*"
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
