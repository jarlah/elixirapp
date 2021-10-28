all:
	docker build . -t eve-online-market-order-object-names
	docker run eve-online-market-order-object-names
