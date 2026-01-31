#!/bin/bash

# Colores para que se vea pro
VERDE='\033[0;32m'
NC='\033[0m'

echo -e "${VERDE}>>> Instalando dependencias (PHP)...${NC}"
apt update && apt install -y php-cli screen git

# Crear directorio de la API
mkdir -p /etc/v2ray_api
cd /etc/v2ray_api

echo -e "${VERDE}>>> Creando el script index.php para el CheckUser...${NC}"
cat <<EOF > index.php
<?php
\$uuid_buscado = \$_GET['uuid'] ?? '';
if (empty(\$uuid_buscado)) {
    die(json_encode(["days" => -1, "error" => "No UUID"]));
}

\$archivo = "/etc/SSHPlus/RegV2ray";
if (!file_exists(\$archivo)) {
    die(json_encode(["days" => -1, "error" => "DB not found"]));
}

\$lineas = file(\$archivo);
foreach (\$lineas as \$linea) {
    \$partes = explode(" | ", trim(\$linea));
    if (count(\$partes) >= 3 && \$partes[0] === \$uuid_buscado) {
        \$fecha_exp = strtotime(\$partes[2]);
        \$dias = (int)ceil((\$fecha_exp - time()) / 86400);
        echo json_encode([
            "user" => \$partes[1],
            "days" => (\$dias > 0 ? \$dias : 0)
        ]);
        exit;
    }
}
echo json_encode(["days" => -1]);
?>
EOF

echo -e "${VERDE}>>> Configurando inicio automático con SystemD...${NC}"
cat <<EOF > /etc/systemd/system/v2ray-api.service
[Unit]
Description=API CheckUser V2Ray en puerto 89
After=network.target

[Service]
ExecStart=/usr/bin/php -S 0.0.0.0:89 -t /etc/v2ray_api
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Activar el servicio
systemctl daemon-reload
systemctl enable v2ray-api
systemctl start v2ray-api

echo -e "${VERDE}>>> ¡LISTO! API corriendo en el puerto 89${NC}"
echo -e "Probando: http://localhost:89/?uuid=test"