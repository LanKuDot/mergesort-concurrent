CC = gcc
CFLAGS = -std=gnu11 -Wall -g -pthread
OBJS = list.o threadpool.o merge_sort.o main.o

.PHONY: all clean test

GIT_HOOKS := .git/hooks/pre-commit

all: $(GIT_HOOKS) sort util/util-average

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

deps := $(OBJS:%.o=.%.o.d)
%.o: %.c
	$(CC) $(CFLAGS) -o $@ -MMD -MF .$@.d -c $<

sort: $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS) -rdynamic

genData:
	uniq test_data/words.txt | sort -R > test_data/input.txt

util/util-average: util/util-average.c
	$(CC) $(CFLAGS) -o $@ $<

# Default variables for auto testing
THREADS ?= 4
TEST_DATA_FILE   ?= /tmp/test_number.txt
NUM_OF_DATA      ?= 1024
SORTED_DATA_FILE ?= $(TEST_DATA_FILE).sorted
SORTED_RESULT    ?= /tmp/sort_result.txt
ITERATIONS       ?= 100

check: sort
# Generate testing data
	@bash scripts/gen-random-numbers.sh $(NUM_OF_DATA) $(TEST_DATA_FILE)
# Sort the testing data first to generate ground truth
	@sort -g $(TEST_DATA_FILE) > $(SORTED_DATA_FILE)
# Time for user program to sort the testing data, and ignore first the 3 lines of output.
# Because we only want the sorting result.
	@./sort $(THREADS) $(TEST_DATA_FILE) | tail -n +4 > $(SORTED_RESULT)
	@bash scripts/compare.sh $(SORTED_DATA_FILE) $(SORTED_RESULT)

repeat-test: sort util/util-average
# Generate testing data
	@bash scripts/gen-random-numbers.sh $(NUM_OF_DATA) $(TEST_DATA_FILE)
	@echo 3 | sudo tee /proc/sys/vm/drop_caches
	@bash scripts/repeat-test.sh $(THREADS) $(TEST_DATA_FILE) $(ITERATIONS)
	@./util/util-average ./out/repeat-test-result.dat

clean:
	rm -f $(OBJS) sort
	@rm -rf $(deps)

-include $(deps)
