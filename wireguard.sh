#!/bin/bash

cd "$(dirname "$0")"

case "$1" in
    start)
        docker compose up -d
        ;;
    stop)
        docker compose down
        ;;
    restart)
        docker compose restart
        ;;
    status)
        docker compose ps
        ;;
    logs)
        docker compose logs -f
        ;;
    handshake)
        docker exec -it wireguard wg show
        ;;
    regenerate)
        ./scripts/regenerate-configs.sh
        ;;
    qr)
        if [ -z "$2" ]; then
            echo "Error: Specify the peer number. E.g.: ./wireguard.sh qr 1"
            exit 1
        else
            docker exec -it wireguard /app/show-peer "$2"
        fi
        ;;
    conf-file)
        if [ -z "$2" ]; then
            echo "Error: Specify the peer number. E.g.: ./wireguard.sh conf-file 1"
            exit 1
        else
            docker exec -it wireguard cat /config/peer"$2"/peer"$2".conf
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs|handshake|regenerate|qr <num>|conf-file <num>}"
        exit 1
        ;;
esac