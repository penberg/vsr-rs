# The FizzBee model of vsr-rs. Needs `fizz` from a FizzBee release
# (https://github.com/fizzbee-io/fizzbee/releases), or point FIZZ at it.

FIZZ ?= fizz
RUNS ?= 2000
STEPS ?= 40

.PHONY: all check simulate clean

all: check

## Every execution up to the `max_actions` in the spec's frontmatter.
check:
	$(FIZZ) Vsr.fizz

## Random executions of up to STEPS actions. The frontmatter takes precedence
## over `fizz.yaml`, so the deeper bound goes into a copy of the spec.
simulate:
	mkdir -p out/simulate
	sed 's/max_actions: .*/max_actions: $(STEPS)/' Vsr.fizz > out/simulate/Vsr.fizz
	$(FIZZ) -x --max_runs $(RUNS) out/simulate/Vsr.fizz

clean:
	rm -rf out Vsr.json
