import boto3
from PIL import Image
import os
import io

# Initialize S3 client
s3_client = boto3.client('s3')

# Define the destination bucket
DESTINATION_BUCKET = 'your-blog-public-assets'  # <-- CHANGE THIS


def lambda_handler(event, context):
    # 1. Get data from the event that triggered Lambda
    record = event['Records'][0]
    source_bucket = record['s3']['bucket']['name']
    source_key = record['s3']['object']['key']  # File name (e.g., 'posts/image.jpg')

    # Define the desired target width for the image
    target_width = 1200

    # Prevent infinite loops (if the Lambda triggers itself)
    if source_bucket == DESTINATION_BUCKET:
        print("Ignoring event from destination bucket. End.")
        return

    print(f"Starting processing for {source_key} from bucket {source_bucket}")

    try:
        # 2. Download the image from S3 to Lambda's temporary memory
        download_path = f'/tmp/{os.path.basename(source_key)}'

        print(f"Downloading file...")
        s3_client.download_file(source_bucket, source_key, download_path)

        # 3. Process the image with Pillow
        print(f"Resizing image...")
        with Image.open(download_path) as image:
            # Maintain aspect ratio
            width, height = image.size
            if width > target_width:
                ratio = target_width / float(width)
                target_height = int(float(height) * float(ratio))
                image = image.resize((target_width, target_height), Image.Resampling.LANCZOS)

            # Save the resized image to an in-memory buffer
            in_mem_file = io.BytesIO()

            file_format = image.format if image.format else 'JPEG'
            image.save(in_mem_file, format=file_format, quality=85)  # 'quality=85' optimizes size
            in_mem_file.seek(0)  # Rewind the buffer

        # 4. Upload the new image to the destination bucket
        destination_key = source_key

        print(f"Uploading optimized file to {DESTINATION_BUCKET}/{destination_key}")
        s3_client.upload_fileobj(
            in_mem_file,
            DESTINATION_BUCKET,
            destination_key,
            ExtraArgs={
                'ACL': 'public-read',  # Make the image publicly accessible
                'ContentType': f'image/{file_format.lower()}'  # Set the content type
            }
        )

        print("Process completed successfully.")
        return {'status': 200, 'message': 'Image processed successfully.'}

    except Exception as e:
        print(f"Error processing image: {e}")
        raise e