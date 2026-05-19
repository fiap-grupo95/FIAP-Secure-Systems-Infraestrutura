.PHONY: up down clean

up:
	docker compose up

down:
	docker compose down

clean:
	docker compose down --rmi all --volumes --remove-orphans