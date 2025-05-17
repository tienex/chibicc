#!/bin/bash
# Run all test executables and the driver script without stopping on failure.

chibicc=$1
shift

test_exes=("$@")

# Expected failures from XFAIL environment variable (space separated)
IFS=' ' read -r -a expected_failures <<< "${XFAIL}"

is_expected_failure() {
    for t in "${expected_failures[@]}"; do
        if [ "${t}" = "$1" ]; then
            return 0
        fi
    done
    return 1
}

pass=0
fail=0
xfail_count=0
xpass=0

for exe in "${test_exes[@]}"; do
    echo "running $exe"
    cmd="./$exe"
    if output=$($cmd 2>&1); then
        if is_expected_failure "$exe"; then
            echo "  unexpected success"
            ((xpass++))
        else
            echo "  passed"
            ((pass++))
        fi
    else
        if is_expected_failure "$exe"; then
            echo "  expected failure"
            echo "$output"
            ((xfail_count++))
        else
            echo "  failed"
            echo "$output"
            ((fail++))
        fi
    fi
    echo
done

# Run the driver script
if [ -f test/driver.sh ]; then
    test/driver.sh "$chibicc"
fi

echo "Summary:"
echo "  Passed: $pass"
echo "  Expected failures: $xfail_count"
echo "  Unexpected successes: $xpass"
echo "  Failed: $fail"

exit 0
