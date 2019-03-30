check:
	- mix format --check-formatted
	- mix credo -a
	- mix dialyzer
	- mix test
