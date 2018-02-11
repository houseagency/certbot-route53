snyltrecept
===========

This script helps create [Let's Encrypt](https://letsencrypt.org/) certificates
by validating through [AWS Route53](https://aws.amazon.com/route53/).

### Features

* Will use a TXT record on [AWS Route53](https://aws.amazon.com/route53/)
  for Letsencrypt validation.
* Will only renew your certs if they are due for renewal, so you can run the
  script in a daily cronjob.
* Handles multiple certs for domains on multiple AWS accounts.
* Dockerized.

Dependencies
------------

* Your domain must use [AWS Route53](https://aws.amazon.com/route53/) for it's
  domain name servers. (You don't have to buy your domains from Amazon, tho.)
* [Docker](https://www.docker.com/) must be installed.

Usage
-----

### 1.

Create a `config.json` file from this template:

    {
      "myapp": {
        "domains": [
          "example.org",
          "example.net"
        ],
        "email": "johndoe@my-email-provider.com",
        "route53_credentials": {
          "aws_key_id": "AKIFDE3TJFEWBVKFDSE",
          "aws_sekret_key": "8+C7z6A37sMTFABG3jMVsm9epO2JdslhQ4MeDEjM"
        }
      },
      "catpicssite": {
        "domains": [
          "example.com",
          "www.example.com",
          "api.example.com"
        ],
        "email": "meow@example.com",
        "route53_credentials": {
          "aws_key_id": "AKIFDE3TJFEWBVKFDSE",
          "aws_sekret_key": "8+C7z6A37sMTFABG3jMVsm9epO2JdslhQ4MeDEjM"
        }
      }
    }
    

### 2.

Run Snyltrecept (and wait patiently).

    ./snyltrecept.sh

### 3.

Find your new certificate(s) in the `.certbot` directory.

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
                "route53domains:*"
            ],
            "Resource": "*"
        }
    ]
}
```

You should limit your policy to only the resources you actually need.

