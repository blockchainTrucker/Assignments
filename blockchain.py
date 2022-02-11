import hashlib
import json
from operator import index
from time import time
from flask import Flask, jsonify, request
from uuid import uuid4
from urllib.parse import urlparse
import requests

class Blockchain(object):
    def __init__(self):
        self.chain = []
        self.pending_transactions = []
        self.new_block(previous_hash = '1', proof = 100)
        self.nodes = set()

    def new_block(self, proof, previous_hash = None):
        block = {
            'index': len(self.chain)+1,
            'timestamp': time(),
            'transactions': self.pending_transactions,
            'proof': proof,
            'previous_hash': previous_hash or self.hash(self.chain[-1])            
        }
        self.pending_transactions = []
        self.chain.append(block)
        return block

    def new_transaction(self, sender, recipient, amount):
        self.pending_transactions.append({
            "sender": sender,
            "recipient": recipient,
            "amount": amount
        })
        
        return self.last_block['index'] + 1
    
    def register_node(self, address):
        parsed_url = urlparse(address)
        self.nodes.add(parsed_url.netloc)
       
    def valid_chain(self, chain):
        last_block = chain[0]
        current_index = 1
        
        while current_index < len(chain):
            block = chain[current_index]
            print(last_block)
            print(block)
            print("\n--------\n")

            if block["previous_hash"] != self.hash(last_block):
                print("Previous hash does not match")
                return False
            
            if not self.valid_proof(block):
                print("Block proof of work is invalid")
                return False
            
            last_block = block
            current_index += 1
        
        return True
    
    def resolve_conflict(self):
        neighbors = self.nodes
        new_chain = None
        max_length = len(self.chain)
        for node in neighbors:
            response = request.get(f'http://{node}/chain')
            if response.status_code == 200:
                length = response.json()['length']
                chain = response.json()['chain']
                if length > max_length and self.valid_proof(chain):
                    max_length = length
                    new_chain = chain
        if new_chain:
            self.chain = new_chain
            return True
        
        return False
            
    @staticmethod
    def hash(block):
        block_string = json.dumps(block, sort_keys = True).encode()
        return hashlib.sha256(block_string).hexdigest()
    
    @property
    def last_block(self):
        return self.chain[-1]

    @staticmethod
    def proof_of_work(block):
        while not Blockchain.valid_proof(block):
            block["proof"] += 1

    @staticmethod
    def valid_proof(block):
        return Blockchain.hash(block)[:4] == "0000"

app = Flask(__name__)
node_identifier = str(uuid4()).replace('-', '')
blockchain = Blockchain()

@app.route('/mine', methods = ["GET"])
def mine():
    blockchain.new_transaction(
        sender = "0",
        recipient = node_identifier,
        amount = 1
    )
    block = blockchain.new_block(0)
    blockchain.proof_of_work(block)
    
    response = {
        "message": "New block mined",
        "index": block["index"],
        "transactions": block["transactions"],
        "proof": block["proof"],
        "previous_hash": block["previous_hash"]
    }
    return jsonify(response), 200

@app.route('/transactions/new', methods = ["POST"])
def new_transaction():
    values = request.get_json()
    if not values:
        return "Missing body", 400
    
    required = ["sender", "recipient", "amount"]
    
    if not all(k in values for k in required):
        return "Missing values", 400
    
    index = blockchain.new_transaction(values["sender"], values["recipient"], values["amount"])
    
    response = { "message": f"Transaction will be added to block {index}"}
    return jsonify(response), 201

@app.route('/chain', methods = ["GET"])
def full_chain():
    response = {
        'chain': blockchain.chain,
        "length": len(blockchain.chain)
    }
    return jsonify(response), 200

@app.route('/nodes/register', methods = ["POST"])
def register_nodes():
    values = request.get_json()
    nodes = values.get('nodes')
    
    if nodes is None:
        return "Error: Please supply a valid list of nodes", 400
    
    for node in nodes:
        blockchain.register_node(node)
        
    response = {"'message": "New nodes have been added"}
    return jsonify(response),201

@app.route("/nodes/resolve", methods=["GET"])
def consensus():
    replaced = blockchain.resolve_conflict()
    
    if replaced:
        response = {
            'message': "Our chain was replaced",
            'new chain': blockchain.chain
        }
    else:
        response = {
            'message': "Our chain is authoritative",
            'chain': blockchain.chain
        }
    return jsonify(response), 200

    
if __name__ == "__main__":
    from argparse import ArgumentParser
    parser = ArgumentParser()
    parser.add_argument('-p', '--port', default=5000, type=int, help='port to listen on')
    args = parser.parse_args()
    app.run(host='0.0.0.0', port=args.port)




    # blockchain = Blockchain()
    # blockchain.proof_of_work(blockchain.last_block)
    # print(blockchain.hash(blockchain.last_block))


    # print(blockchain.hash(blockchain.last_block))
    # blockchain.new_transaction("Alice", "Bob", 50)
    # blockchain.new_block(0)
    # print(blockchain.hash(blockchain.last_block))
