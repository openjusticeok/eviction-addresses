import json
import urllib.request
import base64

def get_document(event, context):
    # Parse the event JSON to get the link and ID
    body = json.loads(event.get('body', '{}'))
    id = body.get('id')
    link = body.get('link')
    if not link or not id:
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid request: Could not find either or both of "id" and "link" in body')
        }

    # Download the document from OSCN
    headers = {'User-Agent': '1ecbd577-793f-4a38-b82f-e361ed335168'}
    req = urllib.request.Request(link, headers=headers)

    try:
        response = urllib.request.urlopen(req)
    except urllib.error.HTTPError as e:
        return {
            'statusCode': 500,
            'body': 'Bad response from OSCN: {}'.format(str(e))
        }

    # Check if the content type is PDF
    content_type = response.info().get('Content-Type', '')
    if 'application/pdf' not in content_type:
        return {
            'statusCode': 500,
            'body': 'Bad content type from OSCN'
        }

    # Verify the content length
    expected_size = int(response.info().get('Content-Length', '0'))
    document = response.read()
    actual_size = len(document)
    if expected_size != actual_size:
        return {
            'statusCode': 500,
            'body': 'Content was corrupted during download'
        }

    # Convert the document to base64
    base64_document = base64.b64encode(document).decode('utf-8')

    # Return the document URL and other metadata
    return {
        'statusCode': 200,
        'body': json.dumps({
            'id': id,
            'document': base64_document,
            'contentType': 'application/pdf',
            'contentDisposition': 'attachment; filename=document.pdf'
        })
    }

