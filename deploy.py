import os
from dotenv import load_dotenv
from web3 import Web3

# Carga las variables del archivo .env
load_dotenv()

# Obtén las variables de entorno
alchemy_amoy_key = os.getenv('ALCHEMY_AMOY_KEY')
private_key = os.getenv('PRIVATE_KEY')
etherscan_api_key = os.getenv('ETHERSCAN_API_KEY')

w3 = Web3(Web3.HTTPProvider(f'https://polygon-amoy.g.alchemy.com/v2/{alchemy_amoy_key}'))
with open('autograph/abis/Data.json') as f:
    contract_abi = f.read()


contract_address = '0xa59f9659738A0C07C395c3921f6DE7649a271196'

contract = w3.eth.contract(address=contract_address, abi=contract_abi)

def call_contract_function(function_name, *args):
    nonce = w3.eth.get_transaction_count("0xfa3fea500eeDAa120f7EeC2E4309Fe094F854E61")
    
    transaction = contract.functions[function_name](*args).build_transaction({
        'chainId': 80002,
        'gas': 2000000,
        'gasPrice': w3.to_wei('50', 'gwei'),
        'nonce': nonce,
    })
    
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key=private_key)
    
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    
    tx_receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    
    return tx_receipt

function_name = 'setAutographMarketAddress'
args = ("0xb75C8dCf8f906EFb903c0f17D30079439B6c8781",)  

try:
    receipt = call_contract_function(function_name, *args)
    print(f'Transacción completada: {receipt}')
except Exception as e:
    print(f'Error al llamar la función del contrato: {e}')



# # Comando para desplegar el contrato
# command = f"forge create --rpc-url https://polygon-amoy.g.alchemy.com/v2/{alchemy_amoy_key} --chain 80002 --private-key {private_key} --etherscan-api-key {etherscan_api_key} --verify src/NPCPublication.sol:NPCPublication --constructor-args 'NPCP' 'NPC Publication' 0xe57438297515C4B7c62FE13957413085A7e1763c 0x64d7b1b3388f8F0B0eaF96fCcd30F94797A7Bf95"
# # Ejecuta el comando
# os.system(command)

