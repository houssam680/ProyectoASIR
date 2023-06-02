#!/bin/bash
# Para agregar sudo sin solicitar la contraseña, puedes modificar el archivo /etc/sudoers
# Para hacerlo, debes agregar la siguiente línea al final del archivo /etc/sudoers, reemplazando 'usuario' con el nombre de usuario que ejecuta el script:
# usuario ALL=(ALL) NOPASSWD: ALL
declare -A Remote_users=(
    ["52.87.184.216"]="ubuntu"
    ["54.91.253.131"]="ubuntu"
    ["3.87.147.148"]="ubuntu"
    ["34.224.64.190"]="ubuntu"
)
Remote_servers=( "${!Remote_users[@]}" )
Local_key="/home/houssam_local/.ssh/id_rsa"
Authorized_keys=".ssh/authorized_keys"
chmod 400 /home/houssam_local/admin.pem
# Generar SSH key
ssh-keygen -t rsa -b 4096 -N "" -f "$Local_key"

for Remote_server in "${Remote_servers[@]}"
do
    Remote_user="${Remote_users[$Remote_server]}"
    # Añadir SSH key a amazon authorized keys
    scp -o StrictHostKeyChecking=no -i /home/houssam_local/admin.pem $Local_key.pub $Remote_user@$Remote_server:/tmp
    ssh -o StrictHostKeyChecking=no -i /home/houssam_local/admin.pem $Remote_user@$Remote_server "mkdir -p .ssh && touch $Authorized_keys && chmod 700 .ssh && chmod 600 $Authorized_keys && cat /tmp/id_rsa.pub >> $Authorized_keys && rm /tmp/id_rsa.pub"
done

declare -A Local_users=(
    ["192.168.202.216"]="ubuntu_local:2001"
    ["192.168.202.217"]="ubuntu_local:2001"
    ["192.168.202.218"]="ubuntu_local:2001"
)

# Define la ruta de la clave pública del servidor local
local_pub_key="/home/houssam_local/.ssh/id_rsa.pub"

# Itera sobre los servidores remotos y sube la clave pública
for Local_host in "${!Local_users[@]}"
do
    remote_user="${Local_users[$Local_host]}"
    sshpass -p '2001' ssh-copy-id -f -i $local_pub_key $remote_user@$Local_host
done


# Verificacion de SHH
# Contador de servidores que se han conectado correctamente
contador=0
puerto_ssh=22
for nombre_host in "${!Remote_users[@]}"; do
    usuario=${Remote_users[$nombre_host]}

    # Verifica si la conexión al puerto SSH está disponible
    if echo -e "exit\n" | nc -w 2 $nombre_host $puerto_ssh &>/dev/null; then
        if ssh $usuario@$nombre_host echo "Conexión SSH" &>/dev/null; then
            echo "Se puede configurar Ansible para conectarse a $nombre_host con el usario $usuario utilizando SHH "
            ((contador++))
        else
            echo "Error: Ansible no puede conectarse a $nombre_host"
        fi
    else
        echo "Error: $nombre_host no responde en el puerto 22"
    fi
done

for nombre_host in "${!Local_users[@]}"; do
    usuario=${Local_users[$nombre_host]}

    # Verifica si la conexión al puerto SSH está disponible
    if echo -e "exit\n" | nc -w 2 $nombre_host $puerto_ssh &>/dev/null; then
        if ssh $usuario@$nombre_host echo "Conexión SSH" &>/dev/null; then
            echo "Se puede configurar Ansible para conectarse a $nombre_host con el usario $usuario utilizando SHH "
            ((contador++))
        else
            echo "Error: Ansible no puede conectarse a $nombre_host"
        fi
    else
        echo "Error: $nombre_host no responde en el puerto 22"
    fi
done
    echo "---------------------------------------------------------"
    echo "Numero de servidores conectados correctamente: $contador"
    echo "---------------------------------------------------------"
    sleep 5
# Instalacion de ansible
if ! command -v ansible &> /dev/null
then
    sudo apt-get update
    sudo apt-get install -y ansible
fi
# Configuración de hosts de Ansible
# El archivo de hosts contiene los diferentes hosts que vamos a controlar mediante Ansible
if [ ! -d "/etc/ansible" ]; then
    sudo mkdir "/etc/ansible"
fi
if [ ! -f "/etc/ansible/hosts" ]; then
    sudo touch /etc/ansible/hosts
fi

sudo cp ./hosts /etc/ansible/hosts
