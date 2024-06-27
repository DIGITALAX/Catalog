import os
from dotenv import load_dotenv
from web3 import Web3

# Carga las variables del archivo .env
load_dotenv()

# Obtén las variables de entorno
alchemy_key = os.getenv('ALCHEMY_KEY')
private_key = os.getenv('PRIVATE_KEY')
etherscan_api_key = os.getenv('ETHERSCAN_API_KEY')

w3 = Web3(Web3.HTTPProvider(f'https://polygon-mainnet.g.alchemy.com/v2/{alchemy_key}'))
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



# Comando para desplegar el contrato
# command = f"forge create --rpc-url https://polygon-mainnet.g.alchemy.com/v2/{alchemy_key} --chain 137 --private-key {private_key} --etherscan-api-key {etherscan_api_key} --verify src/AutographOpenAction.sol:AutographOpenAction --constructor-args 'ipfs://QmT4Sf2vNF6uvTV8nXTjwFPzEpyP698tsoVZUd18XKA91X' 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d 0x1eD5983F0c883B96f7C35528a1e22EEA67DE3Ff9 0xd52dA212D5C7Ec8f7Bb3594372530b19f3e5f37E 0xcD70E5C79b1a199af92134CD8F9f1583963e6CC9 0x9D38850465982be54372B68eD2067d92aD6F817F"

# command = f"forge verify-contract 0x749Da95bC493AF77A695dEc621C733d6317aa8Fc src/AutographOpenAction.sol:AutographOpenAction --verifier etherscan --rpc-url https://polygon-mainnet.g.alchemy.com/v2/{alchemy_key} --chain 137 --etherscan-api-key {etherscan_api_key} --constructor-args 'ipfs://QmT4Sf2vNF6uvTV8nXTjwFPzEpyP698tsoVZUd18XKA91X' 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d 0x1eD5983F0c883B96f7C35528a1e22EEA67DE3Ff9 0xd52dA212D5C7Ec8f7Bb3594372530b19f3e5f37E 0xcD70E5C79b1a199af92134CD8F9f1583963e6CC9 0x9D38850465982be54372B68eD2067d92aD6F817F"

# command = f'forge verify-contract --rpc-url https://polygon-mainnet.g.alchemy.com/v2/{alchemy_key} --chain-id 137 --compiler-version 0.8.26 --constructor-args $(cast abi-encode "constructor(string,address,address,address,address,address)" "ipfs://QmT4Sf2vNF6uvTV8nXTjwFPzEpyP698tsoVZUd18XKA91X" 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d 0x1eD5983F0c883B96f7C35528a1e22EEA67DE3Ff9 0xd52dA212D5C7Ec8f7Bb3594372530b19f3e5f37E 0xcD70E5C79b1a199af92134CD8F9f1583963e6CC9 0x9D38850465982be54372B68eD2067d92aD6F817F) --etherscan-api-key {etherscan_api_key} --watch 0x749Da95bC493AF77A695dEc621C733d6317aa8Fc src/AutographOpenAction.sol:AutographOpenAction'


# Ejecuta el comando
# os.system(command)