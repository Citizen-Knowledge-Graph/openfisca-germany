#!/bin/bash
set -e

OPENFISCA_CORE_VERSION=43.2.1
PACKAGE_NAME=openfisca_browser_dist
PACKAGE_VERSION=0.1.0
COUNTRY_PKG_PATH=openfisca_germany
DIST_DIR=dist/browser

rm -rf vendored ${DIST_DIR}
mkdir -p vendored ${DIST_DIR}

pip install --no-deps --target=vendored openfisca-core==${OPENFISCA_CORE_VERSION}
cp -r ${COUNTRY_PKG_PATH} vendored/
pip install --no-binary :all: --no-deps --target=vendored dpath pendulum strenum

# Minimal numexpr and psutil stubs for Pyodide as they don't have official builds but are needed for imports to work
mkdir -p vendored/numexpr
cat > vendored/numexpr/__init__.py <<EOF
import numpy as np
def evaluate(expr, local_dict=None, **kwargs):
    return eval(expr, {"np": np}, local_dict or {})
EOF
mkdir -p vendored/psutil
cat > vendored/psutil/__init__.py <<EOF
virtual_memory = lambda: None
cpu_percent = lambda *a, **k: 0
EOF

# Exclude web api as it is not needed for the purpose of this standalone server-free browser distribution
cat > vendored/setup.py <<EOF
from setuptools import setup, find_packages
setup(
    name="${PACKAGE_NAME}",
    version="${PACKAGE_VERSION}",
    packages=[pkg for pkg in find_packages() if not pkg.startswith("openfisca_web_api")],
    include_package_data=True,
)
EOF

cat > vendored/MANIFEST.in <<EOF
recursive-include openfisca_germany *.yaml
recursive-include openfisca_germany *.json
EOF

(cd vendored && python3 -m build --wheel --outdir ../${DIST_DIR})
rm -rf vendored

cat > ${DIST_DIR}/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <title>OpenFisca Standalone Browser</title>
    <script src="https://cdn.jsdelivr.net/pyodide/v0.28.0/full/pyodide.js"></script>
</head>
<body>
<h2>OpenFisca Standalone Browser Demo</h2>
<pre id="sim_code">
from openfisca_core.simulation_builder import SimulationBuilder
from openfisca_germany import CountryTaxBenefitSystem
system = CountryTaxBenefitSystem()
population = {
    "persons": {
        "Alice": {
            "salary": { "2025-07": 4000 },
            "age": { "2025-07": 30 }
        }
    }
}
sim = SimulationBuilder().build_from_entities(system, population)
result = sim.calculate("basic_income", "2025-07")[0]
f"Basic income for Alice in 2025-07: {result}"
</pre>

<button id="run">Run</button>
<pre id="output" style="background: lightyellow">Click to start</pre>
<script>
    document.getElementById("run").onclick = async () => {
        const out = document.getElementById("output")
        out.textContent = "Loading Pyodide"
        const pyodide = await loadPyodide({ indexURL: "https://cdn.jsdelivr.net/pyodide/v0.28.0/full/" })
        out.textContent = "Preloading core packages"
        await pyodide.loadPackage([ "micropip", "numpy", "pyyaml", "typing-extensions", "sortedcontainers", "python-dateutil", "tzdata"])
        out.textContent = "Installing wheel"
        let code = \`
import micropip
await micropip.install("/dist/browser/openfisca_browser_dist-0.1.0-py3-none-any.whl")\`
        await pyodide.runPythonAsync(code.trim())
        out.textContent = "Running simulation"
        code = document.getElementById("sim_code").textContent
        const result = await pyodide.runPythonAsync(code.trim())
        out.textContent = result
    }
</script>
</body>
</html>
EOF
