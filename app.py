import os
import boto3
from flask import Flask, request, jsonify

app = Flask(__name__)

# Get table name from environment variable
#table_name = 'Candidates'
# Get table name from environment variable
table_name = os.environ.get('TC_DYNAMO_TABLE', 'Candidates')

# Create DynamoDB resource using IAM role (no explicit credentials needed)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(table_name)

# Health check endpoints (already provided)
from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/')
def root():
    """Root route - Return a welcome message or any desired content."""
    return jsonify({'message': 'Welcome to the Candidate API!'}), 200


@app.route('/gtg')
def health_check():
    """Simple health check, returns 'OK' with a 200 status code."""
    return 'HTTP 200 OK', 200

@app.route('/gtg/details')
def health_check_details():
    """Advanced health check, returns service details in JSON format."""
    details = {
        'service_name': 'Candidate API',
        'status': 'healthy',
        'database': 'DynamoDB'
    }
    return jsonify(details), 200


@app.route('/candidate/<name>', methods=['POST'])
def add_candidate(name):
    party = request.args.get('party', 'ind')
    if party not in ['ind', 'dem', 'rep']:
        return jsonify({'error': 'Invalid party'}), 400

    table.put_item(Item={'CandidateName': name, 'Party': party})
    return jsonify({'message': 'Candidate added successfully'}), 200

@app.route('/candidate/<name>')
def get_candidate(name):
    response = table.get_item(Key={'CandidateName': name})
    item = response.get('Item')
    if item:
        return jsonify(item), 200
    else:
        return jsonify({'error': 'Candidate not found'}), 404

@app.route('/candidates')
def get_all_candidates():
    response = table.scan()
    candidates = response.get('Items', [])
    return jsonify(candidates), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)