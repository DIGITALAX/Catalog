import os
from dotenv import load_dotenv

# Carga las variables del archivo .env
load_dotenv()

# Obtén las variables de entorno
alchemy_amoy_key = os.getenv('ALCHEMY_AMOY_KEY')
private_key = os.getenv('PRIVATE_KEY')
etherscan_api_key = os.getenv('ETHERSCAN_API_KEY')

# Comando para desplegar el contrato
command = f"forge create --rpc-url https://polygon-amoy.g.alchemy.com/v2/{alchemy_amoy_key} --chain 80002 --private-key {private_key} --etherscan-api-key {etherscan_api_key} --verify src/NPCPublication.sol:NPCPublication --constructor-args 'NPCP' 'NPC Publication' 0xe57438297515C4B7c62FE13957413085A7e1763c 0x52f43D34e1abb0a6d1C97c0CF8b8f323872fC664"
# Ejecuta el comando
os.system(command)

