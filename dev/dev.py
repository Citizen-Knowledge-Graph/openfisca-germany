from openfisca_core.simulation_builder import SimulationBuilder
from openfisca_germany import CountryTaxBenefitSystem

system = CountryTaxBenefitSystem()

population = {
    "persons": {
        "Alice": {
            "salary": { "2025-07": 5000 },
        },
        "Bob": {
            "salary": { "2025-07": 3000 },
        }
    }
}

sim = SimulationBuilder().build_from_entities(system, population)
print(sim.calculate("dev_benefit", "2025-07"))
