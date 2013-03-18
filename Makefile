SRC = \
  src/runtime/runtime.js \
  src/traceur.js
GENSRC = \
  src/syntax/trees/ParseTreeType.js \
  src/syntax/trees/ParseTrees.js \
  src/syntax/ParseTreeVisitor.js \
  src/codegeneration/ParseTreeTransformer.js \
  src/outputgeneration/SourceMapIntegration.js

TFLAGS = --strict-semicolons --

build: bin/traceur.js

min: bin/traceur.min.js

# Uses uglifyjs to compress. Make sure you have it installed
#   npm install uglify-js -g
ugly: bin/traceur.ugly.js

test: build test/test-list.js
	node test/testfeatures.js --errsfile test/errsfile.json

test-list: test/test-list.js

test/test-list.js: build/build-test-list.js
	git ls-files test/feature | node $? > $@

boot: clean build

clean:
	git checkout bin
	touch -t 197001010000.00 bin/traceur.js

distclean: clean
	rm -f build/dep.mk
	rm -f $(GENSRC)

initbench:
	rm -rf test/bench/esprima
	git clone https://github.com/ariya/esprima.git test/bench/esprima
	cd test/bench/esprima; \
			git reset --hard 1ddd7e0524d09475a14eee66e8e1e3557c5b5999
	git apply test/bench/esprima-compare.patch

bin/traceur.min.js: bin/traceur.js
	node build/minifier.js $? $@

bin/traceur.js force:
	./traceur --out bin/traceur.js $(TFLAGS) $(SRC)

# Prerequisites following '|' are rebuilt just like ordinary prerequisites.
# However, they don't cause remakes if they're newer than the target. See:
# http://www.gnu.org/software/make/manual/html_node/Prerequisite-Types.html
build/dep.mk: | $(GENSRC)
	node build/makedep.js --depTarget bin/traceur.js $(TFLAGS) $(SRC) > $@

src/syntax/trees/ParseTrees.js: src/syntax/trees/trees.json build/build-parse-trees.js
	node build/build-parse-trees.js src/syntax/trees/trees.json > $@

src/syntax/trees/ParseTreeType.js: src/syntax/trees/trees.json build/build-parse-tree-type.js
	node build/build-parse-tree-type.js src/syntax/trees/trees.json > $@

src/syntax/ParseTreeVisitor.js: src/syntax/trees/trees.json build/build-parse-tree-visitor.js
	node build/build-parse-tree-visitor.js src/syntax/trees/trees.json > $@

src/codegeneration/ParseTreeTransformer.js: src/syntax/trees/trees.json build/build-parse-tree-transformer.js
	node build/build-parse-tree-transformer.js src/syntax/trees/trees.json > $@

%.js: %.js-template.js
	node build/expand-js-template.js $^ $@

bin/traceur.ugly.js: bin/traceur.js
	uglifyjs bin/traceur.js --compress dead_code=true,unused=true,sequences=true,join_vars=true,evaluate=true,booleans=true,conditionals=true -m -o $@

.PHONY: build min test test-list force boot clean distclean

-include build/dep.mk
-include build/local.mk
