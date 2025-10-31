# Implementing-Serverless-Automation-with-AWS-Lambda
Serverless Automation Implementation using AWS Lambda
Base Project (Fictional): We have a blog where the administrator uploads post images to an S3 bucket.

The Problem: The images are too large (e.g., 5MB), which slows down the website.

The Solution (AWS Service): Use AWS Lambda to automatically resize any uploaded image to a web-friendly size (e.g., 1200px wide) and save it to a different bucket, ready for use on the website.
Admin ➡️ Upload Large Image ➡️ S3 Bucket "original-uploads"

[AUTOMATIC TRIGGER]

AWS Lambda ➡️ (Fetches the image, resizes)

Lambda ➡️ Saves Optimized Image ➡️ S3 Bucket "public-assets"

Blog ➡️ (Loads the optimized image from public-assets)
aws_project/
├── s3/
│   ├── source_bucket/              # Where original uploads would go
│   └── destination_bucket/         # Where resized images will be saved
├── iam_role/                       # Documentation/metadata for the Role
│   └── LambdaS3ResizeRole.txt
├── lambda_function/
│   └── my-image-processor.py       # Lambda function code
└── lambda_layer/
    └── python/
        └── lib/
            └── python3.11/
                └── site-packages/  # Where Pillow will be installed
