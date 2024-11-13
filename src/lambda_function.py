import uuid
import boto3
import json
import os
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb', region_name=os.environ['REGION_US_EAST_1'])
table = dynamodb.Table(os.environ['TABLE_NAME'])


def lambda_handler(event, context):
    http_method = event.get('httpMethod', '')
    
    if http_method == 'GET':
        return handle_get_request()
    elif http_method == 'POST':
        return handle_post_request(event)
    else:
        return response_api(405, {'message': 'Method Not Allowed'})


def handle_get_request():
    try:
        response = table.scan()
        data = response.get('Items', [])
        
        while 'LastEvaluatedKey' in response:
            response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
            data.extend(response.get('Items', []))
            
        filtered_data = [{k: v for k, v in item.items() if k != 'studentid'} for item in data]
        return response_api(200, filtered_data)
    
    except ClientError as e:
        return handle_error(e)


def handle_post_request(event):
    student_id = str(uuid.uuid4())
    
    if not event.get("body"):
        return response_api(400, "Error: Request body not found.")
    
    try:
        body = json.loads(event["body"])
        name = body.get("name")
        student_class = body.get("student_class")
        age = body.get("age")
        
        table.put_item(
            Item={
                'studentid': student_id,
                'name': name,
                'student_class': student_class,
                'age': age
            }
        )
        return response_api(200, "Success")
    
    except json.JSONDecodeError:
        return response_api(400, "Error: Invalid JSON.")
    except ClientError as e:
        return handle_error(e)


def response_api(status_code, body):
    return {
        'statusCode': status_code,
        'body': json.dumps(body),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        }
    }


def handle_error(error):
    print("Error:", error)
    return response_api(500, {'Error:': str(error)})
