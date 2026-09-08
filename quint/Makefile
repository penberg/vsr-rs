# The Quint model of vsr-rs. Needs `quint` (npm install -g @informalsystems/quint)
# and, for `verify`, a Java 17+ runtime; Quint downloads Apalache itself.

SAMPLES ?= 10000
STEPS ?= 200
DEPTH ?= 1
WITNESSES = wCommitted wViewChanged wCommittedAfterViewChange wStateTransferred wCaughtUp wRecovered

.PHONY: all typecheck run run3 run5 verify verify3 verifymin clean

all: typecheck run

typecheck:
	quint typecheck vsr.qnt
	quint typecheck vsr3.qnt
	quint typecheck vsr3min.qnt
	quint typecheck vsr5.qnt

## Random simulation of every run of `stepFair`, checking `safety` after every step.
run: run3 run5

run3:
	quint run vsr3.qnt --step=stepFair --invariant=safety --max-samples=$(SAMPLES) --max-steps=$(STEPS) --witnesses $(WITNESSES)

run5:
	quint run vsr5.qnt --step=stepFair --invariant=safety --max-samples=$(SAMPLES) --max-steps=$(STEPS) --witnesses $(WITNESSES)

## Bounded model checking with Apalache: every run of `step` of up to DEPTH
## steps. Depth 1 takes minutes; depth 2 did not return within an hour.
verify: verify3

verify3:
	quint verify vsr3.qnt --invariant=safety --max-steps=$(DEPTH)

verifymin:
	quint verify vsr3min.qnt --invariant=safety --max-steps=$(DEPTH)

clean:
	rm -rf _apalache-out
