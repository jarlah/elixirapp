all: build run

build:
	docker build . -t eve-online-market-order-object-names
run:
	docker run eve-online-market-order-object-names