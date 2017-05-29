snyltrecept
===========

This script helps create [Let's Encrypt](https://letsencrypt.org/) certificates
by validating through [AWS Route53](https://aws.amazon.com/route53/).

### Features

* Will use a TXT record on [AWS Route53](https://aws.amazon.com/route53/)
  for Letsencrypt validation.
* Will only renew your certs if they are due for renewal, so you can run the
  script in a daily cronjob.
* Can upload certs to Amazon S3.
* Dockerized.

Dependencies
------------

* Your domain must use [AWS Route53](https://aws.amazon.com/route53/) for it's
  domain name servers. (You don't have to buy your domains from Amazon, tho.)
* The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables
  must be set with proper [IAM](https://aws.amazon.com/iam/) profile
  credentials.
* [Docker](https://www.docker.com/) must be installed.

Usage
-----

### 1.

Run the script with your domain and e-mail address as first and second
parameters:

    ./snyltrecept.sh mydomain.example.com johndoe@example.org

### 2.

Wait patiently.

### 3.

Find your new certificate(s) in the `letsencrypt/live` directory.

If you already had a valid certificate in `letsencrypt/live`, and it is not yet
due for renewal, no action will be taken. (So you can run this script on a
cronjob.)

Upload certs to AWS S3
----------------------

Add a third parameter to upload certs to AWS S3:

    ./snyltrecept.sh mydomain.example.com johndoe@example.org bucket/certs

That will create (or update) those files in your S3 bucket:

* `certs/mydomain.example.com/certs.pem`
* `certs/mydomain.example.com/chain.pem`
* `certs/mydomain.example.com/fullchain.pem`
* `certs/mydomain.example.com/privkey.pem`

IAM Policy
----------

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "route53:*",
                "route53domains:*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
```

You should limit your policy to only the resources you actually need. If you
do not want to upload your certs to S3, then remove the `"s3:*"` action.

