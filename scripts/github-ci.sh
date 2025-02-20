#!/bin/bash

set -e

PARALLEL=2
PARALLEL_MAKE=-j"$PARALLEL"
PARALLEL_CTEST=-j"$PARALLEL"

BUILDDIR=b
GCOVRDIR=c

do_enable_python() {
	echo "do_enable_python()"
	PYTHON_DEFINE="-DENABLE_PYTHON=ON"
}
do_build() {
	echo "do_build()"

	rm -rf "$BUILDDIR"
	mkdir "$BUILDDIR"
	(
		cd "$BUILDDIR"
		cmake -DCMAKE_BUILD_TYPE=Release -DEXPERIMENTAL=ON -DPROFILE=ON ${PYTHON_DEFINE} .. && make $PARALLEL_MAKE
	)
	if [[ $? != 0 ]]; then
		echo "Build failure"
		exit 1
	fi
}

do_test() {
	echo "do_test()"

	(
		cd "$BUILDDIR"
		ctest $PARALLEL_CTEST
		if [[ $? != 0 ]]; then
			exit 1
		fi
		if [ -d tests/.gcov ]; then
			tar -C tests/.gcov -c -f - . | tar -x -f -
		fi
	)
	if [[ $? != 0 ]]; then
		echo "Test failure"
		exit 1
	fi
}

do_coverage() {
	echo "do_coverage()"

	case $(gcovr --version | head -n1 | awk '{ print $2 }') in
	    [4-9].*)
		PARALLEL_GCOVR=-j"$PARALLEL"
		;;
	    *)
		PARALLEL_GCOVR=
		;;
	esac

	rm -rf "$GCOVRDIR"
	mkdir "$GCOVRDIR"
	(
		cd "$BUILDDIR"
		echo "Generating code coverage report..."
		gcovr -r .. $PARALLEL_GCOVR --html --html-details -p -o coverage.html
		if [[ $? != 0 ]]; then
			exit 1
		fi
		mv coverage*.html ../"$GCOVRDIR"
		echo "done."
	)
	if [[ $? != 0 ]]; then
		echo "Coverage failure"
		exit 1
	fi
}

for func in $@
do
	"do_$func"
done

exit 0
