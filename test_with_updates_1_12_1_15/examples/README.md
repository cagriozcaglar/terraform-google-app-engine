# Complete App Engine Standard Example

This example demonstrates how to use the App Engine module to create a comprehensive setup.

It performs the following actions:
1.  Creates a GCS bucket to stage the application source code.
2.  Packages a local Python "Hello World" application into a zip file and uploads it to the bucket.
3.  Instantiates the root module to create an App Engine application.
4.  Deploys two services:
    - A `default` service with `automatic_scaling` and a traffic split.
    - An `api` service with `basic_scaling`.
5.  Maps a custom domain `www.<your-domain.com>` to the application.

## How to use this example

### Prerequisites

1.  **Source Code**: Create a directory named `app` in the same folder as these Terraform files. Inside the `app` directory, create the following two files:

    *   `app/main.py`:
