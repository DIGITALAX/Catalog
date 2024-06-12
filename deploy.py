import os
from dotenv import load_dotenv

# Carga las variables del archivo .env
load_dotenv()

# Obtén las variables de entorno
alchemy_amoy_key = os.getenv('ALCHEMY_AMOY_KEY')
private_key = os.getenv('PRIVATE_KEY')
etherscan_api_key = os.getenv('ETHERSCAN_API_KEY')

# Comando para desplegar el contrato
command = f"forge create --rpc-url https://polygon-amoy.g.alchemy.com/v2/{alchemy_amoy_key} --chain 80002 --private-key {private_key} --etherscan-api-key {etherscan_api_key} --verify src/AutographOpenAction.sol:AutographOpenAction --constructor-args 'metadata' 0xA2574D9DdB6A325Ad2Be838Bd854228B80215148 0x9E81eD8099dF82004D298144138C12AbB959DF1E 0x883a24A5315c0E4Ff4451E6E2B760338FDC8faE8 0xe57438297515C4B7c62FE13957413085A7e1763c 0xb1931e410FC5Abe6581E3308018c9d6b173c16BF"

# Ejecuta el comando
os.system(command)
