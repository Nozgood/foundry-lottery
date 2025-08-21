unit-test:
	forge test -vvv

test-coverage:
	forge coverage --report debug > coverage.txt

lint:
	forge fmt --check
